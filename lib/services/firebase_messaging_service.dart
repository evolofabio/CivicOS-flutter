import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/services/tenant_refs.dart';

/// Top-level background handler required by `firebase_messaging`.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message here (logging for prototype).
  print('Background message ${message.messageId}');
}

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._();

  factory FirebaseMessagingService() => _instance;

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
  String? _sessionTopic;

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _storeTokenForCurrentUser({String? comuneId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _safeGetToken();
    if (token == null || token.isEmpty) return;

    final tokenData = {
      'email': user.email ?? '',
      'comuneId': comuneId ?? '',
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'pushEnabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Salva nel bootstrap globale (identificazione al login).
    await TenantRefs.bootstrapDoc(
      user.uid,
    ).set(tokenData, SetOptions(merge: true));

    // Se il comune è noto, salva anche nel profilo tenant-scoped.
    final cid = comuneId ?? '';
    if (cid.isNotEmpty) {
      await TenantRefs.utentiDoc(
        cid,
        user.uid,
      ).set(tokenData, SetOptions(merge: true));
    }
  }

  /// Call during app startup after Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[FCM] Firebase.initializeApp error: $e');
    }

    await _initLocalNotifications();

    // Request permission on all supported platforms
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
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
      // Evita duplicati: in foreground le notifiche sono gestite dal listener
      // Firestore in app.dart (_startNotificaListener).
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

    final user = FirebaseAuth.instance.currentUser;
    String? previousTopic = _sessionTopic;
    if (user != null) {
      try {
        final doc = await TenantRefs.bootstrapDoc(user.uid).get();
        final data = doc.data();
        final remoteTopic = data?['fcmTopic'] as String?;
        if (remoteTopic != null && remoteTopic.isNotEmpty) {
          previousTopic = remoteTopic;
        }
      } catch (e) {
        debugPrint('[FCM] syncComuneSubscription bootstrap read error: $e');
      }
    }

    final nextTopic = topicForComune(comuneId);

    if (previousTopic != null &&
        previousTopic.isNotEmpty &&
        previousTopic != nextTopic) {
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
      _sessionTopic = nextTopic;
      if (user != null) {
        try {
          // Aggiorna topic nel bootstrap globale e nel profilo tenant-scoped.
          final topicData = {
            'fcmTopic': nextTopic,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await Future.wait([
            TenantRefs.bootstrapDoc(
              user.uid,
            ).set(topicData, SetOptions(merge: true)),
            TenantRefs.utentiDoc(
              comuneId,
              user.uid,
            ).set(topicData, SetOptions(merge: true)),
          ]);
        } catch (e) {
          debugPrint('[FCM] syncComuneSubscription topic update error: $e');
        }
      }
    }

    await _storeTokenForCurrentUser(comuneId: comuneId);
  }

  Future<void> clearComuneSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    String? previousTopic = _sessionTopic;
    if (user != null) {
      try {
        final doc = await TenantRefs.bootstrapDoc(user.uid).get();
        final data = doc.data();
        final remoteTopic = data?['fcmTopic'] as String?;
        if (remoteTopic != null && remoteTopic.isNotEmpty) {
          previousTopic = remoteTopic;
        }
      } catch (e) {
        debugPrint('[FCM] clearComuneSubscription bootstrap read error: $e');
      }
    }

    if (previousTopic != null && previousTopic.isNotEmpty) {
      try {
        await _messaging.unsubscribeFromTopic(previousTopic);
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
        print('FCM topic unsubscribe skipped: ${e.message}');
      }
      _sessionTopic = null;
      if (user != null) {
        try {
          await TenantRefs.bootstrapDoc(user.uid).set({
            'fcmTopic': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[FCM] clearComuneSubscription bootstrap clear error: $e');
        }
      }
    }
  }
}
