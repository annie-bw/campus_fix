import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/theme/app_colors.dart';
import '../models/incident.dart';

/// Square thumbnail: the uploaded photo if there is one, else the
/// category icon on a soft green well.
class IncidentThumb extends StatelessWidget {
  const IncidentThumb({super.key, required this.incident, this.size = 52});

  final Incident incident;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.primaryTint,
      child: Icon(incident.category.icon, color: AppColors.primary, size: size * 0.46),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: incident.photoUrl == null
          ? fallback
          : Image.network(
              incident.photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
            ),
    );
  }
}

/// Large photo on the details screen, with loading and error states.
class IncidentPhoto extends StatelessWidget {
  const IncidentPhoto({super.key, required this.url, this.height = 200});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget box(Widget child) => Container(
      height: height,
      width: double.infinity,
      color: AppColors.primaryTint,
      alignment: Alignment.center,
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _PhotoViewer(url: url))),
        child: Image.network(
          url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null ? child : box(const CircularProgressIndicator()),
          errorBuilder: (_, _, _) => box(
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.imageBroken, color: AppColors.primary, size: 30),
                SizedBox(height: 6),
                Text(
                  'Photo couldn’t load',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    );
  }
}
