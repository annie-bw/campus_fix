import 'package:flutter/material.dart';
import '../core/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'profile/profile_screen.dart';
import 'reports/reports_screen.dart';
import 'staff/staff_dashboard_screen.dart';
import 'student/home_screen.dart';

/// Signed-in container. The tabs depend on the role: staff never see the
/// student home or the new-report button, students never see the dashboard.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _studentTabs = [
    NavItem('Home', PhosphorIconsRegular.house, PhosphorIconsFill.house),
    NavItem('Reports', PhosphorIconsRegular.fileText, PhosphorIconsFill.fileText),
    NavItem('Profile', PhosphorIconsRegular.user, PhosphorIconsFill.user),
  ];

  static const _staffTabs = [
    NavItem('Dashboard', PhosphorIconsRegular.squaresFour, PhosphorIconsFill.squaresFour),
    NavItem('All reports', PhosphorIconsRegular.listBullets, PhosphorIconsFill.listBullets),
    NavItem('Profile', PhosphorIconsRegular.user, PhosphorIconsFill.user),
  ];

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);
    final shell = context.watch<ShellProvider>();

    final pages = [
      isStaff ? const StaffDashboardScreen() : const HomeScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: shell.index == Tabs.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goTo(Tabs.home); // back on a tab returns to Home
      },
      // Dark status-bar icons by default; photo headers switch to light.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: IndexedStack(index: shell.index, children: pages),
          bottomNavigationBar: AppBottomNav(
            items: isStaff ? _staffTabs : _studentTabs,
            currentIndex: shell.index,
            onTap: shell.goTo,
          ),
        ),
      ),
    );
  }
}
