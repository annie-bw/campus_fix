import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

/// Thrown when a photo upload or delete is rejected or fails.
class PhotoStorageException implements Exception {
  PhotoStorageException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Uploads and deletes incident photos in Cloudflare (Workers KV), through
/// the CampusFix photo Worker (cloudflare/photo-worker.js).
///
/// Files live at incidents/{uid}/{incidentId}_{timestamp}.jpg. Every write
/// sends the user's Firebase ID token; the Worker verifies it and only lets
/// a verified user write inside their own uid folder.
class StorageService {
  StorageService({FirebaseAuth? auth, http.Client? client, String? baseUrl})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? photoApiUrl;

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 60);

  Uri _uri(String path) => Uri.parse('$_baseUrl/photos/$path');

  Future<String> _token() async {
    final user = _auth.currentUser;
    if (user == null) throw PhotoStorageException('Please sign in again.');
    final token = await user.getIdToken();
    if (token == null) throw PhotoStorageException('Please sign in again.');
    return token;
  }

  /// Returns (url, path). [onProgress] gets 0.0 → 1.0 as bytes are sent.
  Future<({String url, String path})> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'incidents/$uid/${incidentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final length = await file.length();
    if (length > 5 * 1024 * 1024) {
      throw PhotoStorageException('That photo is larger than 5 MB. Choose a smaller one.');
    }

    final request = http.StreamedRequest('POST', _uri(path))
      ..headers['authorization'] = 'Bearer ${await _token()}'
      ..headers['content-type'] = 'image/jpeg'
      ..contentLength = length;

    // Stream the file so progress can be reported while it uploads.
    var sent = 0;
    file.openRead().listen(
      (chunk) {
        request.sink.add(chunk);
        sent += chunk.length;
        onProgress?.call(sent / length);
      },
      onDone: request.sink.close,
      onError: (Object e) {
        request.sink.addError(e);
        request.sink.close();
      },
      cancelOnError: true,
    );

    final http.Response res;
    try {
      res = await http.Response.fromStream(await _client.send(request).timeout(_timeout));
    } on SocketException {
      throw PhotoStorageException('No internet connection. Check your network and retry.');
    } on TimeoutException {
      throw PhotoStorageException('Photo upload timed out. Check your connection and retry.');
    } on http.ClientException {
      throw PhotoStorageException('Couldn’t reach the photo server. Try again.');
    }

    if (res.statusCode != 201) throw _failure(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (url: body['url'] as String, path: body['path'] as String);
  }

  /// Best effort: a missing file should not block deleting a report.
  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final res = await _client
          .delete(_uri(path), headers: {'authorization': 'Bearer ${await _token()}'})
          .timeout(_timeout);
      if (res.statusCode != 200 && res.statusCode != 404) throw _failure(res);
    } on SocketException {
      // Offline: leave the file; the report itself still gets deleted.
    }
  }

  PhotoStorageException _failure(http.Response res) {
    String? serverMessage;
    try {
      serverMessage = (jsonDecode(res.body) as Map<String, dynamic>)['error'] as String?;
    } catch (_) {}
    final message = switch (res.statusCode) {
      401 => 'Your session expired. Sign in again and retry.',
      403 => serverMessage ?? 'You don’t have permission to upload this photo.',
      413 => 'That photo is larger than 5 MB. Choose a smaller one.',
      _ => 'Couldn’t upload the photo. Try again, or send the report without it.',
    };
    return PhotoStorageException(message, statusCode: res.statusCode);
  }
}
