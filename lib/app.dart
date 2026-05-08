import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_drawer.dart';
import 'core/models/tenant.dart';
import 'features/home/home_screen.dart';
import 'features/report/report_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/comunicazioni/comunicazioni_screen.dart';
import 'features/storico/storico_screen.dart';
import 'features/servizi_convenzionati/servizi_convenzionati_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/senior/senior_home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'core/services/mock_data.dart';
import 'services/firebase_messaging_service.dart';

class CivicOSApp extends StatefulWidget {
  @override
  State<CivicOSApp> createState() => _CivicOSAppState();
}

class _CivicOSAppState extends State<CivicOSApp> {
  int _currentIndex = 0;
  bool _seniorMode = false;
  bool _darkMode = false;
  bool _isLoggedIn = false;
  bool _notificationsEnabled = true;
  String _comuneSelezionato = MockData.comune;
  String _frazioneSelezionata = MockData.frazioni.first;
  StreamSubscription<DocumentSnapshot>? _notificaListener;
  Timestamp? _lastNotificaTimestamp;

  static const _keyComune = 'civicos_comune';
  static const _keyFrazione = 'civicos_frazione';

  String _keyComuneForUser(String? uid) =>
      uid == null ? _keyComune : 'civicos_comune_$uid';
  String _keyFrazioneForUser(String? uid) =>
      uid == null ? _keyFrazione : 'civicos_frazione_$uid';

  @override
  void initState() {
    super.initState();
    // Ripristina sessione Firebase Auth
    if (FirebaseAuth.instance.currentUser != null) {
      _isLoggedIn = true;
    }
    // Carica comune/frazione salvati
    _loadPrefs();
  }

