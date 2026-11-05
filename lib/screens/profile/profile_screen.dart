import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/shell_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/status_pill.dart';
import '../notifications/notifications_screen.dart';

/// Profile tab for both roles. Staff see their role badge and a note about
/// their access; students see their report count.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePassword(BuildContext context, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Change password'),
        content: Text('We’ll email a secure link to $email so you can set a new password.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send link')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await context.read<AuthProvider>().sendPasswordReset(email);
    if (!context.mounted) return;
    showAppSnack(context, error ?? 'Reset link sent to $email', error: error != null);
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Log out?'),
        content: const Text('You’ll need your ALU email and password to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final isStaff = auth.isStaff;
    final myCount = context.select<IncidentProvider, int>((p) => p.mine.length);
    final unread = context.select<NotificationProvider, int>((n) => n.unreadCount);
    final name = profile?.name ?? '';
    final email = profile?.email ?? auth.email;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
        children: [
          Center(child: UserAvatar(name: name, size: 80)),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Center(
            child: isStaff
                ? StatusPill.dark(profile?.department == null ? 'Staff' : 'Staff · ${profile!.department}')
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsFill.sealCheck, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Verified student',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          if (isStaff) ...[
            const NoticeBanner(
              text: 'Your staff role lets you change report statuses. Students can’t see this access.',
            ),
            const SizedBox(height: 24),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (!isStaff) ...[
                  _MenuRow(
                    icon: PhosphorIconsRegular.fileText,
                    label: 'My reports',
                    value: '$myCount',
                    onTap: () {
                      context.read<IncidentProvider>().showOnlyMine();
                      context.read<ShellProvider>().goTo(Tabs.reports);
                    },
                  ),
                  const Divider(height: 1),
                ],
                _MenuRow(
                  icon: PhosphorIconsRegular.bell,
                  label: 'Notifications',
                  value: unread > 0 ? '$unread new' : null,
                  onTap: () => NotificationsScreen.open(context),
                ),
                const Divider(height: 1),
                _MenuRow(
                  icon: PhosphorIconsRegular.lock,
                  label: 'Change password',
                  onTap: () => _changePassword(context, email),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () => _logout(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(PhosphorIconsRegular.signOut, size: 20),
              label: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.value});

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (value != null) ...[
                Text(value!, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(width: 4),
              ],
              const Icon(PhosphorIconsRegular.caretRight, size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
