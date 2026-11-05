import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/shell_provider.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/incident_repository.dart';
import 'services/notification_repository.dart';

/// Dependency wiring. Services are created once and handed to the
/// providers; the incident and notification providers are "proxy"
/// providers so they re-subscribe whenever the signed-in user changes.
class CampusFixApp extends StatelessWidget {
  CampusFixApp({super.key});

  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProvider(create: (_) => ShellProvider()),
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(IncidentRepository()),
          update: (_, auth, incidents) => incidents!..updateUser(auth.profile),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(NotificationRepository()),
          update: (_, auth, notes) =>
              notes!..updateUser(auth.status == AuthStatus.signedIn ? auth.uid : null),
        ),
      ],
      child: MaterialApp(
        title: 'CampusFix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: _navigatorKey,
        home: AuthGate(navigatorKey: _navigatorKey),
      ),
    );
  }
}