  Future<void> _loadPrefs({bool forceRemote = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    final userComuneKey = _keyComuneForUser(uid);
    final userFrazioneKey = _keyFrazioneForUser(uid);

    String? savedComune = prefs.getString(userComuneKey);
    String? savedFrazione = prefs.getString(userFrazioneKey);

    // Migrazione da chiavi legacy (globali) alle chiavi per utente
    savedComune ??= prefs.getString(_keyComune);
    savedFrazione ??= prefs.getString(_keyFrazione);

    String? normalizeComuneName(String? comune, String? comuneId) {
      if (comune != null && MockData.comuni.containsKey(comune)) {
        return comune;
      }
      if (comuneId == null || comuneId.isEmpty) return null;
      for (final c in MockData.comuni.keys) {
        if (Tenant.toId(c) == comuneId) return c;
      }
      return null;
    }

    // Prova sempre il profilo remoto (o forzatamente al login) per evitare comuni stale
    if (uid != null && (forceRemote || savedComune == null)) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('utenti')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          final remoteComune = normalizeComuneName(
            data?['comune'] as String?,
            data?['comuneId'] as String?,
          );
          final remoteFrazione = data?['frazione'] as String?;
          if (remoteComune != null) {
            savedComune = remoteComune;
            savedFrazione = remoteFrazione;
            await prefs.setString(userComuneKey, remoteComune);
            await prefs.setString(_keyComune, remoteComune);
            if (remoteFrazione != null) {
              await prefs.setString(userFrazioneKey, remoteFrazione);
              await prefs.setString(_keyFrazione, remoteFrazione);
            }
          }
        }
      } catch (_) {}
    }

    // Se ancora non ci sono preferenze, recupera il comune da Firestore
    if (savedComune == null) {
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('utenti')
              .doc(uid)
              .get();
          if (doc.exists) {
            final data = doc.data();
            savedComune = normalizeComuneName(
              data?['comune'] as String?,
              data?['comuneId'] as String?,
            );
            savedFrazione = data?['frazione'] as String?;
            if (savedComune != null) {
              await prefs.setString(userComuneKey, savedComune);
              await prefs.setString(_keyComune, savedComune);
              if (savedFrazione != null) {
                await prefs.setString(userFrazioneKey, savedFrazione);
                await prefs.setString(_keyFrazione, savedFrazione);
              }
            }
          }
        } catch (_) {}
      }
    }

    // Fallback retrocompatibile: prova a dedurre il comune da richieste esistenti dell'utente
    if (savedComune == null && user != null) {
      final uid = user.uid;
      final email = user.email;

      Future<String?> comuneIdFromCollectionGroup(String group) async {
        QuerySnapshot<Map<String, dynamic>> snap;
        if (email != null && email.isNotEmpty) {
          snap = await FirebaseFirestore.instance
              .collectionGroup(group)
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            return snap.docs.first.reference.parent.parent?.id;
          }
        }
        snap = await FirebaseFirestore.instance
            .collectionGroup(group)
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.first.reference.parent.parent?.id;
        }
        return null;
      }

      try {
        String? comuneId = await comuneIdFromCollectionGroup('segnalazioni');
        comuneId ??= await comuneIdFromCollectionGroup('prenotazioni');
        comuneId ??= await comuneIdFromCollectionGroup('cisterne');

        final inferredComune = normalizeComuneName(null, comuneId);
        if (inferredComune != null) {
          savedComune = inferredComune;
          await prefs.setString(userComuneKey, inferredComune);
          await prefs.setString(_keyComune, inferredComune);

          final frazioni = MockData.comuni[inferredComune] ?? const <String>[];
          final inferredFrazione = frazioni.isNotEmpty ? frazioni.first : '';
          await prefs.setString(userFrazioneKey, inferredFrazione);
          await prefs.setString(_keyFrazione, inferredFrazione);
          savedFrazione = inferredFrazione;

          await FirebaseFirestore.instance.collection('utenti').doc(uid).set({
            'comune': inferredComune,
            'comuneId': Tenant.toId(inferredComune),
            'frazione': inferredFrazione,
            'email': email ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}
    }

    if (savedComune != null && MockData.comuni.containsKey(savedComune)) {
      final frazioni = MockData.comuni[savedComune]!;
      final frazione =
          (savedFrazione != null && frazioni.contains(savedFrazione))
          ? savedFrazione
          : (frazioni.isNotEmpty ? frazioni.first : '');
      if (mounted) {
        setState(() {
          _comuneSelezionato = savedComune!;
          _frazioneSelezionata = frazione;
        });
        // Aggiorna anche il Tenant provider
        final tenant = Provider.of<Tenant>(context, listen: false);
        tenant.updateComune(id: Tenant.toId(savedComune), name: savedComune);
        FirebaseMessagingService().syncComuneSubscription(
          Tenant.toId(savedComune),
        );
        _startNotificaListener(Tenant.toId(savedComune));
        unawaited(_notifyRaccoltaDailyIfNeeded());
      }
    }
  }

  void _setIndex(int i) => setState(() => _currentIndex = i);
  void _toggleSenior(bool v) => setState(() => _seniorMode = v);

  String _weekdayNameIt(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Lunedì';
      case DateTime.tuesday:
        return 'Martedì';
      case DateTime.wednesday:
        return 'Mercoledì';
      case DateTime.thursday:
        return 'Giovedì';
      case DateTime.friday:
        return 'Venerdì';
      case DateTime.saturday:
        return 'Sabato';
      case DateTime.sunday:
      default:
        return 'Domenica';
    }
  }

  Set<String> _raccoltaTipiForDay(String giorno) {
    final tipi = <String>{};
    for (final calendario in MockData.calendarioPerFrazione.values) {
      for (final row in calendario) {
        if ((row['giorno'] as String? ?? '') == giorno) {
          final list = (row['tipi'] as List<dynamic>? ?? []);
          for (final t in list) {
            final value = t.toString().trim();
            if (value.isNotEmpty) tipi.add(value);
          }
        }
      }
    }
    if (tipi.isEmpty) {
      for (final row in MockData.calendarioRaccolta) {
        if ((row['giorno'] as String? ?? '') == giorno) {
          final list = (row['tipi'] as List<dynamic>? ?? []);
          for (final t in list) {
            final value = t.toString().trim();
            if (value.isNotEmpty) tipi.add(value);
          }
        }
      }
    }
    return tipi;
  }

  Future<void> _notifyRaccoltaForDate(DateTime date, {required bool tomorrow}) async {
    if (!_notificationsEnabled) return;
    final giorno = _weekdayNameIt(date);
    final tipi = _raccoltaTipiForDay(giorno);
    if (tipi.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final dateKey = date.toIso8601String().split('T').first;
    final key = 'civicos_raccolta_${tomorrow ? 'domani' : 'oggi'}_${_comuneSelezionato}_$dateKey';
    if (prefs.getBool(key) == true) return;

    final title = tomorrow
        ? 'Raccolta differenziata di domani'
        : 'Raccolta differenziata di oggi';
    final body = 'Comune di $_comuneSelezionato: ${tipi.join(', ')}';

    await FlutterLocalNotificationsPlugin().show(
      key.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'civicos_avvisi',
          'Avvisi CivicOS',
          channelDescription: 'Notifiche su comunicazioni e avvisi del comune',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    await prefs.setBool(key, true);
  }

  Future<void> _notifyRaccoltaDailyIfNeeded() async {
    final now = DateTime.now();
    await _notifyRaccoltaForDate(now, tomorrow: false);
    await _notifyRaccoltaForDate(now.add(const Duration(days: 1)), tomorrow: true);
  }

  void _startNotificaListener(String comuneId) {
    _notificaListener?.cancel();
    if (comuneId.isEmpty) return;
    _notificaListener = FirebaseFirestore.instance
        .collection('comuni')
        .doc(comuneId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;
          final data = snap.data();
          if (data == null) return;
          final notifica = data['_lastNotifica'] as Map<String, dynamic>?;
          if (notifica == null) return;
          final ts = notifica['timestamp'] as Timestamp?;
          if (ts == null) return;
          // mostra solo notifiche nuove (dopo l'avvio del listener)
          if (_lastNotificaTimestamp != null &&
              !ts.toDate().isAfter(_lastNotificaTimestamp!.toDate()))
            return;
          _lastNotificaTimestamp = ts;
          // Mostra notifica locale
          final titolo = notifica['titolo'] as String? ?? 'Nuovo avviso';
          final contenuto = notifica['contenuto'] as String? ?? '';
          final tipo = notifica['tipo'] as String? ?? '';
          final header = tipo.isNotEmpty
              ? 'Comune di $_comuneSelezionato - ${tipo[0].toUpperCase()}${tipo.substring(1)}'
              : 'Comune di $_comuneSelezionato';
          FlutterLocalNotificationsPlugin().show(
            ts.hashCode,
            header,
            contenuto.isNotEmpty ? '$titolo\n$contenuto' : titolo,
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
        });
  }

  @override
  void dispose() {
    _notificaListener?.cancel();
    super.dispose();
  }

  Future<void> _setComune(String c) async {
    final frazioni = MockData.comuni[c] ?? [];
    final primaFrazione = frazioni.isNotEmpty ? frazioni.first : '';
    setState(() {
      _comuneSelezionato = c;
      _frazioneSelezionata = primaFrazione;
    });
    // Aggiorna Tenant provider
    final tenant = Provider.of<Tenant>(context, listen: false);
    tenant.updateComune(id: Tenant.toId(c), name: c);
    await FirebaseMessagingService().syncComuneSubscription(Tenant.toId(c));
    _startNotificaListener(Tenant.toId(c));
    await _notifyRaccoltaDailyIfNeeded();
    // Salva su disco
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await prefs.setString(_keyComuneForUser(uid), c);
    await prefs.setString(_keyFrazioneForUser(uid), primaFrazione);
    // Backward compatibility con chiavi storiche
    await prefs.setString(_keyComune, c);
    await prefs.setString(_keyFrazione, primaFrazione);

    // Persisti il comune dell'utente su Firestore per login automatico su nuovi dispositivi
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('utenti')
            .doc(user.uid)
            .set({
              'comune': c,
              'comuneId': Tenant.toId(c),
              'frazione': primaFrazione,
              'email': user.email ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> _setFrazione(String f) async {
    setState(() => _frazioneSelezionata = f);
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await prefs.setString(_keyFrazioneForUser(uid), f);
    await prefs.setString(_keyFrazione, f);
  }

  Future<void> _logout() async {
    await FirebaseMessagingService().clearComuneSubscription();
    await FirebaseAuth.instance.signOut();
    setState(() {
      _isLoggedIn = false;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenant = Provider.of<Tenant>(context);
    final theme = AppTheme.of(seniorMode: _seniorMode, darkMode: _darkMode);
    final darkTheme = AppTheme.of(seniorMode: _seniorMode, darkMode: true);

    if (!_isLoggedIn) {
      return MaterialApp(
        title: 'CivicOS',
        theme: theme,
        darkTheme: darkTheme,
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        home: LoginScreen(
          onLoginSuccess: () {
            setState(() => _isLoggedIn = true);
            _loadPrefs(forceRemote: true);
          },
        ),
      );
    }

    // --- MODALITÀ SENIOR ---
    if (_seniorMode) {
      return MaterialApp(
        title: 'CivicOS - ${tenant.name}',
        theme: theme,
        darkTheme: darkTheme,
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: SafeArea(
            child: SeniorHomeScreen(
              onToggleSenior: _toggleSenior,
              comuneSelezionato: _comuneSelezionato,
              frazioneSelezionata: _frazioneSelezionata,
            ),
          ),
        ),
      );
    }

    // --- MODALITÀ STANDARD ---
    final tabs = [
      HomeScreen(
        onToggleSenior: _toggleSenior,
        seniorMode: _seniorMode,
        comuneSelezionato: _comuneSelezionato,
        frazioneSelezionata: _frazioneSelezionata,
      ),
      ReportScreen(seniorMode: _seniorMode),
      BookingScreen(seniorMode: _seniorMode),
      const ComunicazioniScreen(),
      const StoricoScreen(),
      const ServiziConvenzionatiScreen(),
      SettingsScreen(
        seniorMode: _seniorMode,
        notificationsEnabled: _notificationsEnabled,
        comuneSelezionato: _comuneSelezionato,
        frazioneSelezionata: _frazioneSelezionata,
        onSeniorModeChanged: _toggleSenior,
        onNotificationsChanged: (v) =>
            setState(() => _notificationsEnabled = v),
        onComuneChanged: (c) => _setComune(c),
        onFrazioneChanged: (f) => _setFrazione(f),
        onPrivacyConsentChanged: (v) {},
        privacyConsent: true,
        onDarkModeChanged: (v) => setState(() => _darkMode = v),
      ),
      ProfileScreen(
        tenant: tenant,
        seniorMode: _seniorMode,
        onToggleSenior: _toggleSenior,
        onLogout: _logout,
      ),
    ];

    return MaterialApp(
      title: 'CivicOS - ${tenant.name}',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3B7A), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AppBar(
              title: Text(_pageTitles[_currentIndex]),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
        drawer: AppDrawer(
          currentIndex: _currentIndex,
          onTap: _setIndex,
          seniorMode: _seniorMode,
          unreadAvvisi: 0,
          onLogout: _logout,
        ),
        body: SafeArea(child: tabs[_currentIndex]),
      ),
    );
  }

  List<String> get _pageTitles => [
    'Home',
    'Segnalazioni',
    'Prenotazioni',
    'Avvisi',
    'Storico',
    'Servizi Convenzionati',
    'Impostazioni',
    'Profilo',
  ];
}
