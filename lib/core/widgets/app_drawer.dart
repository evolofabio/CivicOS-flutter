import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../models/tenant.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool seniorMode;
  final int unreadAvvisi;
  final VoidCallback? onLogout;

  const AppDrawer({
    required this.currentIndex,
    required this.onTap,
    this.seniorMode = false,
    this.unreadAvvisi = 0,
    this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _menuItems;
    final tenant = Provider.of<Tenant>(context);

    return Drawer(
      child: Column(
        children: [
          // Header — premium gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D3B7A),
                  Color(0xFF1565C0),
                  Color(0xFF42A5F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: _buildComuneLogo(tenant.id),
                ),
                const SizedBox(height: 16),
                Text(
                  'CivicOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: seniorMode ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Portale del Cittadino',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: seniorMode ? 13 : 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = currentIndex == item['index'] as int;

                // Section header
                if (item['section'] != null) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      top: 20,
                      bottom: 6,
                    ),
                    child: Text(
                      item['section'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400],
                        letterSpacing: 1.2,
                      ),
                    ),
                  );
                }

                Widget? trailing;
                if (item['badge'] != null && (item['badge'] as int) > 0) {
                  trailing = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item['badge']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 1,
                  ),
                  child: Material(
                    color: isSelected
                        ? cs.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        onTap(item['index'] as int);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: seniorMode ? 38 : 34,
                              height: seniorMode ? 38 : 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withOpacity(0.12)
                                    : Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? cs.primary
                                    : Colors.grey[500],
                                size: seniorMode ? 22 : 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: seniorMode ? 16 : 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? cs.primary
                                      : const Color(0xFF374151),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            if (trailing != null) trailing,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout
          if (onLogout != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Color(0xFFE53935),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                      fontSize: seniorMode ? 16 : 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onLogout!();
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _menuItems => [
    // Sezione principale
    {'section': 'PRINCIPALE', 'index': -1},
    {'icon': Icons.home, 'label': 'Home', 'index': 0},
    {'icon': Icons.report, 'label': 'Segnala', 'index': 1},
    {'icon': Icons.calendar_today, 'label': 'Prenota', 'index': 2},
    {'icon': Icons.mail, 'label': 'Avvisi', 'index': 3, 'badge': unreadAvvisi},
    {'icon': Icons.history, 'label': 'Storico', 'index': 4},
    // Servizi
    {'section': 'SERVIZI', 'index': -2},
    {
      'icon': Icons.medical_services,
      'label': 'Servizi Convenzionati',
      'index': 5,
    },
    // Account
    {'section': 'ACCOUNT', 'index': -3},
    {'icon': Icons.person, 'label': 'Profilo', 'index': 7},
    // Impostazioni in fondo
    {'section': 'IMPOSTAZIONI', 'index': -4},
    {'icon': Icons.settings, 'label': 'Impostazioni', 'index': 6},
  ];

  Widget _buildComuneLogo(String comuneId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('comuni')
          .doc(comuneId)
          .snapshots(),
      builder: (context, snapshot) {
        final logoUrl = (snapshot.data?.data()?['portale']?['logoUrl'] ?? '')
            .toString();

        if (logoUrl.startsWith('data:image/')) {
          final commaIndex = logoUrl.indexOf(',');
          if (commaIndex > 0) {
            final b64 = logoUrl.substring(commaIndex + 1);
            try {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(b64),
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                ),
              );
            } catch (e) {
              debugPrint('[AppDrawer] logo decode error: $e');
            }
          }
        }

        if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              logoUrl,
              fit: BoxFit.cover,
              width: 56,
              height: 56,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.shield, color: Colors.white, size: 30),
            ),
          );
        }

        return const Icon(Icons.shield, color: Colors.white, size: 30);
      },
    );
  }
}
