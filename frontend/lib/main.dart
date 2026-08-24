import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/record_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/elder_dashboard_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Care',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a5c38)),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login':  (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/records':       (_) => const RecordScreen(),
        '/settings':      (_) => const SettingsScreen(),
        '/elder':         (_) => const ElderDashboardScreen(),
      },
    );
  }
}