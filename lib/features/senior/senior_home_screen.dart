import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/tenant.dart';
import '../../core/services/calendario_service.dart';
import 'senior_report_screen.dart';
import 'senior_booking_screen.dart';
import 'senior_comunicazioni_screen.dart';

class SeniorHomeScreen extends StatefulWidget {
  final Function(bool) onToggleSenior;
  final String comuneSelezionato;
  final String frazioneSelezionata;

  const SeniorHomeScreen({
    required this.onToggleSenior,
    required this.comuneSelezionato,
    required this.frazioneSelezionata,
    super.key,
  });

  @override
  State<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends State<SeniorHomeScreen> {
  Map<String, List<Map<String, dynamic>>> _calendarioPerFrazione = {};
  StreamSubscription<Map<String, List<Map<String, dynamic>>>>? _calendarioSub;

  static const _giorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica'
  ];

  String get _oggiGiorno => _giorni[DateTime.now().weekday - 1];

  List<Map<String, dynamic>> get _calendario =>
      CalendarioService.resolveForFrazione(
        perFrazione: _calendarioPerFrazione,
        frazione: widget.frazioneSelezionata,
      );

  @override
  void initState() {
    super.initState();
    _subscribeCalendario();
  }

  @override
  void didUpdateWidget(SeniorHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comuneSelezionato != widget.comuneSelezionato) {
      _subscribeCalendario();
    }
  }

  void _subscribeCalendario() {
    _calendarioSub?.cancel();
    final comuneId = Tenant.toId(widget.comuneSelezionato);
    _calendarioSub = CalendarioService.watchPerFrazione(comuneId).listen(
      (data) {
        if (mounted) setState(() => _calendarioPerFrazione = data);
      },
    );
  }

  @override
  void dispose() {
    _calendarioSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header benvenuto ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.waving_hand, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Benvenuto!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comune di ${widget.comuneSelezionato}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Raccolta di oggi (grande e chiara) ---
            _buildRaccoltaOggi(context),
            const SizedBox(height: 28),

            // --- Azioni principali ---
            const Text(
              'Cosa vuoi fare?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            _BigActionButton(
              icon: Icons.warning_amber_rounded,
              label: 'Segnala un\nproblema',
              subtitle: 'Buca, lampione rotto, rifiuti...',
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SeniorReportScreen(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _BigActionButton(
              icon: Icons.calendar_today_rounded,
              label: 'Prenota un\nservizio',
              subtitle: 'Ritiro ingombranti, acqua...',
              color: const Color(0xFF00897B),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SeniorBookingScreen(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _BigActionButton(
              icon: Icons.mail_rounded,
              label: 'Avvisi del\nComune',
              subtitle: 'Notizie, allerte, eventi',
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SeniorComunicazioniScreen(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _BigActionButton(
              icon: Icons.phone_in_talk_rounded,
              label: 'Chiama il\nComune',
              subtitle: 'Parla con un operatore',
              color: const Color(0xFF6A1B9A),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Chiama il Comune',
                      style: TextStyle(fontSize: 22),
                    ),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, size: 48, color: Color(0xFF6A1B9A)),
                        SizedBox(height: 12),
                        Text(
                          '0123 456 789',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Lun-Ven: 8:30 - 13:00\nMar e Gio: anche 15:00 - 17:00',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Chiudi',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // --- Toggle per uscire dalla modalità senior ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.accessibility_new,
                      size: 28, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Modalità Facilitata attiva',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: widget.onToggleSenior,
                    activeColor: const Color(0xFF1565C0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRaccoltaOggi(BuildContext context) {
    final oggi = _calendario.firstWhere(
      (g) => g['giorno'] == _oggiGiorno,
      orElse: () => {'tipi': <String>[], 'variazione': null},
    );
    final tipi = (oggi['tipi'] as List).cast<String>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, size: 28, color: Color(0xFF00897B)),
              SizedBox(width: 8),
              Text(
                'Raccolta di Oggi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00897B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (tipi.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nessuna raccolta prevista oggi',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          else
            ...tipi.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _rifiutoColor(t).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _rifiutoColor(t).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        _rifiutoIcon(t, size: 32),
                        const SizedBox(width: 14),
                        Text(
                          t.toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _rifiutoColor(t),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _rifiutoIcon(String tipo, {double size = 24}) {
    IconData icon;
    switch (tipo.toLowerCase()) {
      case 'umido':
        icon = Icons.eco;
      case 'plastica':
        icon = Icons.local_drink;
      case 'carta':
        icon = Icons.description;
      case 'vetro':
        icon = Icons.wine_bar;
      case 'metalli':
        icon = Icons.settings;
      case 'secco residuo':
      case 'secco':
        icon = Icons.delete;
      default:
        icon = Icons.circle;
    }
    return Icon(icon, color: _rifiutoColor(tipo), size: size);
  }

  Color _rifiutoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'umido':
        return Colors.brown;
      case 'plastica':
        return Colors.orange;
      case 'carta':
        return Colors.blue;
      case 'vetro':
        return Colors.green;
      case 'metalli':
        return Colors.grey;
      case 'secco residuo':
      case 'secco':
        return Colors.black54;
      default:
        return Colors.teal;
    }
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
