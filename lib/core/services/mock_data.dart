class MockData {
  // Lista comuni disponibili, ciascuno con le proprie frazioni
  static Map<String, List<String>> comuni = {
    'Acquaro': ['Ariola', 'Piani', 'Piani di Acquaro', 'Serrata'],
    'Arena': [
      'Bivieri',
      'Croce',
      'Malgari',
      'Piani di Arena',
      'Santa Maria',
      'Santicelli',
    ],
    'Briatico': ['Mandaradoni', 'Paradisoni', 'Potenzoni', 'San Costantino'],
    'Brognaturo': [],
    'Capistrano': ['San Nicola'],
    'Cessaniti': [
      'Pannaconi',
      'San Cono',
      'Favelloni',
      'Mantineo',
      'Piana Pugliese',
      'San Michele',
      "Sant'Andrea",
      'Vena',
    ],
    'Dasà': ["Sant'Antonio"],
    'Dinami': ['Monsoreto', 'Melicuccà', 'San Giovanni'],
    'Drapia': ['Brattirò', 'Caria', 'Gasponi'],
    'Fabrizia': ['Cassari', 'Ciano'],
    'Filadelfia': [
      'Montesoro',
      'Piano delle Querce',
      'San Giovanni',
      'San Teodoro',
      'Fossa',
      'Caria',
      'Lenza',
    ],
    'Filandari': ['Arzona', 'Mesiano', 'Scaliti', 'Vena di Maida'],
    'Francavilla Angitola': ['Motta Filocastro', 'Calvario'],
    'Francica': [],
    'Gerocarne': ['Ariola', 'Ciano', "Sant'Angelo"],
    'Ionadi': ['Nao', 'Vena di Ionadi'],
    'Joppolo': ['Coccorino', 'Coccorinello', 'Caroniti'],
    'Limbadi': ['Badia', 'Motta Filocastro', 'San Nicola De Legistis'],
    'Maierato': [],
    'Mileto': ['Calabrò', 'Comparni', 'Paravati'],
    'Mongiana': [],
    'Monterosso Calabro': [],
    'Nardodipace': ['Cassari', 'Ragonà', 'San Todaro', 'Vecchio Abitato'],
    'Nicotera': [
      'Badia',
      'Comerconi',
      'Marina di Nicotera',
      'Preitoni',
      'San Nicola',
      'Monte Poro',
    ],
    'Parghelia': ['Fitili', 'Michelizia'],
    'Pizzo': ['Marinella', 'Prangi'],
    'Pizzoni': ['Vascellero', 'San Nicola'],
    'Polia': ['Trecroci', 'Menniti', 'Poliolo'],
    'Ricadi': [
      'Brivadi',
      'Lampazzone',
      'Orsigliadi',
      'San Nicolò',
      'Santa Domenica',
      'Santa Maria',
    ],
    'Rombiolo': ['Pernocari', 'Presinaci', 'Moladi', 'Mesiano'],
    'San Calogero': ['Calimera'],
    'San Costantino Calabro': ['San Costantino Scalo'],
    'San Gregorio d\'Ippona': ['Zammarò'],
    'San Nicola da Crissa': ['Piscopio', 'Trivio'],
    "Sant'Onofrio": ['Papanice'],
    'Serra San Bruno': ['Ellera', 'Ninfo', 'Spinetto'],
    'Simbario': ['Piani di Simbario'],
    'Soriano Calabro': ['San Domenico'],
    'Spadola': [],
    'Spilinga': ['Carciadi', 'Panaja'],
    'Stefanaconi': ["Sant'Angelo"],
    'Tropea': [],
    'Vallelonga': [],
    'Vazzano': [],
    'Vibo Valentia': [
      'Bivona',
      'Longobardi',
      'Piscopio',
      'Porto Salvo',
      'San Pietro di Bivona',
      'Triparni',
      'Vena Inferiore',
      'Vena Media',
      'Vena Superiore',
      'Vibo Marina',
    ],
    'Zaccanopoli': ['Coccorino'],
    'Zambrone': ['Daffinà', 'San Giovanni'],
    'Zungri': ['Papaglionti'],
  };

  // Defaults
  static const String comune = 'Vibo Valentia';
  static List<String> frazioni = [
    'Bivona',
    'Longobardi',
    'Piscopio',
    'Porto Salvo',
    'San Pietro di Bivona',
    'Triparni',
    'Vena Inferiore',
    'Vena Media',
    'Vena Superiore',
    'Vibo Marina',
  ];

  // Calendario raccolta per ogni frazione
  static Map<String, List<Map<String, dynamic>>> calendarioPerFrazione = {
    'Bivona': [
      {
        "giorno": "Lunedì",
        "tipi": ["Umido", "Vetro"],
        "variazione": null,
      },
      {
        "giorno": "Martedì",
        "tipi": ["Plastica", "Metalli"],
        "variazione": null,
      },
      {
        "giorno": "Mercoledì",
        "tipi": ["Umido", "Carta"],
        "variazione": null,
      },
      {
        "giorno": "Giovedì",
        "tipi": ["Secco residuo"],
        "variazione": null,
      },
      {
        "giorno": "Venerdì",
        "tipi": ["Umido", "Plastica"],
        "variazione": null,
      },
      {
        "giorno": "Sabato",
        "tipi": ["Carta", "Vetro"],
        "variazione": "Raccolta posticipata ore 10:00 per festività",
      },
      {"giorno": "Domenica", "tipi": [], "variazione": "Nessuna raccolta"},
    ],
    'Piscopio': [
      {
        "giorno": "Lunedì",
        "tipi": ["Plastica", "Metalli"],
        "variazione": null,
      },
      {
        "giorno": "Martedì",
        "tipi": ["Umido", "Vetro"],
        "variazione": null,
      },
      {
        "giorno": "Mercoledì",
        "tipi": ["Secco residuo"],
        "variazione": null,
      },
      {
        "giorno": "Giovedì",
        "tipi": ["Umido", "Carta"],
        "variazione": null,
      },
      {
        "giorno": "Venerdì",
        "tipi": ["Vetro", "Plastica"],
        "variazione": null,
      },
      {
        "giorno": "Sabato",
        "tipi": ["Umido"],
        "variazione": null,
      },
      {"giorno": "Domenica", "tipi": [], "variazione": "Nessuna raccolta"},
    ],
    'Vibo Marina': [
      {
        "giorno": "Lunedì",
        "tipi": ["Umido", "Carta"],
        "variazione": null,
      },
      {
        "giorno": "Martedì",
        "tipi": ["Vetro"],
        "variazione": null,
      },
      {
        "giorno": "Mercoledì",
        "tipi": ["Umido", "Plastica", "Metalli"],
        "variazione": null,
      },
      {
        "giorno": "Giovedì",
        "tipi": ["Carta"],
        "variazione": null,
      },
      {
        "giorno": "Venerdì",
        "tipi": ["Umido", "Secco residuo"],
        "variazione": null,
      },
      {
        "giorno": "Sabato",
        "tipi": ["Plastica", "Vetro"],
        "variazione": null,
      },
      {"giorno": "Domenica", "tipi": [], "variazione": "Nessuna raccolta"},
    ],
    'Triparni': [
      {
        "giorno": "Lunedì",
        "tipi": ["Umido"],
        "variazione": null,
      },
      {
        "giorno": "Martedì",
        "tipi": ["Plastica", "Carta"],
        "variazione": null,
      },
      {
        "giorno": "Mercoledì",
        "tipi": ["Umido", "Vetro"],
        "variazione": null,
      },
      {
        "giorno": "Giovedì",
        "tipi": ["Metalli", "Secco residuo"],
        "variazione": null,
      },
      {
        "giorno": "Venerdì",
        "tipi": ["Umido"],
        "variazione": null,
      },
      {"giorno": "Sabato", "tipi": [], "variazione": "Nessuna raccolta"},
      {"giorno": "Domenica", "tipi": [], "variazione": "Nessuna raccolta"},
    ],
  };

  // Raccolta di oggi (per la frazione selezionata)
  static List<Map<String, dynamic>> raccoltaOggi = [];

  // Alias: calendario per retrofit (usa Bivona di default)
  static List<Map<String, dynamic>> get calendarioRaccolta =>
      calendarioPerFrazione['Bivona']!;

  static List<String> avvisi = [];

  // Comunicazioni ufficiali dal Comune
  static List<Map<String, dynamic>> comunicazioni = [];

  static List<String> categorieSegnalazione = [
    'Rifiuti abbandonati',
    'Discariche abusive',
    'Cestini pieni',
    'Degrado urbano',
    'Illuminazione',
    'Strade',
    'Verde pubblico',
    'Igiene pubblica',
  ];

  // Storico segnalazioni inviate
  static List<Map<String, dynamic>> storicoSegnalazioni = [];

  // Storico prenotazioni ingombranti
  static List<Map<String, dynamic>> storicoPrenotazioni = [];

  static List<String> tipiRifiuto = ['Umido', 'Secco', 'Plastica', 'Carta'];

  // Tipi rifiuti ingombranti (come da PDF)
  static List<String> tipiIngombranti = [
    'Mobili',
    'Elettrodomestici',
    'Materassi',
    'Elettronica',
    'Altro',
  ];

  // Motivazioni richiesta rifornimento cisterna acqua
  static List<String> motivazioniCisterna = [
    'Assenza totale di acqua',
    'Pressione insufficiente',
    'Cisterna vuota (periodo estivo)',
    'Guasto alla rete idrica',
    'Lavori programmati sulla rete',
    'Altro',
  ];

  // Storico richieste cisterne acqua
  static List<Map<String, dynamic>> storicoRichiesteCisterne = [];
}
