import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/tenant.dart';
import '../../core/services/aziende_service.dart';
import '../../core/services/comune_config_service.dart';

class ServiziConvenzionatiScreen extends StatefulWidget {
  const ServiziConvenzionatiScreen({super.key});

  @override
  State<ServiziConvenzionatiScreen> createState() =>
      _ServiziConvenzionatiScreenState();
}

class _ServiziConvenzionatiScreenState extends State<ServiziConvenzionatiScreen> {
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = Provider.of<Tenant>(context);
    return Container(
      color: const Color(0xFFF8FAFD),
      child: StreamBuilder<List<AziendaConvenzionata>>(
        stream: AziendeService.watch(tenant.id),
        builder: (context, aziendeSnap) {
          return StreamBuilder<Map<String, dynamic>>(
            stream: ComuneConfigService.watchPartner(tenant.id),
            builder: (context, partnerSnap) {
              final partner = partnerSnap.data ??
                  ComuneConfigService.defaultPartnerSanitario;
              final aziende = aziendeSnap.data ?? [];
              final sanitarie = AziendeService.filterSanitarie(aziende);
              final showPartner = sanitarie.isEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 20),
                    if (showPartner) ...[
                      _partnerSection(context, partner),
                      const SizedBox(height: 20),
                    ],
                    if (sanitarie.isNotEmpty) ...[
                      Text(
                        'Strutture convenzionate',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...sanitarie.map((a) => _aziendaCard(context, a)),
                    ] else if (aziende.isNotEmpty) ...[
                      Text(
                        'Aziende e servizi del comune',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...aziende.map((a) => _aziendaCard(context, a)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: const Color(0xFF0D3B7A),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.medical_services, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Servizi Convenzionati',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Assistenza sanitaria e servizi per i cittadini',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerSection(BuildContext context, Map<String, dynamic> partner) {
    final nome = (partner['nome'] ?? 'VisitaMedical').toString();
    final tel = (partner['telefono'] ?? '').toString();
    final wa = (partner['whatsapp'] ?? '').toString();
    final sito = (partner['sito'] ?? '').toString();
    final orari = (partner['orari'] ?? '').toString();
    final specs = (partner['specialita'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (partner['sottotitolo'] != null)
              Text(
                partner['sottotitolo'].toString(),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            if (tel.isNotEmpty)
              _action(Icons.phone, Colors.green, 'Chiama', tel, () => _launch('tel:$tel')),
            if (wa.isNotEmpty)
              _action(Icons.chat, const Color(0xFF25D366), 'WhatsApp', wa,
                  () => _launch('https://wa.me/$wa')),
            if (sito.isNotEmpty)
              _action(Icons.language, const Color(0xFF0D3B7A), 'Sito web', sito,
                  () => _launch(sito)),
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specs
                    .map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 12))))
                    .toList(),
              ),
            ],
            if (orari.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(orari, style: TextStyle(fontSize: 13, color: Colors.orange[900])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _aziendaCard(BuildContext context, AziendaConvenzionata a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(a.ragioneSociale, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [a.settore, a.indirizzo].where((x) => x.isNotEmpty).join(' · '),
        ),
        trailing: a.telefono.isNotEmpty ? const Icon(Icons.phone) : null,
        onTap: a.telefono.isNotEmpty ? () => _launch('tel:${a.telefono}') : null,
      ),
    );
  }

  Widget _action(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
