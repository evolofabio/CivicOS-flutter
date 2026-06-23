import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/tenant_refs.dart';

const _kPrimary = Color(0xFF0D3B7A);
const _kGreen = Color(0xFF00897B);

/// Tipo di allegato supportato
enum _AllegatoTipo { foto, video, documento }

class _Allegato {
  final File file;
  final _AllegatoTipo tipo;
  final String nome;
  _Allegato({required this.file, required this.tipo, required this.nome});
}

class NuovaComunicazioneScreen extends StatefulWidget {
  final String comuneId;
  const NuovaComunicazioneScreen({required this.comuneId, super.key});

  @override
  State<NuovaComunicazioneScreen> createState() =>
      _NuovaComunicazioneScreenState();
}

class _NuovaComunicazioneScreenState extends State<NuovaComunicazioneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titoloCtrl = TextEditingController();
  final _corpoCtrl = TextEditingController();
  String _tipo = 'servizio';
  final _picker = ImagePicker();
  final List<_Allegato> _allegati = [];

  static const _tipi = {
    'servizio': {'label': 'Servizio', 'icon': Icons.miscellaneous_services},
    'allerta': {'label': 'Allerta', 'icon': Icons.warning_amber},
    'evento': {'label': 'Evento', 'icon': Icons.celebration},
    'istituzionale': {'label': 'Istituzionale', 'icon': Icons.account_balance},
  };

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _corpoCtrl.dispose();
    super.dispose();
  }

  // ── Foto ──
  Future<void> _scattaFoto() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (img != null) {
      setState(
        () => _allegati.add(
          _Allegato(
            file: File(img.path),
            tipo: _AllegatoTipo.foto,
            nome: img.name,
          ),
        ),
      );
    }
  }

  Future<void> _scegliDaGalleria() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      setState(
        () => _allegati.addAll(
          imgs.map(
            (x) => _Allegato(
              file: File(x.path),
              tipo: _AllegatoTipo.foto,
              nome: x.name,
            ),
          ),
        ),
      );
    }
  }

  // ── Video ──
  Future<void> _registraVideo() async {
    final vid = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );
    if (vid != null) {
      setState(
        () => _allegati.add(
          _Allegato(
            file: File(vid.path),
            tipo: _AllegatoTipo.video,
            nome: vid.name,
          ),
        ),
      );
    }
  }

  Future<void> _scegliVideo() async {
    final vid = await _picker.pickVideo(source: ImageSource.gallery);
    if (vid != null) {
      setState(
        () => _allegati.add(
          _Allegato(
            file: File(vid.path),
            tipo: _AllegatoTipo.video,
            nome: vid.name,
          ),
        ),
      );
    }
  }

  // ── Documenti (simulato con nota testuale, in produzione userebbe file_picker) ──
  void _allegaDocumento() {
    // In un'app reale si userebbe file_picker per PDF/DOC/etc.
    // Per il prototipo simuliamo l'aggiunta di un documento
    showDialog(
      context: context,
      builder: (ctx) {
        final nomeCtrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Allega documento',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'In produzione si aprirà il selettore file.\nPer il prototipo, inserisci il nome del documento:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomeCtrl,
                decoration: InputDecoration(
                  hintText: 'es. delibera_2026.pdf',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeCtrl.text.trim();
                if (nome.isNotEmpty) {
                  setState(
                    () => _allegati.add(
                      _Allegato(
                        file: File(''), // placeholder per prototipo
                        tipo: _AllegatoTipo.documento,
                        nome: nome,
                      ),
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text(
                'Allega',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pubblica() async {
    if (!_formKey.currentState!.validate()) return;

    final nFoto = _allegati.where((a) => a.tipo == _AllegatoTipo.foto).length;
    final nVideo = _allegati.where((a) => a.tipo == _AllegatoTipo.video).length;
    final nDoc = _allegati
        .where((a) => a.tipo == _AllegatoTipo.documento)
        .length;

    final allegatiDesc = [
      if (nFoto > 0) '$nFoto foto',
      if (nVideo > 0) '$nVideo video',
      if (nDoc > 0) '$nDoc documento/i',
    ].join(', ');

    final now = DateTime.now();
    final dataStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    try {
      await TenantRefs.comunicazioniCol(widget.comuneId).add({
        'titolo': _titoloCtrl.text.trim(),
        'corpo': _corpoCtrl.text.trim(),
        'tipo': _tipo,
        'stato': 'attivo',
        'data': dataStr,
        'dataTs': FieldValue.serverTimestamp(),
        'letto': false,
        'allegati': allegatiDesc,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comunicazione pubblicata!'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[NuovaComunicazione] Errore pubblicazione: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la pubblicazione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova comunicazione'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF8FAFD),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo
                const Text(
                  'Tipo comunicazione',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tipi.entries.map((e) {
                    final selected = _tipo == e.key;
                    return ChoiceChip(
                      avatar: Icon(
                        e.value['icon'] as IconData,
                        size: 18,
                        color: selected ? Colors.white : _kPrimary,
                      ),
                      label: Text(e.value['label'] as String),
                      selected: selected,
                      selectedColor: _kPrimary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : _kPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _tipo = e.key),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Titolo
                const Text(
                  'Titolo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titoloCtrl,
                  decoration: InputDecoration(
                    hintText: 'Inserisci il titolo...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kPrimary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 15),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),

                const SizedBox(height: 20),

                // Corpo
                const Text(
                  'Testo comunicazione',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _corpoCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Scrivi il contenuto della comunicazione...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kPrimary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),

                const SizedBox(height: 24),

                // ── ALLEGATI MULTIMEDIALI ──
                const Text(
                  'Allegati multimediali',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),

                // Riga 1: Foto
                Row(
                  children: [
                    _AttachButton(
                      icon: Icons.camera_alt,
                      label: 'Scatta foto',
                      onTap: _scattaFoto,
                    ),
                    const SizedBox(width: 10),
                    _AttachButton(
                      icon: Icons.photo_library,
                      label: 'Galleria foto',
                      onTap: _scegliDaGalleria,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Riga 2: Video
                Row(
                  children: [
                    _AttachButton(
                      icon: Icons.videocam,
                      label: 'Registra video',
                      onTap: _registraVideo,
                    ),
                    const SizedBox(width: 10),
                    _AttachButton(
                      icon: Icons.video_library,
                      label: 'Galleria video',
                      onTap: _scegliVideo,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Riga 3: Documenti
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _allegaDocumento,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text(
                      'Allega documento (PDF, DOC...)',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Conteggio allegati
                if (_allegati.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_allegati.length} allegat${_allegati.length == 1 ? 'o' : 'i'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),

                // ── Preview allegati ──
                if (_allegati.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.perm_media_outlined,
                          size: 36,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nessun allegato',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aggiungi foto, video o documenti',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[350],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _allegati.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final a = _allegati[i];
                      return _AllegatoTile(
                        allegato: a,
                        onRemove: () => setState(() => _allegati.removeAt(i)),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                // Pulsante pubblica
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _pubblica,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Pubblica comunicazione',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AttachButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: _kPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// Tile per singolo allegato — anteprima diversa per foto, video, documento
class _AllegatoTile extends StatelessWidget {
  final _Allegato allegato;
  final VoidCallback onRemove;
  const _AllegatoTile({required this.allegato, required this.onRemove});

  IconData _iconForTipo() {
    switch (allegato.tipo) {
      case _AllegatoTipo.foto:
        return Icons.image;
      case _AllegatoTipo.video:
        return Icons.videocam;
      case _AllegatoTipo.documento:
        return Icons.description;
    }
  }

  Color _colorForTipo() {
    switch (allegato.tipo) {
      case _AllegatoTipo.foto:
        return const Color(0xFF0288D1);
      case _AllegatoTipo.video:
        return const Color(0xFFE53935);
      case _AllegatoTipo.documento:
        return const Color(0xFFF57C00);
    }
  }

  String _labelTipo() {
    switch (allegato.tipo) {
      case _AllegatoTipo.foto:
        return 'Foto';
      case _AllegatoTipo.video:
        return 'Video';
      case _AllegatoTipo.documento:
        return 'Documento';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForTipo();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Anteprima
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            child:
                allegato.tipo == _AllegatoTipo.foto &&
                    allegato.file.path.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    child: Image.file(allegato.file, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_iconForTipo(), color: color, size: 28),
                      const SizedBox(height: 2),
                      Text(
                        _labelTipo(),
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allegato.nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _labelTipo(),
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rimuovi
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
            onPressed: onRemove,
            tooltip: 'Rimuovi',
          ),
        ],
      ),
    );
  }
}
