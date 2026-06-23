import 'package:cloud_firestore/cloud_firestore.dart';

import 'mock_data.dart';
import 'tenant_refs.dart';

/// Calendario raccolta differenziata: Firestore con fallback locale.
///
/// Schema Firestore: `comuni/{comuneId}/calendari/differenziata`
/// ```json
/// { "perFrazione": { "Bivona": [{ "giorno": "Lunedì", "tipi": [...], "variazione": null }] } }
/// ```
class CalendarioService {
  CalendarioService._();

  static const docId = 'differenziata';

  static List<Map<String, dynamic>> fallbackForFrazione(String frazione) =>
      MockData.calendarioPerFrazione[frazione] ?? MockData.calendarioRaccolta;

  static List<Map<String, dynamic>> _parseGiorni(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (row) => {
            'giorno': (row['giorno'] ?? '').toString(),
            'tipi': (row['tipi'] as List<dynamic>? ?? [])
                .map((t) => t.toString())
                .where((t) => t.isNotEmpty)
                .toList(),
            'variazione': row['variazione'],
          },
        )
        .toList();
  }

  static Map<String, List<Map<String, dynamic>>> parsePerFrazione(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return {};
    final raw = data['perFrazione'];
    if (raw is! Map) return {};
    final out = <String, List<Map<String, dynamic>>>{};
    raw.forEach((key, value) {
      final parsed = _parseGiorni(value);
      if (parsed.isNotEmpty) {
        out[key.toString()] = parsed;
      }
    });
    return out;
  }

  static Future<Map<String, List<Map<String, dynamic>>>> loadPerFrazione(
    String comuneId,
  ) async {
    if (comuneId.isEmpty) return {};
    try {
      final doc = await TenantRefs.calendariCol(comuneId).doc(docId).get();
      if (!doc.exists) return {};
      return parsePerFrazione(doc.data());
    } catch (_) {
      return {};
    }
  }

  static Stream<Map<String, List<Map<String, dynamic>>>> watchPerFrazione(
    String comuneId,
  ) {
    if (comuneId.isEmpty) {
      return Stream.value({});
    }
    return TenantRefs.calendariCol(comuneId).doc(docId).snapshots().map(
      (snap) => snap.exists ? parsePerFrazione(snap.data()) : {},
    );
  }

  static Future<List<Map<String, dynamic>>> loadForFrazione({
    required String comuneId,
    required String frazione,
  }) async {
    final perFrazione = await loadPerFrazione(comuneId);
    return perFrazione[frazione] ?? fallbackForFrazione(frazione);
  }

  static List<Map<String, dynamic>> resolveForFrazione({
    required Map<String, List<Map<String, dynamic>>> perFrazione,
    required String frazione,
  }) =>
      perFrazione[frazione] ?? fallbackForFrazione(frazione);

  static Set<String> tipiForDay(
    List<Map<String, dynamic>> calendario,
    String giorno,
  ) {
    final tipi = <String>{};
    for (final row in calendario) {
      if ((row['giorno'] as String? ?? '') != giorno) continue;
      for (final t in (row['tipi'] as List<dynamic>? ?? [])) {
        final value = t.toString().trim();
        if (value.isNotEmpty) tipi.add(value);
      }
    }
    return tipi;
  }

  static Set<String> tipiForDayAllFrazioni(
    Map<String, List<Map<String, dynamic>>> perFrazione,
    String giorno,
  ) {
    final tipi = <String>{};
    if (perFrazione.isEmpty) {
      for (final calendario in MockData.calendarioPerFrazione.values) {
        tipi.addAll(tipiForDay(calendario, giorno));
      }
      if (tipi.isEmpty) {
        tipi.addAll(tipiForDay(MockData.calendarioRaccolta, giorno));
      }
      return tipi;
    }
    for (final calendario in perFrazione.values) {
      tipi.addAll(tipiForDay(calendario, giorno));
    }
    return tipi;
  }

  static String weekdayNameIt(DateTime date) {
    switch (date.weekday) {
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

  static Future<void> savePerFrazione({
    required String comuneId,
    required Map<String, List<Map<String, dynamic>>> perFrazione,
  }) =>
      TenantRefs.calendariCol(comuneId).doc(docId).set({
        'perFrazione': perFrazione,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
