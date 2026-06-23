import 'package:flutter/material.dart';

class SeniorReportScreen extends StatefulWidget {
  const SeniorReportScreen({super.key});

  @override
  State<SeniorReportScreen> createState() => _SeniorReportScreenState();
}

class _SeniorReportScreenState extends State<SeniorReportScreen> {
  String? _categoriaSelezionata;
  final _descController = TextEditingController();
  bool _sending = false;

  // Categorie semplificate con icone grandi
  static const _categorie = [
    {
      'nome': 'Buca nella strada',
      'icona': Icons.edit_road,
      'colore': 0xFFE65100
    },
    {
      'nome': 'Lampione rotto',
      'icona': Icons.lightbulb_outline,
      'colore': 0xFFF9A825
    },
    {
      'nome': 'Rifiuti abbandonati',
      'icona': Icons.delete_outline,
      'colore': 0xFF00897B
    },
    {'nome': 'Problema acqua', 'icona': Icons.water_drop, 'colore': 0xFF1565C0},
    {'nome': 'Albero pericoloso', 'icona': Icons.park, 'colore': 0xFF388E3C},
    {
      'nome': 'Altro problema',
      'icona': Icons.report_problem_outlined,
      'colore': 0xFF757575
    },
  ];

  void _inviaReport() async {
    if (_categoriaSelezionata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tocca il tipo di problema prima di inviare',
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
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text(
                'Segnalazione inviata!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Grazie! Il Comune ha ricevuto la tua segnalazione.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Segnala un problema',
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
            // --- Step 1: Scegli il problema ---
            const Text(
              '1. Che problema hai visto?',
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

            ...(_categorie.map((cat) {
              final nome = cat['nome'] as String;
              final icona = cat['icona'] as IconData;
              final colore = Color(cat['colore'] as int);
              final selezionata = _categoriaSelezionata == nome;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color:
                      selezionata ? colore.withOpacity(0.12) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => setState(() => _categoriaSelezionata = nome),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selezionata ? colore : Colors.grey[300]!,
                          width: selezionata ? 3 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icona, size: 36, color: colore),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              nome,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: selezionata
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: selezionata ? colore : Colors.black87,
                              ),
                            ),
                          ),
                          if (selezionata)
                            Icon(Icons.check_circle, color: colore, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })),

            const SizedBox(height: 20),

            // --- Step 2: Descrizione (opzionale) ---
            const Text(
              '2. Vuoi aggiungere dettagli?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Facoltativo - puoi anche non scrivere nulla',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Es: La buca è vicino alla farmacia...',
                hintStyle: TextStyle(fontSize: 17, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF1565C0), width: 2),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),

            const SizedBox(height: 32),

            // --- Pulsante invio GRANDE ---
            SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _inviaReport,
                icon: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 28),
                label: Text(
                  _sending ? 'Invio in corso...' : 'INVIA SEGNALAZIONE',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
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
