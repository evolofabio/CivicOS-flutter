import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'calendario_service.dart';
import 'tenant_refs.dart';

/// Gestisce listener Firestore e notifiche locali (avvisi + raccolta).
class NotificaCoordinator {
  NotificaCoordinator({
    required this.comuneName,
    required this.notificationsEnabled,
  });

  String comuneName;
  bool notificationsEnabled;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _notificaListener;
  Timestamp? _lastNotificaTimestamp;
  bool _notificaBootstrapDone = false;
  final Set<String> _shownNotificaKeys = <String>{};
  final Set<String> _raccoltaNotifiedKeys = <String>{};
  Map<String, List<Map<String, dynamic>>> _calendarioPerFrazione = {};

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'civicos_avvisi',
      'Avvisi CivicOS',
      channelDescription: 'Notifiche su comunicazioni e avvisi del comune',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  void dispose() {
    _notificaListener?.cancel();
    _notificaListener = null;
  }

  Future<void> syncCalendario(String comuneId) async {
    _calendarioPerFrazione = await CalendarioService.loadPerFrazione(comuneId);
  }

  void startComuneListener(String comuneId) {
    _notificaListener?.cancel();
    if (comuneId.isEmpty) return;

    _notificaBootstrapDone = false;
    _lastNotificaTimestamp = null;
    _shownNotificaKeys.clear();

    _notificaListener = FirebaseFirestore.instance
        .collection('comuni')
        .doc(comuneId)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      final notifica = data['_lastNotifica'] as Map<String, dynamic>?;
      if (notifica == null) return;
      final ts = notifica['timestamp'] as Timestamp?;
      if (ts == null) return;

      if (!_notificaBootstrapDone) {
        _notificaBootstrapDone = true;
        final persisted = await _loadLastSeenNotifica(comuneId);
        if (persisted == null) {
          _lastNotificaTimestamp = ts;
          await _persistLastSeenNotifica(comuneId, ts);
          return;
        }
        _lastNotificaTimestamp = persisted;
      }

      if (_lastNotificaTimestamp != null &&
          !ts.toDate().isAfter(_lastNotificaTimestamp!.toDate())) {
        return;
      }

      final notificaKey = '${comuneId}_${ts.millisecondsSinceEpoch}';
      if (_shownNotificaKeys.contains(notificaKey)) return;
      _shownNotificaKeys.add(notificaKey);
      _lastNotificaTimestamp = ts;
      await _persistLastSeenNotifica(comuneId, ts);

      final titolo = notifica['titolo'] as String? ?? 'Nuovo avviso';
      final contenuto = notifica['contenuto'] as String? ?? '';
      final tipo = notifica['tipo'] as String? ?? '';
      final header = tipo.isNotEmpty
          ? 'Comune di $comuneName - ${tipo[0].toUpperCase()}${tipo.substring(1)}'
          : 'Comune di $comuneName';

      await FlutterLocalNotificationsPlugin().show(
        ts.hashCode,
        header,
        contenuto.isNotEmpty ? '$titolo\n$contenuto' : titolo,
        _notificationDetails,
      );
    });
  }

  Future<void> notifyRaccoltaDailyIfNeeded(String comuneId) async {
    await syncCalendario(comuneId);
    final now = DateTime.now();
    await _notifyRaccoltaForDate(
      comuneId: comuneId,
      date: now,
      tomorrow: false,
    );
    await _notifyRaccoltaForDate(
      comuneId: comuneId,
      date: now.add(const Duration(days: 1)),
      tomorrow: true,
    );
  }

  Future<void> _notifyRaccoltaForDate({
    required String comuneId,
    required DateTime date,
    required bool tomorrow,
  }) async {
    if (!notificationsEnabled) return;

    final giorno = CalendarioService.weekdayNameIt(date);
    final tipi = CalendarioService.tipiForDayAllFrazioni(
      _calendarioPerFrazione,
      giorno,
    );
    if (tipi.isEmpty) return;

    final dateKey = date.toIso8601String().split('T').first;
    final key =
        'civicos_raccolta_${tomorrow ? 'domani' : 'oggi'}_${comuneName}_$dateKey';
    if (_raccoltaNotifiedKeys.contains(key)) return;

    final title = tomorrow
        ? 'Raccolta differenziata di domani'
        : 'Raccolta differenziata di oggi';
    final body = 'Comune di $comuneName: ${tipi.join(', ')}';

    await FlutterLocalNotificationsPlugin().show(
      key.hashCode,
      title,
      body,
      _notificationDetails,
    );
    _raccoltaNotifiedKeys.add(key);
  }

  Future<Timestamp?> _loadLastSeenNotifica(String comuneId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final doc = await TenantRefs.utentiDoc(comuneId, user.uid).get();
      final data = doc.data();
      if (data == null) return null;
      final savedComune = data['lastNotificaSeenComuneId'] as String?;
      if (savedComune != comuneId) return null;
      return data['lastNotificaSeenAt'] as Timestamp?;
    } catch (e) {
      debugPrint('[NotificaCoordinator] loadLastSeen error: $e');
      return null;
    }
  }

  Future<void> _persistLastSeenNotifica(String comuneId, Timestamp ts) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await TenantRefs.utentiDoc(comuneId, user.uid).set({
        'lastNotificaSeenComuneId': comuneId,
        'lastNotificaSeenAt': ts,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[NotificaCoordinator] persistLastSeen error: $e');
    }
  }
}
