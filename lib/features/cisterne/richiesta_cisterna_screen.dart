import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/models/tenant.dart';
import '../../core/services/tenant_refs.dart';

class RichiestaCisternaScreen extends StatefulWidget {
  final bool seniorMode;
  final bool embedded;
  RichiestaCisternaScreen({this.seniorMode = false, this.embedded = false});

  @override
  State<RichiestaCisternaScreen> createState() =>
      _RichiestaCisternaScreenState();
}

class _RichiestaCisternaScreenState extends State<RichiestaCisternaScreen> {
  String? _motivazione;
  final _indirizzo = TextEditingController();
  final _civico = TextEditingController();
  final _telefono = TextEditingController();
  final _notes = TextEditingController();
  int _numPersone = 1;
  bool _sending = false;
  bool _urgente = false;

  Future<bool> _writeWithGracefulFallback(Future<void> Function() op) async {
    try {
      await op().timeout(const Duration(seconds: 6));
      return true;
    } on TimeoutException {
      // Evita blocchi UI: continua il tentativo in background.
      unawaited(
        op().catchError((e, _) {
          debugPrint('[CivicOS] Background write failed (cisterna): $e');
        }),
      );
      return false;
    }
  }

  static const List<String> motivazioni = [
    'Assenza totale di acqua',
    'Pressione insufficiente',
    'Cisterna vuota (periodo estivo)',
    'Guasto alla rete idrica',
    'Lavori programmati sulla rete',
    'Altro',
  ];

  void _send() async {
    if (_motivazione == null || _indirizzo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi obbligatori')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final tenant = Provider.of<Tenant>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();
      final dataStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final indirizzoCompleto = _civico.text.trim().isEmpty
          ? _indirizzo.text.trim()
          : '${_indirizzo.text.trim()}, ${_civico.text.trim()}';
      final confirmed = await _writeWithGracefulFallback(
        () => TenantRefs.cisterneCol(tenant.id).doc().set({
          'motivazione': _motivazione,
          'indirizzo': indirizzoCompleto,
          'telefono': _telefono.text.trim(),
          'numPersone': _numPersone,
          'urgente': _urgente,
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
        _motivazione = null;
        _numPersone = 1;
        _urgente = false;
      });
      _indirizzo.clear();
      _civico.clear();
      _telefono.clear();
      _notes.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmed
                ? 'Richiesta rifornimento cisterna inviata con successo!'
                : 'Richiesta cisterna ricevuta. Sincronizzazione in corso.',
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
    return Container(
      color: const Color(0xFFF8FAFD),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded) ...[
              Text(
                'Richiesta rifornimento acqua',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Richiedi al Comune il rifornimento della cisterna d\'acqua per emergenza idrica o periodo estivo',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],

            // Banner informativo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF1565C0),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Il servizio è attivo nei periodi di emergenza idrica e durante la stagione estiva. '
                      'Le richieste vengono evase entro 48 ore lavorative.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 1: Motivazione
            _StepCard(
              step: '1',
              title: 'Motivo della richiesta',
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Seleziona il motivo',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                isExpanded: true,
                items: motivazioni
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _motivazione = v),
                value: _motivazione,
              ),
            ),
            const SizedBox(height: 12),

            // Step 2: Indirizzo
            _StepCard(
              step: '2',
              title: 'Indirizzo di consegna',
              child: Column(
                children: [
                  TextField(
                    controller: _indirizzo,
                    decoration: const InputDecoration(
                      hintText: 'Es. Via Roma',
                      prefixIcon: Icon(Icons.home),
                      labelText: 'Via / Piazza',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _civico,
                    decoration: const InputDecoration(
                      hintText: 'Es. 15',
                      prefixIcon: Icon(Icons.pin),
                      labelText: 'Numero civico',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Step 3: Contatto
            _StepCard(
              step: '3',
              title: 'Recapito telefonico',
              child: TextField(
                controller: _telefono,
                decoration: const InputDecoration(
                  hintText: 'Es. 333 1234567',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(height: 12),

            // Step 4: Persone
            _StepCard(
              step: '4',
              title: 'Nucleo familiare',
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Numero persone:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _numPersone > 1
                        ? () => setState(() => _numPersone--)
                        : null,
                  ),
                  Text(
                    '$_numPersone',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _numPersone < 20
                        ? () => setState(() => _numPersone++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Step 5: Urgenza
            _StepCard(
              step: '5',
              title: 'Urgenza',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Richiesta urgente'),
                subtitle: Text(
                  _urgente
                      ? 'Assenza completa di acqua potabile'
                      : 'Situazione non critica',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                secondary: Icon(
                  _urgente ? Icons.warning_amber : Icons.schedule,
                  color: _urgente ? Colors.orange : Colors.grey,
                ),
                value: _urgente,
                onChanged: (v) => setState(() => _urgente = v),
              ),
            ),
            const SizedBox(height: 12),

            // Step 6: Note
            _StepCard(
              step: '6',
              title: 'Note aggiuntive (opzionale)',
              child: TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Es. Cisterna da 1000L sul terrazzo, accesso dal cancello laterale...',
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
                    : const Icon(Icons.water_drop),
                label: Text(
                  _sending ? 'Invio in corso...' : 'Invia Richiesta Acqua',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
