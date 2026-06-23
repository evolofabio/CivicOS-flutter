import '../models/tenant.dart';
import 'mock_data.dart';
import 'tenant_refs.dart';

/// Catalogo comuni/frazioni: statico + overlay Firestore.
class ComuniCatalog {
  ComuniCatalog._();

  static Map<String, List<String>> get comuni => MockData.comuni;
  static Iterable<String> get nomi => comuni.keys;
  static const String defaultComune = MockData.comune;
  static List<String> get defaultFrazioni => MockData.frazioni;

  static bool contains(String name) => comuni.containsKey(name);

  static List<String> frazioniStatiche(String comuneName) =>
      comuni[comuneName] ?? const [];

  static String? normalizeName(String? comune, String? comuneId) {
    if (comune != null && contains(comune)) return comune;
    if (comuneId == null || comuneId.isEmpty) return null;
    for (final c in comuni.keys) {
      if (Tenant.toId(c) == comuneId) return c;
    }
    return null;
  }

  static String displayNameFromId(String comuneId) =>
      comuni.keys.firstWhere(
        (k) => Tenant.toId(k) == comuneId,
        orElse: () => comuneId,
      );

  static String resolveFrazione(String comuneName, String? frazione) {
    final list = frazioniStatiche(comuneName);
    if (frazione != null && list.contains(frazione)) return frazione;
    return list.isNotEmpty ? list.first : '';
  }

  /// Frazioni: prima Firestore (`comuni/{id}.frazioni`), poi catalogo statico.
  static Future<List<String>> frazioniForComuneId(
    String comuneId, {
    String? comuneName,
  }) async {
    if (comuneId.isNotEmpty) {
      try {
        final doc = await TenantRefs.comuneDoc(comuneId).get();
        final remote = doc.data()?['frazioni'];
        if (remote is List && remote.isNotEmpty) {
          return remote.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    final name = comuneName ?? normalizeName(null, comuneId) ?? '';
    return frazioniStatiche(name);
  }
}
