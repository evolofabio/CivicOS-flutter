import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/models/tenant.dart';
import '../../core/services/tenant_refs.dart';

class SeniorComunicazioniScreen extends StatelessWidget {
  const SeniorComunicazioniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = Provider.of<Tenant>(context, listen: false);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TenantRefs.comunicazioniCol(tenant.id)
          .where('stato', isEqualTo: 'attivo')
          .orderBy('dataTs', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final comunicazioni = (snapshot.data?.docs ?? [])
            .map((doc) => doc.data())
            .toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            title: const Text(
              'Avvisi del Comune',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            toolbarHeight: 64,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: comunicazioni.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nessun avviso al momento',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: comunicazioni.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = comunicazioni[index];
                    final tipo = c['tipo'] as String;
                    final letto = c['letto'] as bool? ?? true;

                    return Material(
                      color: letto ? Colors.white : const Color(0xFFF5F8FF),
                      borderRadius: BorderRadius.circular(14),
                      elevation: letto ? 0 : 1,
                      child: InkWell(
                        onTap: () => _mostraDettaglio(context, c),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: letto
                                  ? Colors.grey[200]!
                                  : const Color(0xFF1565C0).withOpacity(0.3),
                              width: letto ? 1 : 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _tipoColor(tipo).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _tipoIcon(tipo),
                                  color: _tipoColor(tipo),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!letto)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1565C0),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'NUOVO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      c['titolo'] ?? '',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: letto
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c['data'] ?? '',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 20,
                                color: Colors.grey,
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

  void _mostraDettaglio(BuildContext context, Map<String, dynamic> c) {
    final tipo = c['tipo'] as String;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _tipoColor(tipo).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_tipoIcon(tipo), color: _tipoColor(tipo), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              c['titolo'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              c['data'] ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            Text(
              c['corpo'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Chiudi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'allerta':
        return Icons.warning_amber_rounded;
      case 'evento':
        return Icons.event;
      case 'istituzionale':
        return Icons.account_balance;
      default:
        return Icons.info_outline;
    }
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'allerta':
        return Colors.red;
      case 'evento':
        return Colors.green;
      case 'istituzionale':
        return Colors.orange;
      default:
        return const Color(0xFF1565C0);
    }
  }
}
