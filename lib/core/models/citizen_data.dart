import 'package:flutter/material.dart';

/// Singola abitazione del cittadino.
class Abitazione {
  String titolarita; // Proprietario, Affittuario, Comodato, etc.
  String tipoImmobile; // Abitazione principale, Seconda casa, etc.
  String superficie;
  String renditaCatastale;
  String categoriaCatastale;
  String nucleoFamiliare;

  Abitazione({
    this.titolarita = '',
    this.tipoImmobile = '',
    this.superficie = '',
    this.renditaCatastale = '',
    this.categoriaCatastale = '',
    this.nucleoFamiliare = '',
  });

  bool get isValid => titolarita.isNotEmpty && tipoImmobile.isNotEmpty;

  Abitazione copyWith({
    String? titolarita,
    String? tipoImmobile,
    String? superficie,
    String? renditaCatastale,
    String? categoriaCatastale,
    String? nucleoFamiliare,
  }) {
    return Abitazione(
      titolarita: titolarita ?? this.titolarita,
      tipoImmobile: tipoImmobile ?? this.tipoImmobile,
      superficie: superficie ?? this.superficie,
      renditaCatastale: renditaCatastale ?? this.renditaCatastale,
      categoriaCatastale: categoriaCatastale ?? this.categoriaCatastale,
      nucleoFamiliare: nucleoFamiliare ?? this.nucleoFamiliare,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titolarita': titolarita,
      'tipoImmobile': tipoImmobile,
      'superficie': superficie,
      'renditaCatastale': renditaCatastale,
      'categoriaCatastale': categoriaCatastale,
      'nucleoFamiliare': nucleoFamiliare,
    };
  }

  factory Abitazione.fromMap(Map<String, dynamic> map) {
    return Abitazione(
      titolarita: (map['titolarita'] ?? '').toString(),
      tipoImmobile: (map['tipoImmobile'] ?? '').toString(),
      superficie: (map['superficie'] ?? '').toString(),
      renditaCatastale: (map['renditaCatastale'] ?? '').toString(),
      categoriaCatastale: (map['categoriaCatastale'] ?? '').toString(),
      nucleoFamiliare: (map['nucleoFamiliare'] ?? '').toString(),
    );
  }
}

/// Modello dati del cittadino – anagrafica, residenza, abitazioni e spese.
/// Implementa ChangeNotifier per reagire agli aggiornamenti nel profilo.
class CitizenData extends ChangeNotifier {
  // ── Anagrafica ──
  String nome;
  String cognome;
  String dataNascita;
  String codiceFiscale;
  String telefono;
  String email;

  // ── Residenza ──
  String indirizzo;
  String civico;
  String cap;
  String provincia;

  // ── Abitazioni (più di una) ──
  final List<Abitazione> abitazioni;

  CitizenData({
    this.nome = '',
    this.cognome = '',
    this.dataNascita = '',
    this.codiceFiscale = '',
    this.telefono = '',
    this.email = '',
    this.indirizzo = '',
    this.civico = '',
    this.cap = '',
    this.provincia = 'VV',
    List<Abitazione>? abitazioni,
  }) : abitazioni = abitazioni ?? [];

  bool get hasAnagrafica =>
      nome.isNotEmpty && cognome.isNotEmpty && codiceFiscale.isNotEmpty;

  bool get hasAbitazione => abitazioni.any((a) => a.isValid);

  void updateAnagrafica({
    required String nome,
    required String cognome,
    required String dataNascita,
    required String codiceFiscale,
    required String telefono,
    required String email,
  }) {
    this.nome = nome;
    this.cognome = cognome;
    this.dataNascita = dataNascita;
    this.codiceFiscale = codiceFiscale;
    this.telefono = telefono;
    this.email = email;
    notifyListeners();
  }

  void updateResidenza({
    required String indirizzo,
    required String civico,
    required String cap,
    required String provincia,
  }) {
    this.indirizzo = indirizzo;
    this.civico = civico;
    this.cap = cap;
    this.provincia = provincia;
    notifyListeners();
  }

  void addAbitazione(Abitazione abitazione) {
    abitazioni.add(abitazione);
    notifyListeners();
  }

  void updateAbitazione(int index, Abitazione abitazione) {
    if (index >= 0 && index < abitazioni.length) {
      abitazioni[index] = abitazione;
      notifyListeners();
    }
  }

  void removeAbitazione(int index) {
    if (index >= 0 && index < abitazioni.length) {
      abitazioni.removeAt(index);
      notifyListeners();
    }
  }

  void hydrateFromMap(Map<String, dynamic> map) {
    final residenzaRaw = map['residenza'];
    final residenza = residenzaRaw is Map
        ? Map<String, dynamic>.from(residenzaRaw)
        : <String, dynamic>{};

    final abitazioniRaw = map['abitazioni'];
    final parsedAbitazioni = <Abitazione>[];
    if (abitazioniRaw is List) {
      for (final item in abitazioniRaw) {
        if (item is Map) {
          parsedAbitazioni.add(
            Abitazione.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    if (map.containsKey('nome')) nome = (map['nome'] ?? '').toString();
    if (map.containsKey('cognome')) cognome = (map['cognome'] ?? '').toString();
    if (map.containsKey('dataNascita')) {
      dataNascita = (map['dataNascita'] ?? '').toString();
    }
    if (map.containsKey('codiceFiscale')) {
      codiceFiscale = (map['codiceFiscale'] ?? '').toString();
    }
    if (map.containsKey('telefono')) {
      telefono = (map['telefono'] ?? '').toString();
    }
    if (map.containsKey('email')) email = (map['email'] ?? '').toString();

    final hasIndirizzo =
        residenza.containsKey('indirizzo') || map.containsKey('indirizzo');
    final hasCivico =
        residenza.containsKey('civico') || map.containsKey('civico');
    final hasCap = residenza.containsKey('cap') || map.containsKey('cap');
    final hasProvincia =
        residenza.containsKey('provincia') || map.containsKey('provincia');

    if (hasIndirizzo) {
      indirizzo = (residenza['indirizzo'] ?? map['indirizzo'] ?? '').toString();
    }
    if (hasCivico) {
      civico = (residenza['civico'] ?? map['civico'] ?? '').toString();
    }
    if (hasCap) {
      cap = (residenza['cap'] ?? map['cap'] ?? '').toString();
    }
    if (hasProvincia) {
      provincia = (residenza['provincia'] ?? map['provincia'] ?? 'VV')
          .toString();
    }

    if (map.containsKey('abitazioni')) {
      abitazioni
        ..clear()
        ..addAll(parsedAbitazioni);
    }

    notifyListeners();
  }
}
