import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/citizen_data.dart';
import '../../core/models/tenant.dart';
import '../../core/services/comune_config_service.dart';
import '../../core/services/tenant_refs.dart';

class ReportScreen extends StatefulWidget {
  final bool seniorMode;
  ReportScreen({this.seniorMode = false});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _descController = TextEditingController();
  final _posizioneController = TextEditingController();
  String? _categoria;
  bool _sending = false;
  XFile? _fotoAllegata;
  bool _posizioneRilevata = false;
  bool _anonima = false;
  final _picker = ImagePicker();
  List<String> _categorie = ComuneConfigService.defaults['categorieSegnalazione']!;
  StreamSubscription<Map<String, List<String>>>? _configSub;
  String? _tenantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tenant = Provider.of<Tenant>(context, listen: false);
    if (_tenantId == tenant.id) return;
    _tenantId = tenant.id;
    _configSub?.cancel();
    _configSub = ComuneConfigService.watch(tenant.id).listen((cfg) {
      if (mounted) setState(() => _categorie = cfg['categorieSegnalazione']!);
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _descController.dispose();
    _posizioneController.dispose();
    super.dispose();
  }

  String _buildUtenteDisplay({
    required String nome,
    required String cognome,
    required User? user,
    required bool anonima,
  }) {
    if (anonima) return 'Anonimo';
    final full = '$nome $cognome'.trim();
    if (full.isNotEmpty) return full;
    final direct = (user?.displayName ?? '').trim();
    if (direct.isNotEmpty) return direct;
    final email = (user?.email ?? '').trim();
    if (email.isNotEmpty) return email;
    return 'Utente registrato';
  }

  Future<(String, String)> _resolveNomeCognome(User? user) async {
    final uid = (user?.uid ?? '').trim();
    if (uid.isNotEmpty) {
      try {
        final comuneId = Provider.of<Tenant>(context, listen: false).id;
        final doc = await TenantRefs.utentiDoc(
          comuneId,
          uid,
        ).get().timeout(const Duration(seconds: 2));
        final data = doc.data();
        if (data != null) {
          final nome = (data['nome'] ?? '').toString().trim();
          final cognome = (data['cognome'] ?? '').toString().trim();
          if (nome.isNotEmpty || cognome.isNotEmpty) {
            return (nome, cognome);
          }
        }
      } catch (e) {
        debugPrint('[ReportScreen] _fetchNomeCognome error: $e');
      }
    }

    final citizen = Provider.of<CitizenData>(context, listen: false);
    final localNome = citizen.nome.trim();
    final localCognome = citizen.cognome.trim();
    if (localNome.isNotEmpty || localCognome.isNotEmpty) {
      return (localNome, localCognome);
    }

    return ('', '');
  }

  Future<Map<String, dynamic>> _buildFotoPayload({
    required String comuneId,
    required String segnalazioneId,
  }) async {
    if (_fotoAllegata == null) return {'foto': false};

    try {
      final ref = FirebaseStorage.instance.ref().child(
        'comuni/$comuneId/segnalazioni/$segnalazioneId.jpg',
      );
      await ref.putFile(
        File(_fotoAllegata!.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      return {'foto': true, 'fotoUrl': url, 'fotoNome': _fotoAllegata!.name};
    } catch (e) {
      debugPrint('[CivicOS] Upload foto fallito, provo fallback inline: $e');
    }

    try {
      final bytes = await _fotoAllegata!.readAsBytes();
      if (bytes.lengthInBytes <= 700 * 1024) {
        return {
          'foto': true,
          'fotoDataUrl': 'data:image/jpeg;base64,${base64Encode(bytes)}',
          'fotoNome': _fotoAllegata!.name,
        };
      }
    } catch (e) {
      debugPrint('[CivicOS] Fallback foto inline fallito: $e');
    }

    return {'foto': false};
  }

  Future<bool> _writeWithGracefulFallback(Future<void> Function() op) async {
    try {
      await op().timeout(const Duration(seconds: 6));
      return true;
    } on TimeoutException {
      // Evita blocchi UI: continua il tentativo in background.
      unawaited(
        op().catchError((e, _) {
          debugPrint('[CivicOS] Background write failed (segnalazione): $e');
        }),
      );
      return false;
    }
  }

  Future<bool> _ensureRealGpsPosition() async {
    if (_posizioneRilevata && _posizioneController.text.trim().contains(',')) {
      return true;
    }
    await _rilievaGPS();
    return _posizioneRilevata && _posizioneController.text.trim().contains(',');
  }

  void _send() async {
    if (_categoria == null || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila categoria e descrizione')),
      );
      return;
    }

    final hasRealPosition = await _ensureRealGpsPosition();
    if (!hasRealPosition) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossibile rilevare la posizione reale. Attiva GPS e permessi posizione, poi riprova.',
          ),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final tenant = Provider.of<Tenant>(context, listen: false);
      final now = DateTime.now();
      final dataStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final wasAnonima = _anonima;
      final user = FirebaseAuth.instance.currentUser;
      final segnalazioniRef = TenantRefs.segnalazioniCol(tenant.id);
      final docRef = segnalazioniRef.doc();
      final segnalazioneId = docRef.id;
      final (utenteNome, utenteCognome) = await _resolveNomeCognome(user);
      final utenteDisplay = _buildUtenteDisplay(
        nome: utenteNome,
        cognome: utenteCognome,
        user: user,
        anonima: wasAnonima,
      );
      final fotoPayload = await _buildFotoPayload(
        comuneId: tenant.id,
        segnalazioneId: segnalazioneId,
      );

      double? lat;
      double? lng;
      final posRaw = _posizioneController.text.trim();
      if (posRaw.contains(',')) {
        final parts = posRaw.split(',');
        if (parts.length >= 2) {
          lat = double.tryParse(parts[0].trim());
          lng = double.tryParse(parts[1].trim());
        }
      }

      final confirmed = await _writeWithGracefulFallback(
        () => docRef.set({
          'segnalazioneId': segnalazioneId,
          'categoria': _categoria,
          'descrizione': _descController.text.trim(),
          'data': dataStr,
          'stato': 'Aperta',
          'posizione': posRaw,
          'lat': lat,
          'lng': lng,
          'anonima': _anonima,
          'uid': user?.uid ?? '',
          'email': user?.email ?? '',
          'utenteDisplay': utenteDisplay,
          'utenteNome': wasAnonima ? '' : utenteNome,
          'utenteCognome': wasAnonima ? '' : utenteCognome,
          'utenteId': user?.uid ?? '',
          'utenteEmail': wasAnonima ? '' : (user?.email ?? ''),
          'comuneId': tenant.id,
          'timestamp': FieldValue.serverTimestamp(),
          ...fotoPayload,
        }),
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _fotoAllegata = null;
        _posizioneRilevata = false;
        _categoria = null;
        _anonima = false;
      });
      _descController.clear();
      _posizioneController.clear();
      final okMsg = wasAnonima
          ? 'Segnalazione anonima inviata! ID: $segnalazioneId'
          : 'Segnalazione inviata! ID: $segnalazioneId';
      final syncMsg = wasAnonima
          ? 'Segnalazione anonima ricevuta (ID: $segnalazioneId). Sincronizzazione in corso.'
          : 'Segnalazione ricevuta (ID: $segnalazioneId). Sincronizzazione in corso.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(confirmed ? okMsg : syncMsg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final msg = e is TimeoutException
          ? 'Connessione lenta: invio non confermato. Riprova tra pochi secondi.'
          : 'Errore durante l\'invio. Verifica la connessione e riprova.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _scattaFoto() async {
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (foto != null && mounted) {
        setState(() => _fotoAllegata = foto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore fotocamera: verifica i permessi dell\'app'),
          ),
        );
      }
    }
  }

  Future<void> _scegliDaGalleria() async {
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (foto != null && mounted) {
        setState(() => _fotoAllegata = foto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore accesso galleria')),
        );
      }
    }
  }

  Future<void> _rilievaGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('GPS disattivato sul dispositivo'),
            action: SnackBarAction(
              label: 'Apri GPS',
              onPressed: Geolocator.openLocationSettings,
            ),
          ),
        );
      }
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permesso posizione negato')),
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permesso posizione negato in modo permanente. Abilitalo nelle impostazioni.',
            ),
            action: SnackBarAction(
              label: 'Impostazioni',
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rilevamento GPS in corso...')),
      );
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final lat = pos.latitude.toStringAsFixed(6);
      final lon = pos.longitude.toStringAsFixed(6);
      setState(() {
        _posizioneRilevata = true;
        _posizioneController.text = '$lat, $lon';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Posizione rilevata: $lat, $lon')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore GPS: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: const Color(0xFFF8FAFD),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Segnala un problema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Segnala problematiche ambientali o urbane sul territorio',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Segnalazione anonima
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _anonima ? Icons.visibility_off : Icons.person,
                          color: _anonima
                              ? const Color(0xFFF57C00)
                              : const Color(0xFF0D3B7A),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Modalità di segnalazione',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _anonima
                                    ? 'I tuoi dati non saranno visibili'
                                    : 'I tuoi dati saranno associati alla segnalazione',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _anonima,
                          onChanged: (v) => setState(() => _anonima = v),
                          activeColor: const Color(0xFFF57C00),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _anonima
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _anonima ? Icons.shield : Icons.badge,
                            size: 18,
                            color: _anonima
                                ? const Color(0xFFF57C00)
                                : const Color(0xFF0D3B7A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _anonima
                                  ? 'Segnalazione anonima — nessun dato personale verrà inviato'
                                  : 'Segnalazione identificata — il comune potrà contattarti per aggiornamenti',
                              style: TextStyle(
                                fontSize: 12,
                                color: _anonima
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF0D47A1),
                                height: 1.3,
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
            const SizedBox(height: 12),

            // Categoria
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categoria',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        hintText: 'Seleziona una categoria',
                        prefixIcon: Icon(Icons.category),
                      ),
                      isExpanded: true,
                      items: _categorie
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _categoria = v),
                      value: _categoria,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Descrizione
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descrizione del problema',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Descrivi il problema nel dettaglio...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.edit_note),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Posizione GPS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Posizione geografica',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _posizioneController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText:
                            'Posizione GPS reale (rilevata automaticamente)',
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: _posizioneRilevata ? Colors.green : null,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.my_location, color: cs.primary),
                          onPressed: _rilievaGPS,
                          tooltip: 'Rileva posizione GPS',
                        ),
                      ),
                    ),
                    if (_posizioneRilevata)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Posizione rilevata',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Foto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fotografie',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_fotoAllegata != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_fotoAllegata!.path),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _fotoAllegata = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_fotoAllegata != null) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scattaFoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scatta foto'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scegliDaGalleria,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galleria'),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  _sending
                      ? 'Invio in corso...'
                      : _anonima
                      ? 'Invia Segnalazione Anonima'
                      : 'Invia Segnalazione',
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
