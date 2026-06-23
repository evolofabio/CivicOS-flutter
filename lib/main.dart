import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'core/models/tenant.dart';
import 'core/models/citizen_data.dart';
import 'core/services/comuni_catalog.dart';
import 'services/firebase_messaging_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Disabilita persistence: le scritture vanno direttamente al server
    // così il portale web le vede immediatamente
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    print('Firebase init failed: $e');
  }
  // Init FCM (può fallire sul simulatore senza APNS token - non bloccante)
  try {
    final fcm = FirebaseMessagingService();
    await fcm.init();
  } catch (e) {
    print('FCM init skipped: $e');
  }

  // Placeholder fino al login: sovrascritto da ComunePrefsService.
  final tenant = Tenant(
    id: Tenant.toId(ComuniCatalog.defaultComune),
    name: ComuniCatalog.defaultComune,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Tenant>.value(value: tenant),
        ChangeNotifierProvider<CitizenData>(create: (_) => CitizenData()),
      ],
      child: CivicOSApp(),
    ),
  );
}
