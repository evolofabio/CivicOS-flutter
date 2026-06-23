import 'tenant_refs.dart';

class AziendaConvenzionata {
  const AziendaConvenzionata({
    required this.id,
    required this.ragioneSociale,
    required this.settore,
    this.telefono = '',
    this.email = '',
    this.indirizzo = '',
    this.sito = '',
  });

  final String id;
  final String ragioneSociale;
  final String settore;
  final String telefono;
  final String email;
  final String indirizzo;
  final String sito;

  static AziendaConvenzionata fromMap(String id, Map<String, dynamic> data) {
    return AziendaConvenzionata(
      id: id,
      ragioneSociale: (data['ragioneSociale'] ?? '').toString(),
      settore: (data['settore'] ?? '').toString(),
      telefono: (data['telefono'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      indirizzo: (data['indirizzo'] ?? '').toString(),
      sito: (data['sito'] ?? data['website'] ?? '').toString(),
    );
  }

  bool get isSanitaria {
    final s = settore.toLowerCase();
    return s.contains('sanit') ||
        s.contains('salute') ||
        s.contains('medic') ||
        s.contains('assistenza');
  }
}

class AziendeService {
  AziendeService._();

  static Stream<List<AziendaConvenzionata>> watch(String comuneId) {
    if (comuneId.isEmpty) return Stream.value(const []);
    return TenantRefs.aziendeCol(comuneId)
        .orderBy('ragioneSociale')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AziendaConvenzionata.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  static Future<List<AziendaConvenzionata>> load(String comuneId) async {
    if (comuneId.isEmpty) return [];
    final snap = await TenantRefs.aziendeCol(comuneId)
        .orderBy('ragioneSociale')
        .get();
    return snap.docs
        .map((d) => AziendaConvenzionata.fromMap(d.id, d.data()))
        .toList();
  }

  static List<AziendaConvenzionata> filterSanitarie(
    List<AziendaConvenzionata> list,
  ) =>
      list.where((a) => a.isSanitaria).toList();
}
