import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/citizen_data.dart';
import '../../core/models/tenant.dart';
import '../../core/services/comuni_catalog.dart';
import '../../core/services/tenant_refs.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback onRegistrationSuccess;

  const RegistrationScreen({required this.onRegistrationSuccess, super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cognomeCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _indirizzoCtrl = TextEditingController();
  final _civicoCtrl = TextEditingController();

  // ── Dati personali aggiuntivi (opzionali) ──
  final _dataNascitaCtrl = TextEditingController();
  final _cfCtrl = TextEditingController();

  // ── Dati abitazione (opzionali) ──
  final _superficieCtrl = TextEditingController();
  final _renditaCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _nucleoCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController(text: 'VV');
  String _titolarita = '';
  String _tipoImmobile = '';

  bool _showExtraPersonal = false;
  bool _showExtraAbitazione = false;

  String? _comuneSelezionato;
  String? _frazioneSelezionata;
  bool _obscure = true;
  bool _loading = false;

  List<String> get _frazioniDisponibili {
    if (_comuneSelezionato == null) return [];
    return ComuniCatalog.frazioniStatiche(_comuneSelezionato);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cognomeCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _indirizzoCtrl.dispose();
    _civicoCtrl.dispose();
    _dataNascitaCtrl.dispose();
    _cfCtrl.dispose();
    _superficieCtrl.dispose();
    _renditaCtrl.dispose();
    _categoriaCtrl.dispose();
    _nucleoCtrl.dispose();
    _capCtrl.dispose();
    _provinciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Crea utente su Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Salva dati nel CitizenData model
      final cd = context.read<CitizenData>();
      cd.updateAnagrafica(
        nome: _nomeCtrl.text.trim(),
        cognome: _cognomeCtrl.text.trim(),
        dataNascita: _dataNascitaCtrl.text.trim(),
        codiceFiscale: _cfCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      cd.updateResidenza(
        indirizzo: _indirizzoCtrl.text.trim(),
        civico: _civicoCtrl.text.trim(),
        cap: _capCtrl.text.trim(),
        provincia: _provinciaCtrl.text.trim(),
      );
      if (_titolarita.isNotEmpty || _tipoImmobile.isNotEmpty) {
        cd.addAbitazione(
          Abitazione(
            titolarita: _titolarita,
            tipoImmobile: _tipoImmobile,
            superficie: _superficieCtrl.text.trim(),
            renditaCatastale: _renditaCtrl.text.trim(),
            categoriaCatastale: _categoriaCtrl.text.trim(),
            nucleoFamiliare: _nucleoCtrl.text.trim(),
          ),
        );
      }

      if (_comuneSelezionato != null) {
        // Salva il comune su Firestore per accesso multi-dispositivo
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final comuneId = Tenant.toId(_comuneSelezionato!);
          await TenantRefs.saveProfile(
            comuneId: comuneId,
            uid: uid,
            data: {
              'nome': _nomeCtrl.text.trim(),
              'cognome': _cognomeCtrl.text.trim(),
              'comune': _comuneSelezionato!,
              'comuneId': comuneId,
              'frazione': _frazioneSelezionata ?? '',
              'email': _emailCtrl.text.trim(),
            },
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRegistrationSuccess();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Errore durante la registrazione')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F0FF), Color(0xFFE0F5E4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 36),

                // --- Logo ---
                _buildLogo(),
                const SizedBox(height: 8),

                // --- Subtitle ---
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF00897B)],
                  ).createShader(bounds),
                  child: const Text(
                    'Civic Operating System',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Il sistema che unisce comune e cittadini',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 28),

                // --- Title ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Crea il tuo account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // --- Form ---
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nome e Cognome
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nomeCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                label: 'Nome',
                                icon: Icons.person_outline,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Obbligatorio'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cognomeCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                label: 'Cognome',
                                icon: Icons.person_outline,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Obbligatorio'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Comune
                      DropdownButtonFormField<String>(
                        value: _comuneSelezionato,
                        decoration: _inputDecoration(
                          label: 'Comune di residenza',
                          icon: Icons.location_city_outlined,
                        ),
                        items: ComuniCatalog.nomi
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _comuneSelezionato = v;
                            _frazioneSelezionata = null;
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Seleziona un comune' : null,
                      ),
                      const SizedBox(height: 14),

                      // Frazione
                      DropdownButtonFormField<String>(
                        value: _frazioneSelezionata,
                        decoration: _inputDecoration(
                          label: 'Frazione (opzionale)',
                          icon: Icons.map_outlined,
                        ),
                        items: _frazioniDisponibili
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _frazioneSelezionata = v),
                      ),
                      const SizedBox(height: 14),

                      // Telefono
                      TextFormField(
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          label: 'Numero di telefono',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Inserisci il numero di telefono';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Inserisci la tua email';
                          }
                          if (!v.contains('@')) return 'Email non valida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: _inputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Inserisci una password';
                          }
                          if (v.length < 6) return 'Minimo 6 caratteri';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Indirizzo + Civico
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _indirizzoCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                label: 'Indirizzo di residenza',
                                icon: Icons.home_outlined,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Obbligatorio'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _civicoCtrl,
                              keyboardType: TextInputType.text,
                              decoration: _inputDecoration(
                                label: 'N°',
                                icon: Icons.tag,
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'N°' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // CAP + Provincia
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _capCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                label: 'CAP',
                                icon: Icons.markunread_mailbox_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _provinciaCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _inputDecoration(
                                label: 'Prov.',
                                icon: Icons.map_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Dati personali aggiuntivi (opzionale) ──
                      _optionalSectionToggle(
                        title: 'Dati personali aggiuntivi',
                        subtitle: 'Data di nascita, codice fiscale',
                        icon: Icons.person_add_outlined,
                        isExpanded: _showExtraPersonal,
                        onToggle: () => setState(
                          () => _showExtraPersonal = !_showExtraPersonal,
                        ),
                      ),
                      if (_showExtraPersonal) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _dataNascitaCtrl,
                          decoration: _inputDecoration(
                            label: 'Data di nascita (gg/mm/aaaa)',
                            icon: Icons.cake_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cfCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _inputDecoration(
                            label: 'Codice Fiscale',
                            icon: Icons.badge_outlined,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // ── Dati abitazione (opzionale) ──
                      _optionalSectionToggle(
                        title: 'Dati abitazione',
                        subtitle: 'Titolarità, tipo immobile, superficie',
                        icon: Icons.house_outlined,
                        isExpanded: _showExtraAbitazione,
                        onToggle: () => setState(
                          () => _showExtraAbitazione = !_showExtraAbitazione,
                        ),
                      ),
                      if (_showExtraAbitazione) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _titolarita.isEmpty ? null : _titolarita,
                          decoration: _inputDecoration(
                            label: 'Titolarità',
                            icon: Icons.vpn_key_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Proprietario',
                              child: Text('Proprietario'),
                            ),
                            DropdownMenuItem(
                              value: 'Affittuario',
                              child: Text('Affittuario'),
                            ),
                            DropdownMenuItem(
                              value: 'Comodato d\'uso',
                              child: Text('Comodato d\'uso'),
                            ),
                            DropdownMenuItem(
                              value: 'Usufrutto',
                              child: Text('Usufrutto'),
                            ),
                            DropdownMenuItem(
                              value: 'Altro',
                              child: Text('Altro'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _titolarita = v ?? ''),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _tipoImmobile.isEmpty ? null : _tipoImmobile,
                          decoration: _inputDecoration(
                            label: 'Tipo immobile',
                            icon: Icons.house_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Abitazione principale',
                              child: Text('Abitazione principale'),
                            ),
                            DropdownMenuItem(
                              value: 'Seconda casa',
                              child: Text('Seconda casa'),
                            ),
                            DropdownMenuItem(
                              value: 'Immobile commerciale',
                              child: Text('Immobile commerciale'),
                            ),
                            DropdownMenuItem(
                              value: 'Terreno',
                              child: Text('Terreno'),
                            ),
                            DropdownMenuItem(
                              value: 'Altro',
                              child: Text('Altro'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _tipoImmobile = v ?? ''),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _superficieCtrl,
                          decoration: _inputDecoration(
                            label: 'Superficie (es. 95 mq)',
                            icon: Icons.square_foot_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _renditaCtrl,
                          decoration: _inputDecoration(
                            label: 'Rendita catastale (es. € 520,00)',
                            icon: Icons.euro_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _categoriaCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _inputDecoration(
                            label: 'Categoria catastale (es. A/3)',
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nucleoCtrl,
                          decoration: _inputDecoration(
                            label: 'Nucleo familiare (es. 3 componenti)',
                            icon: Icons.family_restroom_outlined,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Info opzionalità
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'I dati aggiuntivi sono opzionali. '
                                'Potrai inserirli o modificarli in qualsiasi momento dal Profilo.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Registrati
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Registrati',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Hai già un account ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hai già un account? ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Accedi',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionalSectionToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isExpanded
              ? const Color(0xFF1565C0).withOpacity(0.05)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFF1565C0).withOpacity(0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isExpanded ? const Color(0xFF1565C0) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isExpanded
                          ? const Color(0xFF1565C0)
                          : Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE3F0FF), Color(0xFFDBEFDC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.transparent,
            BlendMode.multiply,
          ),
          child: Image.asset(
            'assets/CivicOS.png',
            width: 95,
            height: 95,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
