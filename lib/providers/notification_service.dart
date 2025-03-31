import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/providers/auth_notifier.dart';
import 'package:maker_greenhouse/providers/http_service.dart';
import 'package:maker_greenhouse/providers/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user_model.dart';
import 'http_conf.dart';

part 'notification_service.g.dart';

@riverpod
NotificationService notificationService(Ref ref) {
  return NotificationService(ref);
}

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  String? _currentToken;

  NotificationService(this._ref)
      : _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    User? user = _ref.read(authNotifierProvider).value;
    if (user == null) {
      debugPrint("No user logged in. Skipping FCM initialization.");
      return;
    }
    await Permission.notification.isDenied.then((denied) {
      if (denied) {
        Permission.notification.request().then((granted) => {
              if (granted != PermissionStatus.granted)
                {throw Exception("User did not grant permission")}
            });
      }
    });
    // if (await Permission.notification.isDenied) {
    //   return;
    // }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      showBadge: true,
      ledColor: Colors.blue,
      enableLights: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _currentToken = await _ref
        .read(secureStorageProvider.notifier)
        .read(KEYS.fcmToken.name);
    // Get or refresh the FCM token
    _updateToken(user.id);

    // Listen for token changes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _updateToken(user.id, newToken);
    }).onError((err) {
      debugPrint("Error getting FCM token: $err");
    });
  }

  Future<void> _updateToken(int userId, [String? newToken]) async {
    final token = newToken ??
        _currentToken ??
        await FirebaseMessaging.instance.getToken();
    if (token != null && token != _currentToken) {
      _currentToken = token;
      debugPrint("Updated FCM Token: $_currentToken");
      await _ref
          .read(secureStorageProvider.notifier)
          .write(KEYS.fcmToken.name, _currentToken!);
      _updateTokenOnServer(_currentToken!, userId);
    }
  }

  Future<void> _updateTokenOnServer(String newToken, int userId) async {
    Map<String, String> body = {"fcmToken": newToken};
    _ref.read(httpServiceProvider).request(
        method: HttpMethod.patch,
        endpoint: "/notifications/$userId",
        body: body);
  }

  Future<void> _deleteTokenFromServer(int userId) async {
    ///TODO: implement
  }

  Future<void> clearToken() async {
    await FirebaseMessaging.instance.deleteToken();
    await _ref.read(secureStorageProvider.notifier).delete(KEYS.fcmToken.name);
    _currentToken = null;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showNotification(message);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? " ",
      message.notification?.body ?? " ",
      NotificationDetails(
        android: AndroidNotificationDetails(
            "high_importance_channel", "High Importance Notifications",
            icon: "@mipmap/ic_launcher"),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}
