import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/tenant.dart';
import '../../core/services/calendario_service.dart';

class CalendarioRaccoltaScreen extends StatefulWidget {
  final String frazioneSelezionata;
  final String comuneSelezionato;

  const CalendarioRaccoltaScreen({
    required this.frazioneSelezionata,
    required this.comuneSelezionato,
    super.key,
  });

  @override
  State<CalendarioRaccoltaScreen> createState() =>
      _CalendarioRaccoltaScreenState();
}

class _CalendarioRaccoltaScreenState extends State<CalendarioRaccoltaScreen> {
  Map<String, List<Map<String, dynamic>>> _calendarioPerFrazione = {};
  StreamSubscription<Map<String, List<Map<String, dynamic>>>>? _calendarioSub;

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

  IconData _rifiutoIconData(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'umido':
        return Icons.eco;
      case 'plastica':
        return Icons.local_drink;
      case 'carta':
        return Icons.description;
      case 'vetro':
        return Icons.wine_bar;
      case 'metalli':
        return Icons.kitchen;
      case 'secco residuo':
      case 'secco':
        return Icons.delete;
      default:
        return Icons.circle;
    }
  }

  String _rifiutoTip(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'umido':
        return 'Scarti di cucina, avanzi, fondi di caffè. No plastica.';
      case 'plastica':
        return 'Bottiglie, flaconi, vaschette. Sciacquare e schiacciare.';
      case 'carta':
        return 'Giornali, scatole, cartoni. No carta sporca di cibo.';
      case 'vetro':
        return 'Bottiglie e barattoli. Sciacquare. No ceramica.';
      case 'metalli':
        return 'Lattine e barattoli metallici. Sciacquare.';
      case 'secco residuo':
      case 'secco':
        return 'Tutto ciò che non può essere riciclato.';
      default:
        return '';
    }
  }

  static const _giorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  String get _oggiGiorno {
    final weekday = DateTime.now().weekday;
    return _giorni[weekday - 1];
  }

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Raccolta'),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF8FAFD),
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Header comune/frazione
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.comuneSelezionato} — ${widget.frazioneSelezionata}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Card per ogni giorno
            ..._calendario.map((giorno) {
              final nome = giorno['giorno'] as String;
              final tipi = (giorno['tipi'] as List).cast<String>();
              final variazione = giorno['variazione'] as String?;
              final isOggi = nome == _oggiGiorno;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  elevation: isOggi ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isOggi
                        ? BorderSide(color: cs.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Colonna sinistra: giorno + chips tipo ──
                        SizedBox(
                          width: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isOggi) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Text(
                                        'OGGI',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isOggi ? cs.primary : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (tipi.isEmpty)
                                Text(
                                  'Nessuna raccolta',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: tipi.map((t) {
                                    final color = _rifiutoColor(t);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: color.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _rifiutoIconData(t),
                                            color: color,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            t,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              if (variazione != null &&
                                  variazione != 'Nessuna raccolta') ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 12,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        variazione,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // ── Divisore verticale ──
                        if (tipi.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(width: 1, color: Colors.grey[200]),
                          const SizedBox(width: 12),
                          // ── Colonna destra: come preparare ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Come preparare',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...tipi.map((t) {
                                  final tip = _rifiutoTip(t);
                                  if (tip.isEmpty) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          _rifiutoIconData(t),
                                          size: 13,
                                          color: _rifiutoColor(t),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            tip,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
