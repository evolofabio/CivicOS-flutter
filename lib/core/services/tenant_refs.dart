import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant.dart';

/// Centralizza tutti i percorsi Firestore tenant-scoped.
///
/// Schema:
///   utenti/{uid}                               ← bootstrap globale: {comuneId, email}
///   comuni/{comuneId}/utenti/{uid}             ← profilo completo del cittadino
///   comuni/{comuneId}/operatori/{uid}          ← operatori del comune con ruolo
///   comuni/{comuneId}/comunicazioni/{id}       ← avvisi e comunicazioni
///   comuni/{comuneId}/segnalazioni/{id}        ← segnalazioni dei cittadini
///   comuni/{comuneId}/prenotazioni/{id}        ← prenotazioni sportello
///   comuni/{comuneId}/calendari/{id}           ← calendario raccolta / eventi
///   comuni/{comuneId}/cisterne/{id}            ← livello cisterne
///   comuni/{comuneId}/scadenze/{id}            ← scadenze e avvisi
///   comuni/{comuneId}/aziende/{id}             ← aziende convenzionate
///   comuni/{comuneId}/mezzi/{id}               ← parco mezzi comunale
///   comuni/{comuneId}/statistiche/{periodo}    ← statistiche aggregate (scritte da Functions)
class TenantRefs {
  TenantRefs._();

  static final _db = FirebaseFirestore.instance;

  // ── Bootstrap globale ────────────────────────────────────────────────────
  /// Doc minimale: {comuneId, email}. Usato solo per risolvere il tenant al login.
  static DocumentReference<Map<String, dynamic>> bootstrapDoc(String uid) =>
      _db.collection('utenti').doc(uid);

  // ── Tenant root ──────────────────────────────────────────────────────────
  static DocumentReference<Map<String, dynamic>> comuneDoc(String comuneId) =>
      _db.collection('comuni').doc(comuneId);

  // ── Utenti (profilo completo, tenant-scoped) ─────────────────────────────
  static CollectionReference<Map<String, dynamic>> utentiCol(String comuneId) =>
      _db.collection('comuni').doc(comuneId).collection('utenti');

  static DocumentReference<Map<String, dynamic>> utentiDoc(
    String comuneId,
    String uid,
  ) => utentiCol(comuneId).doc(uid);

  // ── Operatori ────────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> operatoriCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('operatori');

  static DocumentReference<Map<String, dynamic>> operatoriDoc(
    String comuneId,
    String uid,
  ) => operatoriCol(comuneId).doc(uid);

  // ── Comunicazioni ────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> comunicazioniCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('comunicazioni');

  // ── Segnalazioni ─────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> segnalazioniCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('segnalazioni');

  // ── Prenotazioni ─────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> prenotazioniCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('prenotazioni');

  // ── Calendari ────────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> calendariCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('calendari');

  // ── Cisterne ─────────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> cisterneCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('cisterne');

  // ── Scadenze ─────────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> scadenzeCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('scadenze');

  // ── Aziende ──────────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> aziendeCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('aziende');

  // ── Mezzi ─────────────────────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> mezziCol(String comuneId) =>
      _db.collection('comuni').doc(comuneId).collection('mezzi');

  // ── Config tenant (servizi, sezioni portale) ─────────────────────────────
  static DocumentReference<Map<String, dynamic>> configDoc(
    String comuneId,
    String section,
  ) => _db.collection('comuni').doc(comuneId).collection('config').doc(section);

  // ── Statistiche (sola lettura per app; scritte da Cloud Functions) ────────
  static CollectionReference<Map<String, dynamic>> statisticheCol(
    String comuneId,
  ) => _db.collection('comuni').doc(comuneId).collection('statistiche');

  static DocumentReference<Map<String, dynamic>> statisticheDoc(
    String comuneId,
    String periodo,
  ) => statisticheCol(comuneId).doc(periodo);

  // ── Helper: salva bootstrap minimale ─────────────────────────────────────
  /// Scrive solo i campi necessari per risolvere il tenant al prossimo login.
  static Future<void> saveBootstrap({
    required String uid,
    required String comuneId,
    required String email,
  }) => bootstrapDoc(uid).set({
    'comuneId': comuneId,
    'email': email,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // ── Helper: salva profilo completo tenant-scoped ──────────────────────────
  static Future<void> saveProfile({
    required String comuneId,
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final merged = {
      ...data,
      'comuneId': comuneId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Scrittura doppia: profilo completo nel tenant + bootstrap globale.
    await Future.wait([
      utentiDoc(comuneId, uid).set(merged, SetOptions(merge: true)),
      saveBootstrap(
        uid: uid,
        comuneId: comuneId,
        email: (data['email'] as String?) ?? '',
      ),
    ]);
  }

  // ── Helper: leggi comuneId dal bootstrap ─────────────────────────────────
  static Future<String?> resolveComuneId(String uid) async {
    try {
      final doc = await bootstrapDoc(uid).get();
      return doc.data()?['comuneId'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Helper: nome id comune dal nome display ───────────────────────────────
  static String toId(String name) => Tenant.toId(name);
}
