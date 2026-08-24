import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  print('[FCM 백그라운드] ${message.notification?.title}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.subscribeToTopic('senior_care_alerts');
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // 포그라운드 알림 배너 표시
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? '알림';
      final body  = message.notification?.body  ?? '';
      _showInAppBanner(title, body, message.data);
    });

    // 백그라운드에서 알림 탭 → 알림 화면으로 이동
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateToNotifications();
    });

    // 앱 종료 상태에서 알림 탭
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _navigateToNotifications();
    }

    final token = await _messaging.getToken();
    print('[FCM 토큰] $token');
  }

  static void _showInAppBanner(String title, String body, Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFFD32F2F),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(body,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _navigateToNotifications();
            },
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('닫기', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  static void _navigateToNotifications() {
    navigatorKey.currentState?.pushNamed('/notifications');
  }
}
