import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/tenant_refs.dart';
import 'segnalazione_detail_screen.dart';
import 'nuova_comunicazione_screen.dart';

/// Schermata principale operatore comunale.
/// Drawer laterale per navigare tra le sezioni, come la dashboard web.
class OperatorHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String comuneId;
  final String comuneName;

  const OperatorHomeScreen({
    required this.onLogout,
    required this.comuneId,
    required this.comuneName,
    super.key,
  });

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  int _selectedSection = 0;

  static const _sections = [
    {'label': 'Dashboard', 'icon': Icons.dashboard},
    {'label': 'Segnalazioni', 'icon': Icons.report_problem},
    {'label': 'Prenotazioni', 'icon': Icons.calendar_today},
    {'label': 'Rifornimento Acqua', 'icon': Icons.water_drop},
    {'label': 'Aziende e Società', 'icon': Icons.business},
    {'label': 'Mezzi e Dipendenti', 'icon': Icons.local_shipping},
    {'label': 'Scadenze', 'icon': Icons.event_note},
    {'label': 'Comunicazioni', 'icon': Icons.campaign},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sections[_selectedSection]['label'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0D3B7A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifiche',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3B7A), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFF0D3B7A),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Operatore Comunale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.comuneName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _sections.length,
              itemBuilder: (ctx, i) {
                final s = _sections[i];
                final selected = _selectedSection == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: ListTile(
                    leading: Icon(
                      s['icon'] as IconData,
                      color: selected
                          ? const Color(0xFF0D3B7A)
                          : Colors.grey[600],
                    ),
                    title: Text(
                      s['label'] as String,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: selected ? const Color(0xFF0D3B7A) : null,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: const Color(0xFFE3F0FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      setState(() => _selectedSection = i);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedSection) {
      case 0:
        return _OperatorDashboardTab(
          comuneId: widget.comuneId,
          onNavigate: (i) {
            setState(() => _selectedSection = i);
          },
        );
      case 1:
        return _SegnalazioniTab(comuneId: widget.comuneId);
      case 2:
        return _PrenotazioniTab(comuneId: widget.comuneId);
      case 3:
        return _CisterneTab(comuneId: widget.comuneId);
      case 4:
        return const _AziendeTab();
      case 5:
        return const _MezziDipendentiTab();
      case 6:
        return const _ScadenzeTab();
      case 7:
        return _ComunicazioniTab(comuneId: widget.comuneId);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────
// COLORI COSTANTI
// ─────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D3B7A);
const _kBg = Color(0xFFF8FAFD);
const _kGreen = Color(0xFF00897B);
const _kOrange = Color(0xFFF57C00);
const _kRed = Color(0xFFE53935);

Color _statoColor(String stato) {
  switch (stato) {
    case 'Aperta':
    case 'In attesa':
      return _kRed;
    case 'In lavorazione':
    case 'Confermata':
    case 'In consegna':
      return _kOrange;
    case 'Risolta':
    case 'Completata':
      return _kGreen;
    default:
      return _kPrimary;
  }
}

IconData _statoIcon(String stato) {
  switch (stato) {
    case 'Aperta':
    case 'In attesa':
      return Icons.hourglass_empty;
    case 'In lavorazione':
    case 'Confermata':
    case 'In consegna':
      return Icons.build;
    case 'Risolta':
    case 'Completata':
      return Icons.check_circle;
    default:
      return Icons.flag;
  }
}

Widget _badge(String text) {
  final color = _statoColor(text);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

/// Formatta un [DateTime] in dd/MM/yyyy.
String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

/// Converte un doc Firestore di segnalazione in mappa compatibile con i widget UI.
Map<String, dynamic> _toSegMap(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final d = doc.data();
  final ts = d['timestamp'] as Timestamp?;
  return {
    ...d,
    '_docId': doc.id,
    'id': '#${doc.id.substring(0, 6).toUpperCase()}',
    'data': ts != null ? _formatDate(ts.toDate()) : '',
  };
}

/// Converte un doc Firestore di prenotazione in mappa compatibile con i widget UI.
Map<String, dynamic> _toPrenotMap(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final d = doc.data();
  return {
    ...d,
    '_docId': doc.id,
    'id': '#${doc.id.substring(0, 6).toUpperCase()}',
    'note': d['note'] as String? ?? '',
  };
}

/// Converte un doc Firestore di cisterna in mappa compatibile con i widget UI.
Map<String, dynamic> _toCisternaMap(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final d = doc.data();
  return {
    ...d,
    '_docId': doc.id,
    'id': '#${doc.id.substring(0, 6).toUpperCase()}',
    'note': d['note'] as String? ?? '',
    'urgente': d['urgente'] as bool? ?? false,
    'numPersone': d['numPersone'] ?? 1,
  };
}

// ─────────────────────────────────────────────────
// 0 – DASHBOARD
// ─────────────────────────────────────────────────
class _OperatorDashboardTab extends StatelessWidget {
  final void Function(int) onNavigate;
  final String comuneId;
  const _OperatorDashboardTab({
    required this.onNavigate,
    required this.comuneId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TenantRefs.segnalazioniCol(
        comuneId,
      ).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapSeg) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: TenantRefs.comunicazioniCol(
            comuneId,
          ).orderBy('dataTs', descending: true).limit(3).snapshots(),
          builder: (context, snapCom) {
            final segnalazioni = (snapSeg.data?.docs ?? [])
                .map(_toSegMap)
                .toList();
            final comunicazioni = (snapCom.data?.docs ?? [])
                .map(
                  (doc) => <String, dynamic>{...doc.data(), '_docId': doc.id},
                )
                .toList();

            final aperte = segnalazioni
                .where((s) => s['stato'] == 'Aperta')
                .length;
            final inLav = segnalazioni
                .where((s) => s['stato'] == 'In lavorazione')
                .length;
            final risolte = segnalazioni
                .where((s) => s['stato'] == 'Risolta')
                .length;

            final stats = [
              _StatData(
                'Segnalazioni',
                '${segnalazioni.length}',
                Icons.flag,
                _kPrimary,
              ),
              _StatData('Aperte', '$aperte', Icons.error_outline, _kRed),
              _StatData('In lavorazione', '$inLav', Icons.build, _kOrange),
              _StatData('Risolte', '$risolte', Icons.check_circle, _kGreen),
            ];

            return Container(
              color: _kBg,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiche
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: stats
                          .map(
                            (s) => SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 52) / 2,
                              child: _StatCard(stat: s),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Accessi rapidi
                    const Text(
                      'Accesso rapido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _QuickAction(
                            icon: Icons.report_problem,
                            label: 'Segnalazioni',
                            onTap: () => onNavigate(1),
                          ),
                          _QuickAction(
                            icon: Icons.calendar_today,
                            label: 'Prenotazioni',
                            onTap: () => onNavigate(2),
                          ),
                          _QuickAction(
                            icon: Icons.water_drop,
                            label: 'Cisterne',
                            onTap: () => onNavigate(3),
                          ),
                          _QuickAction(
                            icon: Icons.business,
                            label: 'Aziende',
                            onTap: () => onNavigate(4),
                          ),
                          _QuickAction(
                            icon: Icons.event_note,
                            label: 'Scadenze',
                            onTap: () => onNavigate(6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ultime segnalazioni
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ultime segnalazioni',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onNavigate(1),
                          child: const Text('Vedi tutte'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (snapSeg.connectionState == ConnectionState.waiting &&
                        !snapSeg.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (segnalazioni.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Nessuna segnalazione',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...segnalazioni
                          .take(3)
                          .map(
                            (s) => _SegnalazioneCard(
                              item: s,
                              onTap: () => onNavigate(1),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // Ultime comunicazioni
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ultime comunicazioni',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onNavigate(7),
                          child: const Text('Vedi tutte'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (snapCom.connectionState == ConnectionState.waiting &&
                        !snapCom.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (comunicazioni.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Nessuna comunicazione',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...comunicazioni.map(
                        (c) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                          child: ListTile(
                            leading: Icon(
                              _tipoComIcon(c['tipo'] as String? ?? ''),
                              color: _kPrimary,
                            ),
                            title: Text(
                              c['titolo'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              c['data'] as String? ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: c['letto'] == false
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: _kRed,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _tipoComIcon(String tipo) {
    switch (tipo) {
      case 'allerta':
        return Icons.warning_amber;
      case 'evento':
        return Icons.celebration;
      case 'servizio':
        return Icons.miscellaneous_services;
      default:
        return Icons.info_outline;
    }
  }
}

class _StatData {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatData(this.title, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 16, color: stat.color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  stat.title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: stat.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _kPrimary, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: _kPrimary),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegnalazioneCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _SegnalazioneCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stato = item['stato'] as String;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: ListTile(
        leading: Icon(_statoIcon(stato), color: _statoColor(stato)),
        title: Text(
          item['categoria'] as String,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${item['posizione']} · ${item['data']}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _badge(stato),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 1 – SEGNALAZIONI
// ─────────────────────────────────────────────────
class _SegnalazioniTab extends StatefulWidget {
  final String comuneId;
  const _SegnalazioniTab({required this.comuneId});
  @override
  State<_SegnalazioniTab> createState() => _SegnalazioniTabState();
}

class _SegnalazioniTabState extends State<_SegnalazioniTab> {
  String _filtroStato = 'Tutte';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TenantRefs.segnalazioniCol(
        widget.comuneId,
      ).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        final items = docs.map(_toSegMap).toList();
        final filtered = _filtroStato == 'Tutte'
            ? items
            : items.where((s) => s['stato'] == _filtroStato).toList();

        return Container(
          color: _kBg,
          child: Column(
            children: [
              // Filtri
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Tutte', 'Aperta', 'In lavorazione', 'Risolta']
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                              selected: _filtroStato == s,
                              selectedColor: _kPrimary.withOpacity(0.15),
                              onSelected: (_) =>
                                  setState(() => _filtroStato = s),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessuna segnalazione',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final s = filtered[i];
                          final docId = s['_docId'] as String;
                          return _SegnalazioneDetailCard(
                            item: s,
                            onCambiaStato: (nuovoStato) {
                              TenantRefs.segnalazioniCol(
                                widget.comuneId,
                              ).doc(docId).update({'stato': nuovoStato});
                            },
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SegnalazioneDetailScreen(item: s),
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
  }
}

class _SegnalazioneDetailCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(String) onCambiaStato;
  final VoidCallback? onTap;
  const _SegnalazioneDetailCard({
    required this.item,
    required this.onCambiaStato,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stato = item['stato'] as String;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statoIcon(stato), color: _statoColor(stato), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item['id']} – ${item['categoria']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _badge(stato),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item['descrizione'] as String,
                style: const TextStyle(fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    item['posizione'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item['data'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (item['anonima'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Segnalazione anonima',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Azioni rapide + Apri dettaglio
              Row(
                children: [
                  if (stato == 'Aperta')
                    _ActionBtn(
                      label: 'Prendi in carico',
                      color: _kOrange,
                      icon: Icons.build,
                      onTap: () => onCambiaStato('In lavorazione'),
                    ),
                  if (stato == 'Aperta' || stato == 'In lavorazione')
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _ActionBtn(
                        label: 'Risolta',
                        color: _kGreen,
                        icon: Icons.check_circle,
                        onTap: () => onCambiaStato('Risolta'),
                      ),
                    ),
                  if (stato == 'Risolta')
                    _ActionBtn(
                      label: 'Riapri',
                      color: _kRed,
                      icon: Icons.refresh,
                      onTap: () => onCambiaStato('Aperta'),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text(
                      'Dettaglio',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(foregroundColor: _kPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 2 – PRENOTAZIONI
// ─────────────────────────────────────────────────
class _PrenotazioniTab extends StatefulWidget {
  final String comuneId;
  const _PrenotazioniTab({required this.comuneId});
  @override
  State<_PrenotazioniTab> createState() => _PrenotazioniTabState();
}

class _PrenotazioniTabState extends State<_PrenotazioniTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TenantRefs.prenotazioniCol(
        widget.comuneId,
      ).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = (snapshot.data?.docs ?? []).map(_toPrenotMap).toList();
        return Container(
          color: _kBg,
          child: items.isEmpty
              ? const Center(child: Text('Nessuna prenotazione'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final p = items[i];
                    final docId = p['_docId'] as String;
                    final stato = p['stato'] as String? ?? 'In attesa';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showPrenotazioneDetail(context, p, docId),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: _kPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${p['id']} – Ritiro ${p['tipo'] ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  _badge(stato),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                Icons.location_on,
                                p['indirizzo'] as String? ?? '',
                              ),
                              _infoRow(
                                Icons.calendar_today,
                                p['data'] as String? ?? '',
                              ),
                              if ((p['note'] as String).isNotEmpty)
                                _infoRow(Icons.note, p['note'] as String),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (stato != 'Completata' &&
                                      stato != 'Annullata')
                                    _ActionBtn(
                                      label: 'Completata',
                                      color: _kGreen,
                                      icon: Icons.check,
                                      onTap: () =>
                                          TenantRefs.prenotazioniCol(
                                            widget.comuneId,
                                          ).doc(docId).update({
                                            'stato': 'Completata',
                                          }),
                                    ),
                                  if (stato == 'Confermata')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: _ActionBtn(
                                        label: 'Annulla',
                                        color: _kRed,
                                        icon: Icons.cancel,
                                        onTap: () =>
                                            TenantRefs.prenotazioniCol(
                                              widget.comuneId,
                                            ).doc(docId).update({
                                              'stato': 'Annullata',
                                            }),
                                      ),
                                    ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _showPrenotazioneDetail(
                                      context,
                                      p,
                                      docId,
                                    ),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Dettaglio',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showPrenotazioneDetail(
    BuildContext ctx,
    Map<String, dynamic> p,
    String docId,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx2, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.delete_outline, color: _kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p['id']} – Ritiro ${p['tipo'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _badge(p['stato'] as String? ?? 'In attesa'),
              const Divider(height: 24),
              _infoRow(Icons.location_on, p['indirizzo'] as String? ?? ''),
              _infoRow(Icons.calendar_today, p['data'] as String? ?? ''),
              _infoRow(Icons.category, 'Tipo: ${p['tipo'] ?? ''}'),
              if ((p['note'] as String).isNotEmpty)
                _infoRow(Icons.note, 'Note: ${p['note']}'),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (p['stato'] != 'Completata' && p['stato'] != 'Annullata')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          TenantRefs.prenotazioniCol(
                            widget.comuneId,
                          ).doc(docId).update({'stato': 'Completata'});
                          Navigator.pop(ctx2);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Segna completata'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _infoRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────
// 3 – CISTERNE ACQUA
// ─────────────────────────────────────────────────
class _CisterneTab extends StatefulWidget {
  final String comuneId;
  const _CisterneTab({required this.comuneId});
  @override
  State<_CisterneTab> createState() => _CisterneTabState();
}

class _CisterneTabState extends State<_CisterneTab> {
  static const _workflow = {
    'In attesa': 'Confermata',
    'Confermata': 'In consegna',
    'In consegna': 'Completata',
  };

  void _avanza(String docId, String statoAttuale) {
    final next = _workflow[statoAttuale];
    if (next != null) {
      TenantRefs.cisterneCol(
        widget.comuneId,
      ).doc(docId).update({'stato': next});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TenantRefs.cisterneCol(
        widget.comuneId,
      ).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = (snapshot.data?.docs ?? []).map(_toCisternaMap).toList();
        return Container(
          color: _kBg,
          child: items.isEmpty
              ? const Center(child: Text('Nessuna richiesta'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final c = items[i];
                    final docId = c['_docId'] as String;
                    final stato = c['stato'] as String? ?? 'In attesa';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showCisternaDetail(context, c, docId),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.water_drop,
                                    color: Color(0xFF0288D1),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${c['id']} – ${c['motivazione'] ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  _badge(stato),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                Icons.location_on,
                                c['indirizzo'] as String? ?? '',
                              ),
                              _infoRow(
                                Icons.phone,
                                c['telefono'] as String? ?? '',
                              ),
                              _infoRow(
                                Icons.people,
                                '${c['numPersone']} persone nel nucleo',
                              ),
                              if (c['urgente'] == true)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.priority_high,
                                        size: 16,
                                        color: _kRed,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'URGENTE',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _kRed,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if ((c['note'] as String).isNotEmpty)
                                _infoRow(Icons.note, c['note'] as String),
                              _infoRow(
                                Icons.calendar_today,
                                c['data'] as String? ?? '',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (stato == 'In attesa')
                                    _ActionBtn(
                                      label: 'Conferma',
                                      color: _kOrange,
                                      icon: Icons.check,
                                      onTap: () => _avanza(docId, stato),
                                    ),
                                  if (stato == 'Confermata')
                                    _ActionBtn(
                                      label: 'In consegna',
                                      color: const Color(0xFF0288D1),
                                      icon: Icons.local_shipping,
                                      onTap: () => _avanza(docId, stato),
                                    ),
                                  if (stato == 'In consegna')
                                    _ActionBtn(
                                      label: 'Completata',
                                      color: _kGreen,
                                      icon: Icons.check_circle,
                                      onTap: () => _avanza(docId, stato),
                                    ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showCisternaDetail(context, c, docId),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Dettaglio',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showCisternaDetail(
    BuildContext ctx,
    Map<String, dynamic> c,
    String docId,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx2, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Color(0xFF0288D1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${c['id']} – ${c['motivazione'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _badge(c['stato'] as String? ?? 'In attesa'),
                  if (c['urgente'] == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'URGENTE',
                        style: TextStyle(
                          fontSize: 11,
                          color: _kRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 24),
              _infoRow(Icons.location_on, c['indirizzo'] as String? ?? ''),
              _infoRow(Icons.phone, c['telefono'] as String? ?? ''),
              _infoRow(
                Icons.people,
                '${c['numPersone']} persone nel nucleo familiare',
              ),
              _infoRow(Icons.calendar_today, 'Data: ${c['data'] ?? ''}'),
              _infoRow(Icons.comment, c['motivazione'] as String? ?? ''),
              if ((c['note'] as String).isNotEmpty)
                _infoRow(Icons.note, 'Note: ${c['note']}'),
              const SizedBox(height: 20),
              // Workflow completo
              const Text(
                'Avanzamento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _WorkflowStep(
                label: 'In attesa',
                done:
                    [
                      'In attesa',
                      'Confermata',
                      'In consegna',
                      'Completata',
                    ].indexOf(c['stato'] as String? ?? '') >=
                    0,
              ),
              _WorkflowStep(
                label: 'Confermata',
                done: [
                  'Confermata',
                  'In consegna',
                  'Completata',
                ].contains(c['stato']),
              ),
              _WorkflowStep(
                label: 'In consegna',
                done: ['In consegna', 'Completata'].contains(c['stato']),
              ),
              _WorkflowStep(
                label: 'Completata',
                done: c['stato'] == 'Completata',
              ),
              const SizedBox(height: 20),
              if (c['stato'] != 'Completata')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _avanza(docId, c['stato'] as String? ?? '');
                      Navigator.pop(ctx2);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      'Avanza a: ${_workflow[c['stato'] as String? ?? ''] ?? ''}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final String label;
  final bool done;
  const _WorkflowStep({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: done ? _kGreen : Colors.grey[300],
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
              color: done ? _kGreen : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 4 – AZIENDE E SOCIETÀ
// ─────────────────────────────────────────────────
class _AziendeTab extends StatelessWidget {
  const _AziendeTab();

  static const _aziende = [
    {
      'nome': 'EcoService S.r.l.',
      'settore': 'Nettezza urbana',
      'piva': '01234567890',
      'telefono': '0963 123456',
      'costoMensile': '€ 12.500',
      'costoAnnuo': '€ 150.000',
      'dipendenti': '3',
      'scadenza': '30/06/2027',
    },
    {
      'nome': 'AcquaSud S.p.A.',
      'settore': 'Servizio idrico',
      'piva': '09876543210',
      'telefono': '0963 654321',
      'costoMensile': '€ 8.200',
      'costoAnnuo': '€ 98.400',
      'dipendenti': '2',
      'scadenza': '31/12/2028',
    },
    {
      'nome': 'Enel Energia',
      'settore': 'Servizio elettrico',
      'piva': '00811720580',
      'telefono': '800 900800',
      'costoMensile': '€ 4.800',
      'costoAnnuo': '€ 57.600',
      'dipendenti': '1',
      'scadenza': '31/03/2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _aziende.length,
        itemBuilder: (ctx, i) {
          final a = _aziende[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: _kPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a['nome']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      a['settore']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(Icons.badge, 'P.IVA: ${a['piva']}'),
                  _infoRow(Icons.phone, a['telefono']!),
                  _infoRow(Icons.people, '${a['dipendenti']} dipendenti'),
                  _infoRow(Icons.event, 'Scadenza: ${a['scadenza']}'),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Mensile',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              a['costoMensile']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Annuo',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              a['costoAnnuo']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 5 – MEZZI E DIPENDENTI COMUNALI
// ─────────────────────────────────────────────────
class _MezziDipendentiTab extends StatefulWidget {
  const _MezziDipendentiTab();
  @override
  State<_MezziDipendentiTab> createState() => _MezziDipendentiTabState();
}

class _MezziDipendentiTabState extends State<_MezziDipendentiTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  static const _mezzi = [
    {
      'targa': 'FG 123 AB',
      'tipo': 'Autocarro',
      'modello': 'Iveco Daily 35S14',
      'assegnato': 'Ufficio tecnico',
      'stato': 'Operativo',
    },
    {
      'targa': 'FG 456 CD',
      'tipo': 'Autovettura',
      'modello': 'Fiat Panda 4x4',
      'assegnato': 'Vigili urbani',
      'stato': 'Operativo',
    },
    {
      'targa': 'FG 789 EF',
      'tipo': 'Furgone',
      'modello': 'Renault Kangoo',
      'assegnato': 'Servizi sociali',
      'stato': 'In manutenzione',
    },
    {
      'targa': 'FG 321 GH',
      'tipo': 'Mezzo speciale',
      'modello': 'Piaggio Ape 50',
      'assegnato': 'Manutenzione strade',
      'stato': 'Operativo',
    },
    {
      'targa': 'FG 654 IL',
      'tipo': 'Autocarro',
      'modello': 'FIAT Ducato',
      'assegnato': 'Protezione civile',
      'stato': 'Fuori servizio',
    },
  ];

  static const _dipendenti = [
    {
      'nome': 'Antonio Ferraro',
      'categoria': 'Tecnico',
      'ufficio': 'Ufficio tecnico',
      'telefono': '0963 111222',
    },
    {
      'nome': 'Maria Calabrò',
      'categoria': 'Amministrativo',
      'ufficio': 'Anagrafe',
      'telefono': '0963 333444',
    },
    {
      'nome': 'Giuseppe Sergi',
      'categoria': 'Vigili urbani',
      'ufficio': 'Polizia Locale',
      'telefono': '0963 555666',
    },
    {
      'nome': 'Rosa Nesci',
      'categoria': 'Amministrativo',
      'ufficio': 'Ufficio tributi',
      'telefono': '0963 777888',
    },
    {
      'nome': 'Salvatore Piro',
      'categoria': 'Operaio',
      'ufficio': 'Manutenzione strade',
      'telefono': '334 9876543',
    },
  ];

  Color _mezzoStatoColor(String stato) {
    if (stato == 'Operativo') return _kGreen;
    if (stato == 'In manutenzione') return _kOrange;
    return _kRed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: _kPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _kPrimary,
            tabs: const [
              Tab(text: '🚛 Mezzi', icon: null),
              Tab(text: '👷 Dipendenti', icon: null),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // Tab mezzi
              Container(
                color: _kBg,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mezzi.length,
                  itemBuilder: (ctx, i) {
                    final m = _mezzi[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: ListTile(
                        leading: Icon(
                          Icons.local_shipping,
                          color: _mezzoStatoColor(m['stato']!),
                        ),
                        title: Text(
                          '${m['targa']} – ${m['modello']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${m['tipo']} · ${m['assegnato']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: _badge(m['stato']!),
                      ),
                    );
                  },
                ),
              ),
              // Tab dipendenti
              Container(
                color: _kBg,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dipendenti.length,
                  itemBuilder: (ctx, i) {
                    final d = _dipendenti[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _kPrimary.withOpacity(0.1),
                          child: Text(
                            d['nome']!.split(' ').map((n) => n[0]).join(),
                            style: const TextStyle(
                              color: _kPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          d['nome']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${d['categoria']} · ${d['ufficio']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          d['telefono']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// 6 – SCADENZE
// ─────────────────────────────────────────────────
class _ScadenzeTab extends StatelessWidget {
  const _ScadenzeTab();

  static const _scadenze = [
    {
      'desc': 'Bando raccolta rifiuti 2024-2027',
      'cat': 'Bando',
      'fornitore': 'EcoService S.r.l.',
      'data': '30/06/2027',
      'costo': '€ 150.000/anno',
    },
    {
      'desc': 'Utenza illuminazione pubblica',
      'cat': 'Utenza luce',
      'fornitore': 'Enel Energia',
      'data': '31/03/2026',
      'costo': '€ 57.600/anno',
    },
    {
      'desc': 'Utenza gas – riscaldamento uffici',
      'cat': 'Utenza gas',
      'fornitore': 'Eni Plenitude',
      'data': '15/08/2025',
      'costo': '€ 14.400/anno',
    },
    {
      'desc': 'Assicurazione RCA parco mezzi',
      'cat': 'Assicurazione',
      'fornitore': 'UnipolSai',
      'data': '20/07/2025',
      'costo': '€ 10.200/anno',
    },
    {
      'desc': 'Contratto manutenzione strade',
      'cat': 'Contratto',
      'fornitore': 'Strade Sicure S.r.l.',
      'data': '31/12/2025',
      'costo': '€ 42.000/anno',
    },
    {
      'desc': 'Bando servizio idrico integrato',
      'cat': 'Bando',
      'fornitore': 'AcquaSud S.p.A.',
      'data': '31/12/2028',
      'costo': '€ 98.400/anno',
    },
  ];

  Color _catColor(String cat) {
    if (cat.contains('Bando')) return _kPrimary;
    if (cat.contains('luce') || cat.contains('gas')) return _kOrange;
    if (cat.contains('Assicurazione')) return _kRed;
    return const Color(0xFF6A1B9A);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scadenze.length,
        itemBuilder: (ctx, i) {
          final s = _scadenze[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_note,
                        color: _catColor(s['cat']!),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s['desc']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _catColor(s['cat']!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s['cat']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _catColor(s['cat']!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(Icons.business, s['fornitore']!),
                  _infoRow(Icons.calendar_today, 'Scadenza: ${s['data']}'),
                  _infoRow(Icons.euro, s['costo']!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 7 – COMUNICAZIONI
// ─────────────────────────────────────────────────
class _ComunicazioniTab extends StatelessWidget {
  final String comuneId;
  const _ComunicazioniTab({required this.comuneId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TenantRefs.comunicazioniCol(
        comuneId,
      ).orderBy('dataTs', descending: true).snapshots(),
      builder: (context, snapshot) {
        final items = (snapshot.data?.docs ?? [])
            .map((doc) => <String, dynamic>{...doc.data(), '_docId': doc.id})
            .toList();

        return Scaffold(
          backgroundColor: _kBg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NuovaComunicazioneScreen(comuneId: comuneId),
              ),
            ),
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nuova'),
          ),
          body:
              snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final c = items[i];
                    final docId = c['_docId'] as String;
                    final letto = c['letto'] as bool? ?? false;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: letto ? 1 : 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (!letto) {
                            TenantRefs.comunicazioniCol(
                              comuneId,
                            ).doc(docId).update({'letto': true});
                          }
                          _showComunicazione(context, c);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _tipoIcon(c['tipo'] as String? ?? ''),
                                color: _kPrimary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c['titolo'] as String? ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: letto
                                                  ? FontWeight.w400
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (!letto)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: _kRed,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['corpo'] as String? ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c['data'] as String? ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'allerta':
        return Icons.warning_amber;
      case 'evento':
        return Icons.celebration;
      case 'servizio':
        return Icons.miscellaneous_services;
      default:
        return Icons.info_outline;
    }
  }

  void _showComunicazione(BuildContext context, Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(_tipoIcon(c['tipo'] as String? ?? ''), color: _kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c['titolo'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                c['data'] as String? ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const Divider(height: 24),
              Text(
                c['corpo'] as String? ?? '',
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
