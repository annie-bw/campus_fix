import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// "40 min ago", "5 h ago", "2 days ago", then a date.
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(time);
  }

  /// "Today, 9:10 AM", "Yesterday, 2:30 PM", "Oct 15, 10:24 AM".
  static String timelineTime(DateTime time, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final clock = DateFormat('h:mm a').format(time);
    final d = DateTime(time.year, time.month, time.day);
    final t = DateTime(today.year, today.month, today.day);
    final days = t.difference(d).inDays;
    if (days == 0) return 'Today, $clock';
    if (days == 1) return 'Yesterday, $clock';
    return '${DateFormat('MMM d').format(time)}, $clock';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static String firstName(String name) => name.trim().split(' ').first;
}
