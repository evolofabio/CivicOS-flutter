import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_drawer.dart';
import 'core/models/tenant.dart';
import 'core/models/citizen_data.dart';
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
import 'features/operator/operator_home_screen.dart';
import 'core/services/comuni_catalog.dart';
import 'core/services/comune_prefs_service.dart';
import 'core/services/notifica_coordinator.dart';
import 'core/services/tenant_refs.dart';
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
  bool _isOperator = false;
  String _operatorComuneId = '';
  bool _notificationsEnabled = true;
  String _comuneSelezionato = ComuniCatalog.defaultComune;
  String _frazioneSelezionata = ComuniCatalog.defaultFrazioni.first;
  late NotificaCoordinator _notificaCoordinator;

  @override
  void initState() {
    super.initState();
    _notificaCoordinator = NotificaCoordinator(
      comuneName: _comuneSelezionato,
      notificationsEnabled: _notificationsEnabled,
    );
    if (FirebaseAuth.instance.currentUser != null) {
      _isLoggedIn = true;
    }
    unawaited(_loadPrefs());
    unawaited(_loadCitizenProfile());
  }

  Future<void> _loadCitizenProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      final comuneId = await TenantRefs.resolveComuneId(uid);
      if (comuneId == null || comuneId.isEmpty) return;

      final doc = await TenantRefs.utentiDoc(comuneId, uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      if (!mounted) return;
      Provider.of<CitizenData>(context, listen: false).hydrateFromMap(data);
    } catch (e) {
      debugPrint('[App] _loadCitizenProfile error: $e');
    }
  }

  Future<void> _loadPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    ComunePrefs? prefs = await ComunePrefsService.loadForUser(user.uid);
    prefs ??= await ComunePrefsService.inferFromLegacyCollections(user);

    if (prefs == null || !ComuniCatalog.contains(prefs.comuneName)) {
      return;
    }

    if (!mounted) return;
    await _applyComunePrefs(prefs);
  }

  Future<void> _applyComunePrefs(ComunePrefs prefs) async {
    _notificaCoordinator.comuneName = prefs.comuneName;
    setState(() {
      _comuneSelezionato = prefs.comuneName;
      _frazioneSelezionata = prefs.frazione;
    });

    final tenant = Provider.of<Tenant>(context, listen: false);
    tenant.updateComune(id: prefs.comuneId, name: prefs.comuneName);
    await FirebaseMessagingService().syncComuneSubscription(prefs.comuneId);
    _notificaCoordinator.startComuneListener(prefs.comuneId);
    await _notificaCoordinator.notifyRaccoltaDailyIfNeeded(prefs.comuneId);
  }

  void _setIndex(int i) => setState(() => _currentIndex = i);
  void _toggleSenior(bool v) => setState(() => _seniorMode = v);

  @override
  void dispose() {
    _notificaCoordinator.dispose();
    super.dispose();
  }

  Future<void> _setComune(String c) async {
    final frazioni = ComuniCatalog.frazioniStatiche(c);
    final primaFrazione = frazioni.isNotEmpty ? frazioni.first : '';
    final comuneId = Tenant.toId(c);

    _notificaCoordinator.comuneName = c;
    setState(() {
      _comuneSelezionato = c;
      _frazioneSelezionata = primaFrazione;
    });

    final tenant = Provider.of<Tenant>(context, listen: false);
    tenant.updateComune(id: comuneId, name: c);
    await FirebaseMessagingService().syncComuneSubscription(comuneId);
    _notificaCoordinator.startComuneListener(comuneId);
    await _notificaCoordinator.notifyRaccoltaDailyIfNeeded(comuneId);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await ComunePrefsService.saveComune(
          user: user,
          comuneName: c,
          frazione: primaFrazione,
        );
      } catch (e) {
        debugPrint('[App] _setComune save error: $e');
      }
    }
  }

  Future<void> _setFrazione(String f) async {
    setState(() => _frazioneSelezionata = f);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await ComunePrefsService.saveComune(
          user: user,
          comuneName: _comuneSelezionato,
          frazione: f,
        );
      } catch (e) {
        debugPrint('[App] _setFrazione save error: $e');
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseMessagingService().clearComuneSubscription();
    await FirebaseAuth.instance.signOut();
    setState(() {
      _isLoggedIn = false;
      _isOperator = false;
      _operatorComuneId = '';
      _currentIndex = 0;
    });
    _notificaCoordinator.dispose();
    _notificaCoordinator = NotificaCoordinator(
      comuneName: _comuneSelezionato,
      notificationsEnabled: _notificationsEnabled,
    );
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
            unawaited(_loadPrefs());
            unawaited(_loadCitizenProfile());
          },
          onOperatorLoginSuccess: (comuneId) {
            setState(() {
              _isLoggedIn = true;
              _isOperator = true;
              _operatorComuneId = comuneId;
            });
            final t = Provider.of<Tenant>(context, listen: false);
            t.updateComune(
              id: comuneId,
              name: ComunePrefsService.comuneDisplayName(comuneId),
            );
          },
        ),
      );
    }

    if (_isOperator) {
      final comuneName = ComunePrefsService.comuneDisplayName(_operatorComuneId);
      return MaterialApp(
        title: 'CivicOS Operatore',
        theme: theme,
        darkTheme: darkTheme,
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        home: OperatorHomeScreen(
          comuneId: _operatorComuneId,
          comuneName: comuneName,
          onLogout: _logout,
        ),
      );
    }

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
        onNotificationsChanged: (v) {
          setState(() => _notificationsEnabled = v);
          _notificaCoordinator.notificationsEnabled = v;
        },
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
