import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background handler required by `firebase_messaging`.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message here (logging for prototype).
  print('Background message ${message.messageId}');
}

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService _instance = FirebaseMessagingService._();

  factory FirebaseMessagingService() => _instance;

  static const _topicPrefsKey = 'civicos_fcm_topic';
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'civicos_avvisi',
    'Avvisi CivicOS',
    description: 'Notifiche su comunicazioni e avvisi del comune',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<String?> _safeGetToken() async {
    try {
      return await _messaging.getToken();
    } on FirebaseException catch (e) {
      // iOS Simulator often has no APNS token; avoid hard-failing startup.
      if (e.code == 'apns-token-not-set') {
        print('FCM init skipped: ${e.message}');
        return null;
      }
      rethrow;
    }
  }

  String topicForComune(String comuneId) => 'comune_$comuneId';

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _storeTokenForCurrentUser({String? comuneId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _safeGetToken();
    if (token == null || token.isEmpty) return;

    await FirebaseFirestore.instance.collection('utenti').doc(user.uid).set({
      'email': user.email ?? '',
      'comuneId': comuneId ?? '',
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'pushEnabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Call during app startup after Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
    } catch (_) {}

    await _initLocalNotifications();

    // Request permission on all supported platforms
    final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true);
    print('FCM permission: ${settings.authorizationStatus}');

    // Get token
    final token = await _safeGetToken();
    print('FCM token: $token');
    await _storeTokenForCurrentUser();

    _messaging.onTokenRefresh.listen((token) async {
      print('FCM token refreshed: $token');
      await _storeTokenForCurrentUser();
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground message: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'civicos_avvisi',
              'Avvisi CivicOS',
              channelDescription:
                  'Notifiche su comunicazioni e avvisi del comune',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    // When app opened from a terminated state by a message
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) print('Initial message open: ${msg.messageId}');
    });

    // When app is opened from background by a message
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.messageId}');
    });

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _initialized = true;
  }

  Future<void> syncComuneSubscription(String comuneId) async {
    if (comuneId.isEmpty) return;
    await init();

    final prefs = await SharedPreferences.getInstance();
    final previousTopic = prefs.getString(_topicPrefsKey);
    final nextTopic = topicForComune(comuneId);

    if (previousTopic != null && previousTopic.isNotEmpty && previousTopic != nextTopic) {
      try {
        await _messaging.unsubscribeFromTopic(previousTopic);
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
        print('FCM topic unsubscribe skipped: ${e.message}');
      }
    }

    if (previousTopic != nextTopic) {
      try {
        await _messaging.subscribeToTopic(nextTopic);
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
        print('FCM topic subscribe skipped: ${e.message}');
      }
      await prefs.setString(_topicPrefsKey, nextTopic);
    }

    await _storeTokenForCurrentUser(comuneId: comuneId);
  }

  Future<void> clearComuneSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final previousTopic = prefs.getString(_topicPrefsKey);
    if (previousTopic != null && previousTopic.isNotEmpty) {
      try {
        await _messaging.unsubscribeFromTopic(previousTopic);
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
        print('FCM topic unsubscribe skipped: ${e.message}');
      }
      await prefs.remove(_topicPrefsKey);
    }
  }
}
