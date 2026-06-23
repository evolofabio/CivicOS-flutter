import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/models/tenant.dart';
import '../../core/services/comune_config_service.dart';
import '../../core/services/tenant_refs.dart';
import '../cisterne/richiesta_cisterna_screen.dart';

class BookingScreen extends StatefulWidget {
  final bool seniorMode;
  BookingScreen({this.seniorMode = false});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _servizioSelezionato = 'ingombranti';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFD),
      child: Column(
        children: [
          // Selettore servizio
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prenota un servizio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Seleziona il servizio di cui hai bisogno',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ServiceTab(
                        icon: Icons.delete_outline,
                        label: 'Ritiro ingombranti',
                        selected: _servizioSelezionato == 'ingombranti',
                        onTap: () => setState(
                          () => _servizioSelezionato = 'ingombranti',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ServiceTab(
                        icon: Icons.water_drop,
                        label: 'Rifornimento acqua',
                        selected: _servizioSelezionato == 'acqua',
                        onTap: () =>
                            setState(() => _servizioSelezionato = 'acqua'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Contenuto in base al servizio
          Expanded(
            child: _servizioSelezionato == 'ingombranti'
                ? _IngombrantiForm()
                : RichiestaCisternaScreen(
                    seniorMode: widget.seniorMode,
                    embedded: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D3B7A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0D3B7A) : const Color(0xFFDDE1E6),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D3B7A).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form Ritiro Ingombranti (estratto dall'originale) ──

class _IngombrantiForm extends StatefulWidget {
  @override
  State<_IngombrantiForm> createState() => _IngombrantiFormState();
}

class _IngombrantiFormState extends State<_IngombrantiForm> {
  DateTime? _date;
  String? _tipo;
  final _indirizzo = TextEditingController();
  final _notes = TextEditingController();
  bool _sending = false;
  List<String> _tipiIngombranti =
      ComuneConfigService.defaults['tipiIngombranti']!;
  StreamSubscription<Map<String, List<String>>>? _configSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindConfig());
  }

  void _bindConfig() {
    final tenant = Provider.of<Tenant>(context, listen: false);
    _configSub?.cancel();
    _configSub = ComuneConfigService.watch(tenant.id).listen((cfg) {
      if (mounted) setState(() => _tipiIngombranti = cfg['tipiIngombranti']!);
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _indirizzo.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<bool> _writeWithGracefulFallback(Future<void> Function() op) async {
    try {
      await op().timeout(const Duration(seconds: 6));
      return true;
    } on TimeoutException {
      // Evita blocchi UI: continua il tentativo in background.
      unawaited(
        op().catchError((e, _) {
          debugPrint('[CivicOS] Background write failed (prenotazione): $e');
        }),
      );
      return false;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _send() async {
    if (_tipo == null || _indirizzo.text.trim().isEmpty || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi obbligatori')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final tenant = Provider.of<Tenant>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      final dataStr =
          '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}';
      final confirmed = await _writeWithGracefulFallback(
        () => TenantRefs.prenotazioniCol(tenant.id).doc().set({
          'tipo': _tipo,
          'indirizzo': _indirizzo.text.trim(),
          'data': dataStr,
          'stato': 'In attesa',
          'note': _notes.text.trim(),
          'uid': user?.uid ?? '',
          'email': user?.email ?? '',
          'comuneId': tenant.id,
          'timestamp': FieldValue.serverTimestamp(),
        }),
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _tipo = null;
        _date = null;
      });
      _indirizzo.clear();
      _notes.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmed
                ? 'Prenotazione inviata con successo!'
                : 'Prenotazione ricevuta. Sincronizzazione in corso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final msg = e is TimeoutException
          ? 'Connessione lenta: invio non confermato. Riprova tra pochi secondi.'
          : 'Errore durante l\'invio. Verifica la connessione e riprova.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Tipologia
          _StepCard(
            step: '1',
            title: 'Tipologia di rifiuto',
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                hintText: 'Seleziona tipologia',
                prefixIcon: Icon(Icons.delete_outline),
              ),
              isExpanded: true,
              items: _tipiIngombranti
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v),
              value: _tipo,
            ),
          ),
          const SizedBox(height: 12),

          // Step 2: Indirizzo
          _StepCard(
            step: '2',
            title: 'Indirizzo di ritiro',
            child: TextField(
              controller: _indirizzo,
              decoration: const InputDecoration(
                hintText: 'Es. Via Roma, 15',
                prefixIcon: Icon(Icons.home),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Step 3: Data
          _StepCard(
            step: '3',
            title: 'Scegli la data disponibile',
            child: InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'Seleziona data',
                ),
                child: Text(
                  _date == null
                      ? 'Seleziona una data'
                      : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}',
                  style: TextStyle(
                    color: _date == null ? Colors.grey[500] : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Step 4: Note
          _StepCard(
            step: '4',
            title: 'Note aggiuntive (opzionale)',
            child: TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Es. Piano terra, 2 oggetti, citofono Rossi...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.note_alt),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Invio
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _sending ? 'Invio in corso...' : 'Invia Prenotazione',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D3B7A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
