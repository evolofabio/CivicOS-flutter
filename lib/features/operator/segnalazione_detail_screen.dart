import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _kPrimary = Color(0xFF0D3B7A);
const _kGreen = Color(0xFF00897B);
const _kOrange = Color(0xFFF57C00);
const _kRed = Color(0xFFE53935);

class SegnalazioneDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const SegnalazioneDetailScreen({required this.item, super.key});

  @override
  State<SegnalazioneDetailScreen> createState() =>
      _SegnalazioneDetailScreenState();
}

class _SegnalazioneDetailScreenState extends State<SegnalazioneDetailScreen> {
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _foto = [];
  final List<Map<String, String>> _noteOperatore = [];
  late String _stato;

  @override
  void initState() {
    super.initState();
    _stato = widget.item['stato'] as String;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Color _statoColor(String s) {
    switch (s) {
      case 'Aperta':
        return _kRed;
      case 'In lavorazione':
        return _kOrange;
      case 'Risolta':
        return _kGreen;
      default:
        return _kPrimary;
    }
  }

  IconData _statoIcon(String s) {
    switch (s) {
      case 'Aperta':
        return Icons.error_outline;
      case 'In lavorazione':
        return Icons.build;
      case 'Risolta':
        return Icons.check_circle;
      default:
        return Icons.flag;
    }
  }

  void _cambiaStato(String nuovoStato) {
    setState(() {
      _stato = nuovoStato;
      widget.item['stato'] = nuovoStato;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stato aggiornato: $nuovoStato'),
        backgroundColor: _statoColor(nuovoStato),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _scattaFoto() async {
    final img =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) {
      setState(() => _foto.add(File(img.path)));
    }
  }

  Future<void> _scegliDaGalleria() async {
    final img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      setState(() => _foto.add(File(img.path)));
    }
  }

  void _aggiungiNota() {
    final testo = _noteController.text.trim();
    if (testo.isEmpty) return;
    setState(() {
      _noteOperatore.add({
        'testo': testo,
        'data': '19/03/2026 ${TimeOfDay.now().format(context)}',
        'autore': 'Operatore',
      });
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text(item['id'] as String),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF8FAFD),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header stato
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _statoColor(_stato).withOpacity(0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_statoIcon(_stato),
                            color: _statoColor(_stato), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['categoria'] as String,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statoColor(_stato).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _stato,
                        style: TextStyle(
                          fontSize: 13,
                          color: _statoColor(_stato),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Informazioni
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descrizione
                    const Text('Descrizione',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      item['descrizione'] as String,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Dettagli
                    _DetailRow(
                        icon: Icons.location_on,
                        label: 'Posizione',
                        value: item['posizione'] as String),
                    _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Data',
                        value: item['data'] as String),
                    _DetailRow(
                        icon: Icons.tag,
                        label: 'ID',
                        value: item['id'] as String),
                    if (item['anonima'] == true)
                      _DetailRow(
                          icon: Icons.visibility_off,
                          label: 'Tipo',
                          value: 'Segnalazione anonima'),
                    if (item['anonima'] == false)
                      _DetailRow(
                          icon: Icons.person,
                          label: 'Tipo',
                          value: 'Segnalazione nominativa'),

                    const SizedBox(height: 24),

                    // Azioni rapide
                    const Text('Azioni',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (_stato == 'Aperta')
                          _FullActionBtn(
                            label: 'Prendi in carico',
                            color: _kOrange,
                            icon: Icons.build,
                            onTap: () => _cambiaStato('In lavorazione'),
                          ),
                        if (_stato == 'Aperta' || _stato == 'In lavorazione')
                          _FullActionBtn(
                            label: 'Segna risolta',
                            color: _kGreen,
                            icon: Icons.check_circle,
                            onTap: () => _cambiaStato('Risolta'),
                          ),
                        if (_stato == 'Risolta')
                          _FullActionBtn(
                            label: 'Riapri segnalazione',
                            color: _kRed,
                            icon: Icons.refresh,
                            onTap: () => _cambiaStato('Aperta'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // FOTO
                    Row(
                      children: [
                        const Text('Foto allegate',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: _kPrimary, size: 22),
                          tooltip: 'Scatta foto',
                          onPressed: _scattaFoto,
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library,
                              color: _kPrimary, size: 22),
                          tooltip: 'Galleria',
                          onPressed: _scegliDaGalleria,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_foto.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera_back,
                                size: 40, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('Nessuna foto allegata',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[400])),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _foto.length,
                          itemBuilder: (ctx, i) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _foto[i],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _foto.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),

                    // NOTE OPERATORE
                    const Text('Note operatore',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                hintText: 'Aggiungi una nota...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                              ),
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              minLines: 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: _kPrimary),
                            onPressed: _aggiungiNota,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_noteOperatore.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Nessuna nota inserita',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[400])),
                      )
                    else
                      ..._noteOperatore.reversed.map((n) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 14, color: _kPrimary),
                                    const SizedBox(width: 4),
                                    Text(n['autore']!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary)),
                                    const Spacer(),
                                    Text(n['data']!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400])),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(n['testo']!,
                                    style: const TextStyle(
                                        fontSize: 13, height: 1.4)),
                              ],
                            ),
                          )),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _FullActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _FullActionBtn(
      {required this.label,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}
