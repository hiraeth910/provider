// notification_service.dart

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:telemoni/screens/wallet.dart';
import 'package:telemoni/utils/localstorage.dart';
import 'secure_storage_service.dart';

final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  final SecureStorageService _secureStorageService = SecureStorageService();

  // Initialize notification settings and listeners
  Future<void> initialize() async {
    // Initialize FlutterLocalNotificationsPlugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permission for notifications (only needs to be done once)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission for notifications');
    } else {
      print('User declined or has not accepted permission for notifications');
    }

    // Set foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen to foreground and background messages
    FirebaseMessaging.onMessage.listen(_handleNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification);
  }

  Future<void> _handleNotification(RemoteMessage message) async {
    // Show local notification for foreground messages
    if (message.notification != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'your_channel_id', // Replace with a unique channel ID
        'General Notifications', // Channel name for settings
        channelDescription: 'This channel is used for general notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
      );
    }

    // Handle JWT token update
    if (message.data.containsKey('new_jwt_token')) {
      String newJwtToken = message.data['new_jwt_token'];
      await _secureStorageService.storeToken(newJwtToken);
      await setUserRole(newJwtToken);
      print("JWT token updated from notification!");
    }

    // Handle transactional message
    if (message.data.containsKey('transaction_type') &&
        message.data['transaction_type'] == 'withdrawal') {
      notificationNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => WithdrawalPage()),
      );
      print("Navigated to WithdrawalPage from notification!");
    }
  }
}

// Background message handler for when the app is terminated
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService()._handleNotification(message);
}

Future<void> setUserRole(String token) async {
  final jwt = JWT.decode(token);

  await LocalStorage.setUser(jwt.payload['role']);
    print(await LocalStorage.getUser());
}
