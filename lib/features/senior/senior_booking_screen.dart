import 'package:flutter/material.dart';

class SeniorBookingScreen extends StatefulWidget {
  const SeniorBookingScreen({super.key});

  @override
  State<SeniorBookingScreen> createState() => _SeniorBookingScreenState();
}

class _SeniorBookingScreenState extends State<SeniorBookingScreen> {
  String? _servizioSelezionato;
  DateTime? _dataSelezionata;
  bool _sending = false;

  // Servizi semplificati
  static const _servizi = [
    {
      'nome': 'Ritiro ingombranti',
      'icona': Icons.chair,
      'colore': 0xFFE65100,
      'desc': 'Mobili, elettrodomestici, materassi',
    },
    {
      'nome': 'Richiesta acqua',
      'icona': Icons.water_drop,
      'colore': 0xFF1565C0,
      'desc': 'Rifornimento cisterna',
    },
    {
      'nome': 'Ritiro verde',
      'icona': Icons.park,
      'colore': 0xFF00897B,
      'desc': 'Potature, sfalci, foglie',
    },
    {
      'nome': 'Ritiro RAEE',
      'icona': Icons.devices,
      'colore': 0xFF6A1B9A,
      'desc': 'TV, computer, vecchi telefoni',
    },
  ];

  Future<void> _selezionaData() async {
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'SCEGLI IL GIORNO',
      cancelText: 'ANNULLA',
      confirmText: 'CONFERMA',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.1),
          ),
          child: child!,
        );
      },
    );
    if (data != null) setState(() => _dataSelezionata = data);
  }

  void _prenota() async {
    if (_servizioSelezionato == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scegli prima un servizio',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
      return;
    }
    if (_dataSelezionata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scegli una data per il ritiro',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _sending = false);
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Prenotazione confermata!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Il servizio "$_servizioSelezionato" è stato prenotato.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Torna alla Home',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatData(DateTime d) {
    const mesi = [
      '',
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    const giorni = [
      '',
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
      'Domenica',
    ];
    return '${giorni[d.weekday]} ${d.day} ${mesi[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        title: const Text(
          'Prenota un servizio',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Step 1: Scegli il servizio ---
            const Text(
              '1. Cosa ti serve?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tocca per selezionare',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),

            ...(_servizi.map((serv) {
              final nome = serv['nome'] as String;
              final icona = serv['icona'] as IconData;
              final colore = Color(serv['colore'] as int);
              final desc = serv['desc'] as String;
              final selezionato = _servizioSelezionato == nome;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color:
                      selezionato ? colore.withOpacity(0.12) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => setState(() => _servizioSelezionato = nome),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selezionato ? colore : Colors.grey[300]!,
                          width: selezionato ? 3 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icona, size: 36, color: colore),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: selezionato
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color:
                                        selezionato ? colore : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selezionato)
                            Icon(Icons.check_circle, color: colore, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })),

            const SizedBox(height: 24),

            // --- Step 2: Scegli la data ---
            const Text(
              '2. Quando vuoi il servizio?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 14),

            Material(
              color: _dataSelezionata != null
                  ? const Color(0xFFE8F5E9)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _selezionaData,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _dataSelezionata != null
                          ? const Color(0xFF00897B)
                          : Colors.grey[300]!,
                      width: _dataSelezionata != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 36,
                        color: _dataSelezionata != null
                            ? const Color(0xFF00897B)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _dataSelezionata != null
                              ? _formatData(_dataSelezionata!)
                              : 'Tocca per scegliere la data',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: _dataSelezionata != null
                                ? FontWeight.bold
                                : FontWeight.w400,
                            color: _dataSelezionata != null
                                ? const Color(0xFF00897B)
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (_dataSelezionata != null)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF00897B), size: 28),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Pulsante PRENOTA ---
            SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _prenota,
                icon: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 28),
                label: Text(
                  _sending ? 'Prenotazione...' : 'PRENOTA',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
