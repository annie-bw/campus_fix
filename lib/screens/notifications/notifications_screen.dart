import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common.dart';
import '../reports/report_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: ScreenHeader(
        title: 'Notifications',
        trailing: provider.unreadCount > 0
            ? IconButton(
                tooltip: 'Mark all as read',
                icon: const Icon(PhosphorIconsRegular.checks, color: AppColors.primary),
                onPressed: provider.markAllRead,
              )
            : null,
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const EmptyState(
              icon: PhosphorIconsRegular.bell,
              title: 'No notifications yet',
              message: 'You’ll hear from us here when the status of your report changes.',
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 32 + MediaQuery.paddingOf(context).bottom),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _NotificationTile(
                item: items[i],
                onTap: () {
                  provider.markRead(items[i]);
                  ReportDetailsScreen.open(context, items[i].incidentId);
                },
              ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.status) {
      IncidentStatus.submitted => PhosphorIconsRegular.check,
      IncidentStatus.inProgress => PhosphorIconsRegular.fileText,
      IncidentStatus.resolved => PhosphorIconsRegular.checkCircle,
      IncidentStatus.rejected => PhosphorIconsRegular.warningCircle,
    };

    return Material(
      color: item.read ? Colors.white : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Formatters.timeAgo(item.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!item.read)
                Semantics(
                  label: 'Unread',
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                )
              else
                const SizedBox(width: 9),
            ],
          ),
        ),
      ),
    );
  }
}
