import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/tenant.dart';
import '../../core/services/mock_data.dart';

class ComunicazioniScreen extends StatefulWidget {
  const ComunicazioniScreen({Key? key}) : super(key: key);

  @override
  State<ComunicazioniScreen> createState() => _ComunicazioniScreenState();
}

class _ComunicazioniScreenState extends State<ComunicazioniScreen> {
  String? _zonaSelezionata;
  final Set<String> _lettiIds = {};

  List<String> _zonePerComune(String comuneNome, List<String> daFirestore) {
    if (daFirestore.isNotEmpty) return daFirestore;
    return MockData.comuni[comuneNome] ?? [];
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

  DateTime _extractSortDate(Map<String, dynamic> raw) {
    return _asDateTime(
      raw['dataTs'] ??
          raw['publishedAt'] ??
          raw['timestamp'] ??
          raw['updatedAt'] ??
          raw['data'],
    );
  }

  String _formatData(dynamic value) {
    final dt = _asDateTime(value);
    if (dt.millisecondsSinceEpoch == 0) return '';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd/$mm/$yyyy';
  }

  void _segnaLetto(String id) {
    setState(() => _lettiIds.add(id));
  }

  void _mostraDettaglio(Map<String, dynamic> comunicazione) {
    _segnaLetto(comunicazione['id'] as String);
    final frazioni = comunicazione['frazioni'] as List<String>? ?? [];
    final zona = comunicazione['zona'] as String? ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(comunicazione['titolo'] ?? 'Dettaglio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(comunicazione['corpo'] ?? ''),
              if (frazioni.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Destinatari:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: frazioni
                      .map((f) => Chip(label: Text(f, style: const TextStyle(fontSize: 12))))
                      .toList(),
                ),
              ] else if (zona.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Zona: $zona', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'servizio':
        return Icons.build;
      case 'allerta':
        return Icons.warning_amber;
      case 'evento':
        return Icons.celebration;
      case 'istituzionale':
        return Icons.account_balance;
      default:
        return Icons.notifications;
    }
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'servizio':
        return const Color(0xFFF57C00);
      case 'allerta':
        return const Color(0xFFE53935);
      case 'evento':
        return const Color(0xFF7B1FA2);
      case 'istituzionale':
        return const Color(0xFF0D3B7A);
      default:
        return Colors.grey;
    }
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'servizio':
        return 'Servizio';
      case 'allerta':
        return 'Allerta';
      case 'evento':
        return 'Evento';
      case 'istituzionale':
        return 'Istituzionale';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = Provider.of<Tenant>(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('comuni').doc(tenant.id).snapshots(),
      builder: (context, comuneSnapshot) {
        final comuneData = comuneSnapshot.data?.data() as Map<String, dynamic>?;
        final frazioniDaFirestore = (comuneData?['frazioni'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList() ??
            <String>[];
        final zoneDisponibili = _zonePerComune(tenant.name, frazioniDaFirestore);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('comuni')
              .doc(tenant.id)
              .collection('comunicazioni')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento comunicazioni',
                  style: TextStyle(color: Colors.red[700]),
                ),
              );
            }

            List<Map<String, dynamic>> _comunicazioni = [];
            if (snapshot.hasData) {
              _comunicazioni = snapshot.data!.docs
                  .map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final stato = (d['stato'] ?? 'attivo').toString().toLowerCase();
                    if (stato != 'attivo') return null;
                    final frazioni = (d['frazioni'] as List<dynamic>?)
                            ?.map((e) => e.toString().trim())
                            .where((e) => e.isNotEmpty)
                            .toList() ??
                        <String>[];
                    final sortDate = _extractSortDate(d);
                    return <String, dynamic>{
                      'id': doc.id,
                      'titolo': d['titolo'] ?? '',
                      'corpo': d['contenuto'] ?? d['corpo'] ?? '',
                      'dataLabel': _formatData(
                        d['dataTs'] ?? d['publishedAt'] ?? d['timestamp'] ?? d['data'],
                      ),
                      'sortDate': sortDate,
                      'tipo': d['tipo'] ?? 'servizio',
                      'zona': d['zona'] ?? '',
                      'frazioni': frazioni,
                      'priorita': d['priorita'] ?? 'normale',
                      'letto': _lettiIds.contains(doc.id),
                    };
                  })
                  .whereType<Map<String, dynamic>>()
                  .toList();

              _comunicazioni.sort((a, b) {
                final ad = a['sortDate'] as DateTime;
                final bd = b['sortDate'] as DateTime;
                return bd.compareTo(ad);
              });
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final horizontalPadding = isWide
                    ? constraints.maxWidth * 0.18
                    : 0.0;
                final nonLetti = _comunicazioni
                    .where((c) => c['letto'] == false)
                    .length;
                final zonaSelezionataNorm = (_zonaSelezionata ?? '').trim().toLowerCase();
                final comunicazioniFiltrate = _zonaSelezionata == null
                    ? _comunicazioni
                    : _comunicazioni
                        .where((c) {
                          final frazioni = (c['frazioni'] as List<String>)
                              .map((e) => e.trim().toLowerCase())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (frazioni.isEmpty) return true; // indirizzata a tutti
                          return frazioni.contains(zonaSelezionataNorm);
                        })
                        .toList();

            return Container(
              color: const Color(0xFFF8FAFD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 + horizontalPadding,
                      16,
                      16 + horizontalPadding,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Comunicazioni',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (nonLetti > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$nonLetti nuov${nonLetti == 1 ? 'a' : 'e'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 + horizontalPadding,
                      4,
                      16 + horizontalPadding,
                      12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Comunicazioni ufficiali dal Comune',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _zonaSelezionata,
                          hint: const Text('Zona'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Tutte le zone'),
                            ),
                            ...zoneDisponibili.map(
                              (z) => DropdownMenuItem(value: z, child: Text(z)),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _zonaSelezionata = v;
                            });
                          },
                          underline: Container(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: comunicazioniFiltrate.isEmpty
                        ? Center(
                            child: Text(
                              'Nessuna comunicazione per questa zona.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 + horizontalPadding,
                            ),
                            itemCount: comunicazioniFiltrate.length,
                            itemBuilder: (context, index) {
                              final c = comunicazioniFiltrate[index];
                              final letto = c['letto'] as bool;
                              final tipo = c['tipo'] as String;
                              final color = _tipoColor(tipo);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: letto
                                      ? BorderSide.none
                                      : BorderSide(
                                          color: color.withOpacity(0.4),
                                        ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    _mostraDettaglio(c);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _tipoIcon(tipo),
                                                color: color,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c['titolo'],
                                                    style: TextStyle(
                                                      fontWeight: letto
                                                          ? FontWeight.w500
                                                          : FontWeight.w700,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 1,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: color
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          _tipoLabel(tipo),
                                                          style: TextStyle(
                                                            color: color,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        c['dataLabel'],
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[500],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!letto)
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          c['corpo'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
            );
          },
        );
      },
    );
  }
}
