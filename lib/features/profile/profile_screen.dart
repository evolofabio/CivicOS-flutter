import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/models/tenant.dart';
import '../../core/models/citizen_data.dart';
import '../../core/services/tenant_refs.dart';

class ProfileScreen extends StatefulWidget {
  final Tenant tenant;
  final bool seniorMode;
  final Function(bool) onToggleSenior;
  final VoidCallback onLogout;

  const ProfileScreen({
    required this.tenant,
    this.seniorMode = false,
    required this.onToggleSenior,
    required this.onLogout,
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Editing state ──
  bool _editingAnagrafica = false;
  bool _editingResidenza = false;

  // ── Anagrafica controllers ──
  late TextEditingController _nomeCtrl;
  late TextEditingController _cognomeCtrl;
  late TextEditingController _dataNascitaCtrl;
  late TextEditingController _cfCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;

  // ── Residenza controllers ──
  late TextEditingController _indirizzoCtrl;
  late TextEditingController _civicoCtrl;
  late TextEditingController _capCtrl;
  late TextEditingController _provinciaCtrl;

  @override
  void initState() {
    super.initState();
    final cd = context.read<CitizenData>();
    _nomeCtrl = TextEditingController(text: cd.nome);
    _cognomeCtrl = TextEditingController(text: cd.cognome);
    _dataNascitaCtrl = TextEditingController(text: cd.dataNascita);
    _cfCtrl = TextEditingController(text: cd.codiceFiscale);
    _telefonoCtrl = TextEditingController(text: cd.telefono);
    _emailCtrl = TextEditingController(text: cd.email);
    _indirizzoCtrl = TextEditingController(text: cd.indirizzo);
    _civicoCtrl = TextEditingController(text: cd.civico);
    _capCtrl = TextEditingController(text: cd.cap);
    _provinciaCtrl = TextEditingController(text: cd.provincia);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cognomeCtrl.dispose();
    _dataNascitaCtrl.dispose();
    _cfCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _indirizzoCtrl.dispose();
    _civicoCtrl.dispose();
    _capCtrl.dispose();
    _provinciaCtrl.dispose();
    super.dispose();
  }

  void _syncFromModel() {
    final cd = context.read<CitizenData>();
    _nomeCtrl.text = cd.nome;
    _cognomeCtrl.text = cd.cognome;
    _dataNascitaCtrl.text = cd.dataNascita;
    _cfCtrl.text = cd.codiceFiscale;
    _telefonoCtrl.text = cd.telefono;
    _emailCtrl.text = cd.email;
    _indirizzoCtrl.text = cd.indirizzo;
    _civicoCtrl.text = cd.civico;
    _capCtrl.text = cd.cap;
    _provinciaCtrl.text = cd.provincia;
  }

  Future<void> _persistProfileToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final cd = context.read<CitizenData>();
    await TenantRefs.saveProfile(
      comuneId: widget.tenant.id,
      uid: uid,
      data: {
        'nome': cd.nome,
        'cognome': cd.cognome,
        'dataNascita': cd.dataNascita,
        'codiceFiscale': cd.codiceFiscale,
        'telefono': cd.telefono,
        'email': cd.email,
        'indirizzo': cd.indirizzo,
        'civico': cd.civico,
        'cap': cd.cap,
        'provincia': cd.provincia,
        'residenza': {
          'indirizzo': cd.indirizzo,
          'civico': cd.civico,
          'cap': cd.cap,
          'provincia': cd.provincia,
        },
        'abitazioni': cd.abitazioni.map((a) => a.toMap()).toList(),
      },
    );
  }

  Future<void> _saveAnagrafica() async {
    context.read<CitizenData>().updateAnagrafica(
      nome: _nomeCtrl.text.trim(),
      cognome: _cognomeCtrl.text.trim(),
      dataNascita: _dataNascitaCtrl.text.trim(),
      codiceFiscale: _cfCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    try {
      await _persistProfileToFirestore();
    } catch (e) {
      debugPrint('[ProfileScreen] _saveAnagrafica persist error: $e');
    }

    setState(() => _editingAnagrafica = false);
    _showSaved();
  }

  Future<void> _saveResidenza() async {
    context.read<CitizenData>().updateResidenza(
      indirizzo: _indirizzoCtrl.text.trim(),
      civico: _civicoCtrl.text.trim(),
      cap: _capCtrl.text.trim(),
      provincia: _provinciaCtrl.text.trim(),
    );

    try {
      await _persistProfileToFirestore();
    } catch (e) {
      debugPrint('[ProfileScreen] _saveResidenza persist error: $e');
    }

    setState(() => _editingResidenza = false);
    _showSaved();
  }

  void _openAbitazioneDialog({Abitazione? existing, int? index}) {
    final superficieCtrl = TextEditingController(
      text: existing?.superficie ?? '',
    );
    final renditaCtrl = TextEditingController(
      text: existing?.renditaCatastale ?? '',
    );
    final categoriaCtrl = TextEditingController(
      text: existing?.categoriaCatastale ?? '',
    );
    final nucleoCtrl = TextEditingController(
      text: existing?.nucleoFamiliare ?? '',
    );
    String titolarita = existing?.titolarita ?? '';
    String tipoImmobile = existing?.tipoImmobile ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 16),
                    Text(
                      index != null
                          ? 'Modifica abitazione'
                          : 'Nuova abitazione',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Titolarità dropdown
                    Text(
                      'Titolarità',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _dropdownField(
                      value: titolarita.isEmpty ? null : titolarita,
                      items: const [
                        'Proprietario',
                        'Affittuario',
                        'Comodato d\'uso',
                        'Usufrutto',
                        'Altro',
                      ],
                      hint: 'Seleziona titolarità',
                      onChanged: (v) =>
                          setModalState(() => titolarita = v ?? ''),
                    ),
                    const SizedBox(height: 14),
                    // Tipo immobile dropdown
                    Text(
                      'Tipo immobile',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _dropdownField(
                      value: tipoImmobile.isEmpty ? null : tipoImmobile,
                      items: const [
                        'Abitazione principale',
                        'Seconda casa',
                        'Immobile commerciale',
                        'Terreno',
                        'Altro',
                      ],
                      hint: 'Seleziona tipo',
                      onChanged: (v) =>
                          setModalState(() => tipoImmobile = v ?? ''),
                    ),
                    const SizedBox(height: 14),
                    _editField(
                      'Superficie (es. 95 mq)',
                      superficieCtrl,
                      Icons.square_foot,
                    ),
                    _editField(
                      'Rendita catastale (es. € 520,00)',
                      renditaCtrl,
                      Icons.euro,
                    ),
                    _editField(
                      'Categoria catastale (es. A/3)',
                      categoriaCtrl,
                      Icons.category,
                    ),
                    _editField(
                      'Nucleo familiare (es. 3 componenti)',
                      nucleoCtrl,
                      Icons.family_restroom,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final ab = Abitazione(
                                titolarita: titolarita,
                                tipoImmobile: tipoImmobile,
                                superficie: superficieCtrl.text.trim(),
                                renditaCatastale: renditaCtrl.text.trim(),
                                categoriaCatastale: categoriaCtrl.text.trim(),
                                nucleoFamiliare: nucleoCtrl.text.trim(),
                              );
                              final cd = context.read<CitizenData>();
                              if (index != null) {
                                cd.updateAbitazione(index, ab);
                              } else {
                                cd.addAbitazione(ab);
                              }
                              try {
                                await _persistProfileToFirestore();
                              } catch (e) {
                                debugPrint(
                                  '[ProfileScreen] addAbitazione persist error: $e',
                                );
                              }
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              _showSaved();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00897B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Salva'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      superficieCtrl.dispose();
      renditaCtrl.dispose();
      categoriaCtrl.dispose();
      nucleoCtrl.dispose();
    });
  }

  void _confirmDeleteAbitazione(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina abitazione'),
        content: const Text('Vuoi davvero eliminare questa abitazione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              context.read<CitizenData>().removeAbitazione(index);
              try {
                await _persistProfileToFirestore();
              } catch (e) {
                debugPrint(
                  '[ProfileScreen] deleteAbitazione persist error: $e',
                );
              }
              if (!mounted) return;
              Navigator.pop(ctx);
              _showSaved();
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dati salvati con successo'),
        backgroundColor: Color(0xFF00897B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cd = context.watch<CitizenData>();

    return Container(
      color: const Color(0xFFF8FAFD),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Profilo ──
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: const Color(0xFF0D3B7A),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        cd.nome.isNotEmpty ? cd.nome[0] : widget.tenant.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cd.nome.isNotEmpty
                                ? '${cd.nome} ${cd.cognome}'
                                : widget.tenant.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cd.email.isNotEmpty
                                ? cd.email
                                : 'ID: ${widget.tenant.id}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ═══════════════════════════════════
            // ── SEZIONE ANAGRAFICA ──
            // ═══════════════════════════════════
            _buildSectionHeader(
              title: 'Anagrafica',
              editing: _editingAnagrafica,
              isEmpty: !cd.hasAnagrafica,
              onEdit: () {
                _syncFromModel();
                setState(() => _editingAnagrafica = true);
              },
              onCancel: () {
                _syncFromModel();
                setState(() => _editingAnagrafica = false);
              },
              onSave: _saveAnagrafica,
            ),
            const SizedBox(height: 8),
            _editingAnagrafica
                ? _buildAnagraficaEdit()
                : _buildAnagraficaView(cd),
            const SizedBox(height: 20),

            // ═══════════════════════════════════
            // ── SEZIONE RESIDENZA ──
            // ═══════════════════════════════════
            _buildSectionHeader(
              title: 'Indirizzo di Residenza',
              editing: _editingResidenza,
              isEmpty: cd.indirizzo.isEmpty,
              onEdit: () {
                _syncFromModel();
                setState(() => _editingResidenza = true);
              },
              onCancel: () {
                _syncFromModel();
                setState(() => _editingResidenza = false);
              },
              onSave: _saveResidenza,
            ),
            const SizedBox(height: 8),
            _editingResidenza
                ? _buildResidenzaEdit()
                : _buildResidenzaView(cd, cs, []),
            const SizedBox(height: 20),

            // ═══════════════════════════════════
            // ── ABITAZIONI ──
            // ═══════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Abitazioni',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => _openAbitazioneDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cd.abitazioni.isEmpty)
              _EmptySection(
                icon: Icons.house,
                message:
                    'Nessuna abitazione inserita.\nTocca "Aggiungi" per inserire i dati di un\'abitazione.',
              )
            else
              ...cd.abitazioni.asMap().entries.map((entry) {
                final i = entry.key;
                final ab = entry.value;
                return _buildAbitazioneCard(ab, i);
              }),
            const SizedBox(height: 20),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // ── SECTION HEADER (with edit/save/cancel) ──
  // ════════════════════════════════════════════
  Widget _buildSectionHeader({
    required String title,
    required bool editing,
    required bool isEmpty,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (editing)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text(
                  'Annulla',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Salva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          )
        else
          TextButton.icon(
            onPressed: onEdit,
            icon: Icon(isEmpty ? Icons.add : Icons.edit, size: 18),
            label: Text(isEmpty ? 'Aggiungi' : 'Modifica'),
          ),
      ],
    );
  }

  // ════════════════════════════════
  // ──  ANAGRAFICA VIEW / EDIT  ──
  // ════════════════════════════════
  Widget _buildAnagraficaView(CitizenData cd) {
    if (!cd.hasAnagrafica) {
      return _EmptySection(
        icon: Icons.person_add,
        message:
            'Nessun dato anagrafico inserito.\n'
            'Tocca "Aggiungi" per compilare i tuoi dati personali.',
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(label: 'Nome', value: cd.nome, icon: Icons.person),
            const Divider(height: 24),
            _InfoRow(
              label: 'Cognome',
              value: cd.cognome,
              icon: Icons.person_outline,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Data di nascita',
              value: cd.dataNascita,
              icon: Icons.cake,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Codice Fiscale',
              value: cd.codiceFiscale,
              icon: Icons.badge,
            ),
            const Divider(height: 24),
            _InfoRow(label: 'Telefono', value: cd.telefono, icon: Icons.phone),
            const Divider(height: 24),
            _InfoRow(label: 'Email', value: cd.email, icon: Icons.email),
          ],
        ),
      ),
    );
  }

  Widget _buildAnagraficaEdit() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _editField('Nome', _nomeCtrl, Icons.person),
            _editField('Cognome', _cognomeCtrl, Icons.person_outline),
            _editField(
              'Data di nascita (gg/mm/aaaa)',
              _dataNascitaCtrl,
              Icons.cake,
            ),
            _editField(
              'Codice Fiscale',
              _cfCtrl,
              Icons.badge,
              capitalization: TextCapitalization.characters,
            ),
            _editField(
              'Telefono',
              _telefonoCtrl,
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _editField(
              'Email',
              _emailCtrl,
              Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════
  // ──  RESIDENZA VIEW / EDIT   ──
  // ════════════════════════════════
  Widget _buildResidenzaView(
    CitizenData cd,
    ColorScheme cs,
    List<String> frazioniDisponibili,
  ) {
    if (cd.indirizzo.isEmpty) {
      return Column(
        children: [
          _EmptySection(
            icon: Icons.home,
            message:
                'Nessun indirizzo di residenza inserito.\n'
                'Tocca "Aggiungi" per compilare il tuo indirizzo.',
          ),
          const SizedBox(height: 12),
          // rimosso selettore comune/frazione
        ],
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // rimosso selettore comune/frazione
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Indirizzo',
              value: '${cd.indirizzo}, ${cd.civico}',
              icon: Icons.home,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'CAP',
              value: cd.cap,
              icon: Icons.markunread_mailbox,
            ),
            const Divider(height: 24),
            _InfoRow(label: 'Provincia', value: cd.provincia, icon: Icons.map),
            const SizedBox(height: 12),
            _buildFrazioniChips(cs, frazioniDisponibili),
          ],
        ),
      ),
    );
  }

  Widget _buildResidenzaEdit() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _editField('Indirizzo', _indirizzoCtrl, Icons.home),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _editField('N°', _civicoCtrl, Icons.tag),
                ),
              ],
            ),
            _editField(
              'CAP',
              _capCtrl,
              Icons.markunread_mailbox,
              keyboardType: TextInputType.number,
            ),
            _editField('Provincia', _provinciaCtrl, Icons.map),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════
  // ──  ABITAZIONE CARD (single) ──
  // ════════════════════════════════
  Widget _buildAbitazioneCard(Abitazione ab, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D3B7A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D3B7A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        ab.tipoImmobile.isNotEmpty
                            ? ab.tipoImmobile
                            : 'Abitazione ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: const Color(0xFF0D3B7A),
                        onPressed: () =>
                            _openAbitazioneDialog(existing: ab, index: index),
                        tooltip: 'Modifica',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red,
                        onPressed: () => _confirmDeleteAbitazione(index),
                        tooltip: 'Elimina',
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              _InfoRow(
                label: 'Titolarità',
                value: ab.titolarita,
                icon: Icons.vpn_key,
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Tipo immobile',
                value: ab.tipoImmobile,
                icon: Icons.house,
              ),
              if (ab.superficie.isNotEmpty) ...[
                const Divider(height: 24),
                _InfoRow(
                  label: 'Superficie',
                  value: ab.superficie,
                  icon: Icons.square_foot,
                ),
              ],
              if (ab.renditaCatastale.isNotEmpty) ...[
                const Divider(height: 24),
                _InfoRow(
                  label: 'Rendita catastale',
                  value: ab.renditaCatastale,
                  icon: Icons.euro,
                ),
              ],
              if (ab.categoriaCatastale.isNotEmpty) ...[
                const Divider(height: 24),
                _InfoRow(
                  label: 'Categoria catastale',
                  value: ab.categoriaCatastale,
                  icon: Icons.category,
                ),
              ],
              if (ab.nucleoFamiliare.isNotEmpty) ...[
                const Divider(height: 24),
                _InfoRow(
                  label: 'Nucleo familiare',
                  value: ab.nucleoFamiliare,
                  icon: Icons.family_restroom,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════
  // ──  SHARED UI    ──
  // ════════════════════

  Widget _editField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0D3B7A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // rimosso selettore comune/frazione

  // rimosso selettore comune/frazione

  Widget _buildFrazioniChips(ColorScheme cs, List<String> frazioni) {
    if (frazioni.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frazioni del comune',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: frazioni.map((f) {
            return Chip(
              label: Text(f, style: TextStyle(fontSize: 12, color: cs.primary)),
              backgroundColor: cs.primary.withOpacity(0.08),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Empty Section placeholder ──
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Row ──
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '—',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value.isNotEmpty ? null : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
