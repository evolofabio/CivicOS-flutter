import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tenant.dart';
import 'comuni_catalog.dart';
import 'tenant_refs.dart';

class ComunePrefs {
  const ComunePrefs({
    required this.comuneName,
    required this.comuneId,
    required this.frazione,
  });

  final String comuneName;
  final String comuneId;
  final String frazione;
}

/// Carica e persiste comune/frazione dell'utente da Firestore.
class ComunePrefsService {
  ComunePrefsService._();

  static String? normalizeComuneName(String? comune, String? comuneId) {
    if (comune != null && ComuniCatalog.contains(comune)) {
      return comune;
    }
    if (comuneId == null || comuneId.isEmpty) return null;
    for (final c in ComuniCatalog.nomi) {
      if (Tenant.toId(c) == comuneId) return c;
    }
    return null;
  }

  static String resolveFrazione(String comuneName, String? frazione) =>
      ComuniCatalog.resolveFrazione(comuneName, frazione);

  static Future<ComunePrefs?> loadForUser(String uid) async {
    try {
      final bootstrapDoc = await TenantRefs.bootstrapDoc(uid).get();
      if (!bootstrapDoc.exists) return null;

      final bootstrapData = bootstrapDoc.data();
      final resolvedComuneId = bootstrapData?['comuneId'] as String?;
      if (resolvedComuneId == null || resolvedComuneId.isEmpty) return null;

      final profileDoc = await TenantRefs.utentiDoc(resolvedComuneId, uid).get();
      final data = profileDoc.data() ?? bootstrapData;
      final comuneName = normalizeComuneName(
        data?['comune'] as String?,
        data?['comuneId'] as String?,
      );
      if (comuneName == null) return null;

      return ComunePrefs(
        comuneName: comuneName,
        comuneId: Tenant.toId(comuneName),
        frazione: resolveFrazione(comuneName, data?['frazione'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ComunePrefs?> inferFromLegacyCollections(User user) async {
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

      final comuneName = normalizeComuneName(null, comuneId);
      if (comuneName == null) return null;

      final frazione = resolveFrazione(comuneName, null);
      await TenantRefs.saveProfile(
        comuneId: Tenant.toId(comuneName),
        uid: uid,
        data: {
          'comune': comuneName,
          'comuneId': Tenant.toId(comuneName),
          'frazione': frazione,
          'email': email ?? '',
        },
      );

      return ComunePrefs(
        comuneName: comuneName,
        comuneId: Tenant.toId(comuneName),
        frazione: frazione,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ComunePrefs?> resolve(User user) async {
    final fromProfile = await loadForUser(user.uid);
    if (fromProfile != null) return fromProfile;
    return inferFromLegacyCollections(user);
  }

  static Future<void> saveComune({
    required User user,
    required String comuneName,
    required String frazione,
  }) =>
      TenantRefs.saveProfile(
        comuneId: Tenant.toId(comuneName),
        uid: user.uid,
        data: {
          'comune': comuneName,
          'comuneId': Tenant.toId(comuneName),
          'frazione': frazione,
          'email': user.email ?? '',
        },
      );

  static String comuneDisplayName(String comuneId) =>
      ComuniCatalog.displayNameFromId(comuneId);
}
