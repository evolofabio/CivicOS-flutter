import 'package:cloud_firestore/cloud_firestore.dart';

import 'mock_data.dart';
import 'tenant_refs.dart';

/// Config servizi per comune: categorie, tipologie, ecc.
/// Doc: `comuni/{comuneId}/config/servizi`
class ComuneConfigService {
  ComuneConfigService._();

  static const docId = 'servizi';

  static Map<String, dynamic> get defaults => {
    'categorieSegnalazione': MockData.categorieSegnalazione,
    'tipiIngombranti': MockData.tipiIngombranti,
    'tipiRifiuto': MockData.tipiRifiuto,
    'motivazioniCisterna': MockData.motivazioniCisterna,
  };

  static List<String> _list(dynamic raw, List<String> fallback) {
    if (raw is! List) return fallback;
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  static Map<String, List<String>> parse(Map<String, dynamic>? data) {
    final d = data ?? {};
    return {
      'categorieSegnalazione': _list(
        d['categorieSegnalazione'],
        MockData.categorieSegnalazione,
      ),
      'tipiIngombranti': _list(
        d['tipiIngombranti'],
        MockData.tipiIngombranti,
      ),
      'tipiRifiuto': _list(d['tipiRifiuto'], MockData.tipiRifiuto),
      'motivazioniCisterna': _list(
        d['motivazioniCisterna'],
        MockData.motivazioniCisterna,
      ),
    };
  }

  static Future<Map<String, List<String>>> load(String comuneId) async {
    if (comuneId.isEmpty) return parse(null);
    try {
      final doc = await TenantRefs.configDoc(comuneId, docId).get();
      return parse(doc.data());
    } catch (_) {
      return parse(null);
    }
  }

  static Stream<Map<String, List<String>>> watch(String comuneId) {
    if (comuneId.isEmpty) return Stream.value(parse(null));
    return TenantRefs.configDoc(comuneId, docId).snapshots().map(
      (snap) => parse(snap.data()),
    );
  }

  static Map<String, dynamic> get defaultPartnerSanitario => {
    'nome': 'VisitaMedical',
    'sottotitolo': 'Assistenza Domiciliare e Visite Specialistiche',
    'telefono': '0963230208',
    'whatsapp': '393930156978',
    'sito': 'https://www.visitamedical.it',
    'orari': 'Lunedì–Venerdì, 8:00–20:00',
    'specialita': [
      'Cardiologia',
      'Ortopedia',
      'Dermatologia',
      'Oculistica',
      'Neurologia',
      'Ginecologia',
      'Urologia',
      'Otorinolaringoiatria',
      'Fisioterapia',
      'Pediatria',
    ],
  };

  static Map<String, dynamic> parsePartner(Map<String, dynamic>? data) {
    final raw = data?['partnerSanitario'];
    if (raw is! Map) return Map<String, dynamic>.from(defaultPartnerSanitario);
    return {...defaultPartnerSanitario, ...raw.map((k, v) => MapEntry(k.toString(), v))};
  }

  static Future<Map<String, dynamic>> loadPartner(String comuneId) async {
    if (comuneId.isEmpty) return Map<String, dynamic>.from(defaultPartnerSanitario);
    try {
      final doc = await TenantRefs.configDoc(comuneId, docId).get();
      return parsePartner(doc.data());
    } catch (_) {
      return Map<String, dynamic>.from(defaultPartnerSanitario);
    }
  }

  static Stream<Map<String, dynamic>> watchPartner(String comuneId) {
    if (comuneId.isEmpty) {
      return Stream.value(Map<String, dynamic>.from(defaultPartnerSanitario));
    }
    return TenantRefs.configDoc(comuneId, docId).snapshots().map(
      (snap) => parsePartner(snap.data()),
    );
  }

  static Future<void> save(String comuneId, Map<String, dynamic> cfg) =>
      TenantRefs.configDoc(comuneId, docId).set({
        ...cfg,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
