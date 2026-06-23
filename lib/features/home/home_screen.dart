import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/models/tenant.dart';
import '../../core/services/calendario_service.dart';
import '../../core/services/tenant_refs.dart';
import '../calendario_raccolta/calendario_raccolta_screen.dart';
import '../info/differenziata_info_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onToggleSenior;
  final bool seniorMode;
  final String comuneSelezionato;
  final String frazioneSelezionata;
  const HomeScreen({
    required this.onToggleSenior,
    required this.seniorMode,
    required this.comuneSelezionato,
    required this.frazioneSelezionata,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Map<String, dynamic>>> _calendarioPerFrazione = {};
  StreamSubscription<Map<String, List<Map<String, dynamic>>>>? _calendarioSub;

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
    final weekday = DateTime.now().weekday; // 1=Mon
    return _giorni[weekday - 1];
  }

  String get _domaniGiorno {
    final weekday = DateTime.now().weekday;
    return _giorni[weekday % 7]; // next day, wraps Sun→Mon
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

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info raccolta differenziata
            Card(
              color: cs.primary.withOpacity(0.07),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Raccolta Differenziata',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scopri come separare correttamente i rifiuti e perché è importante fare la raccolta differenziata. Consulta la guida completa!',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.menu_book, size: 18),
                        label: const Text('Guida raccolta differenziata'),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.primary,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DifferenziataInfoScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // --- Comune & Frazione (premium header card) ---
            Container(
              decoration: BoxDecoration(
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? LinearGradient(
                        colors: [cs.primaryContainer, cs.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF0D3B7A), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.shield, color: cs.onPrimary, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comune di ${widget.comuneSelezionato}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: cs.onPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.frazioneSelezionata,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onPrimary.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Raccolta di oggi ---
            Text(
              'Raccolta Oggi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final oggi = _calendario.firstWhere(
                  (g) => g['giorno'] == _oggiGiorno,
                  orElse: () => {'tipi': [], 'variazione': null},
                );
                final tipi = (oggi['tipi'] as List).cast<String>();
                final variazione = oggi['variazione'] as String?;

                if (tipi.isEmpty) {
                  return Card(
                    color: cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Nessuna raccolta prevista oggi',
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tipi.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(width: 16),
                        itemBuilder: (context, i) {
                          final t = tipi[i];
                          return SizedBox(
                            width: 180,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _rifiutoColor(t).withOpacity(0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _rifiutoColor(t).withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _rifiutoColor(t).withOpacity(0.13),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: _rifiutoIcon(t, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Flexible(
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: _rifiutoColor(t),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (variazione != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              variazione,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // --- Raccolta di domani ---
            Text(
              'Raccolta Domani',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final domani = _calendario.firstWhere(
                  (g) => g['giorno'] == _domaniGiorno,
                  orElse: () => {'tipi': [], 'variazione': null},
                );
                final tipi = (domani['tipi'] as List).cast<String>();

                if (tipi.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Nessuna raccolta prevista',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tipi.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _rifiutoColor(t).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _rifiutoColor(t).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _rifiutoIcon(t, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onPrimary.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),

            // --- Vedi calendario completo ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CalendarioRaccoltaScreen(
                        frazioneSelezionata: widget.frazioneSelezionata,
                        comuneSelezionato: widget.comuneSelezionato,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Vedi calendario completo'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // --- Dashboard Segnalazioni ---
            Text(
              'Le tue Segnalazioni',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            // Stats row
            _buildSegnalazioniStats(cs),
            const SizedBox(height: 12),
            // Ultime richieste
            _buildUltimeRichieste(cs),
            const SizedBox(height: 28),

            // --- Ultimi avvisi ---
            Text(
              'Ultimi Avvisi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _buildUltimiAvvisi(cs),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final parts = value.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatData(dynamic value) {
    final dt = _asDateTime(value);
    if (dt.millisecondsSinceEpoch == 0) return '';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Widget _buildUltimiAvvisi(ColorScheme cs) {
    final tenant = Provider.of<Tenant>(context, listen: false);
    final frazioneNorm = widget.frazioneSelezionata.trim().toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: TenantRefs.comunicazioniCol(tenant.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        final avvisi = docs
            .map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final stato = (d['stato'] ?? 'attivo').toString().toLowerCase();
              final frazioni =
                  (d['frazioni'] as List<dynamic>?)
                      ?.map((e) => e.toString().trim().toLowerCase())
                      .where((e) => e.isNotEmpty)
                      .toList() ??
                  <String>[];
              final isForFrazione =
                  frazioni.isEmpty || frazioni.contains(frazioneNorm);
              if (stato != 'attivo' || !isForFrazione) return null;

              final sortDate = _asDateTime(
                d['dataTs'] ?? d['publishedAt'] ?? d['timestamp'] ?? d['data'],
              );

              return <String, dynamic>{
                'titolo': (d['titolo'] ?? '').toString(),
                'corpo': (d['contenuto'] ?? d['corpo'] ?? '').toString(),
                'tipo': (d['tipo'] ?? 'servizio').toString(),
                'dataLabel': _formatData(
                  d['dataTs'] ??
                      d['publishedAt'] ??
                      d['timestamp'] ??
                      d['data'],
                ),
                'sortDate': sortDate,
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();

        avvisi.sort((a, b) {
          final ad = a['sortDate'] as DateTime;
          final bd = b['sortDate'] as DateTime;
          return bd.compareTo(ad);
        });

        final latest = avvisi.take(2).toList();
        if (latest.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Nessun avviso disponibile al momento.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          );
        }

        return Column(
          children: latest.map((c) {
            final tipo = c['tipo'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _tipoAvvisoColor(tipo).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _tipoAvvisoIcon(tipo),
                              size: 18,
                              color: _tipoAvvisoColor(tipo),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c['titolo'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _tipoAvvisoColor(tipo).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tipo.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _tipoAvvisoColor(tipo),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c['corpo'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c['dataLabel'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _rifiutoIcon(String tipo, {double size = 24}) {
    IconData icon;
    Color color;
    switch (tipo.toLowerCase()) {
      case 'umido':
        icon = Icons.eco;
        color = Colors.brown;
        break;
      case 'plastica':
        icon = Icons.local_drink;
        color = Colors.orange;
        break;
      case 'carta':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'vetro':
        icon = Icons.wine_bar;
        color = Colors.green;
        break;
      case 'metalli':
        icon = Icons.settings;
        color = Colors.grey;
        break;
      case 'secco residuo':
      case 'secco':
        icon = Icons.delete;
        color = Colors.black54;
        break;
      default:
        icon = Icons.circle;
        color = Colors.teal;
    }
    return Icon(icon, color: color, size: size);
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

  Widget _buildUltimeRichieste(ColorScheme cs) {
    final tenant = Provider.of<Tenant>(context, listen: false);
    return StreamBuilder<QuerySnapshot>(
      stream: TenantRefs.segnalazioniCol(
        tenant.id,
      ).orderBy('timestamp', descending: true).limit(3).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty)
          return const SizedBox.shrink();
        final docs = snap.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ultime segnalazioni',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final stato = d['stato'] as String? ?? '';
              final color = stato == 'Aperta'
                  ? Colors.red[600]!
                  : stato == 'In lavorazione'
                  ? Colors.orange[700]!
                  : Colors.green[700]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['categoria'] as String? ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            d['data'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stato,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSegnalazioniStats(ColorScheme cs) {
    final tenant = Provider.of<Tenant>(context, listen: false);
    return StreamBuilder<QuerySnapshot>(
      stream: TenantRefs.segnalazioniCol(tenant.id).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.hasData
            ? snapshot.data!.docs
            : <QueryDocumentSnapshot>[];
        final aperte = docs
            .where((d) => (d.data() as Map)['stato'] == 'Aperta')
            .length;
        final inLavorazione = docs
            .where((d) => (d.data() as Map)['stato'] == 'In lavorazione')
            .length;
        final risolte = docs
            .where((d) => (d.data() as Map)['stato'] == 'Risolta')
            .length;
        return Row(
          children: [
            _statCard('Totali', '${docs.length}', cs.primary),
            const SizedBox(width: 8),
            _statCard('Aperte', '$aperte', Colors.orange),
            const SizedBox(width: 8),
            _statCard('In corso', '$inLavorazione', Colors.blue),
            const SizedBox(width: 8),
            _statCard('Risolte', '$risolte', Colors.green),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _tipoAvvisoIcon(String tipo) {
    switch (tipo) {
      case 'allerta':
        return Icons.warning_amber;
      case 'evento':
        return Icons.event;
      case 'istituzionale':
        return Icons.account_balance;
      default:
        return Icons.build_circle_outlined;
    }
  }

  Color _tipoAvvisoColor(String tipo) {
    switch (tipo) {
      case 'allerta':
        return Colors.red;
      case 'evento':
        return Colors.green;
      case 'istituzionale':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
