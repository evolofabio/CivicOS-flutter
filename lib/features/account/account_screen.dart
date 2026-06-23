import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final VoidCallback onChangePassword;

  const AccountScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Gestione Account'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0.5,
      ),
      body: Container(
        color: cs.surface,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).cardColor,
              child: ListTile(
                leading:
                    Icon(Icons.account_circle, size: 40, color: cs.primary),
                title: Text(userName, style: TextStyle(color: cs.onSurface)),
                subtitle: Text(userEmail,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
              ),
            ),
            const SizedBox(height: 24),
            Text('Azioni',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: cs.onSurface)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.logout, color: cs.onError),
              label: Text('Logout', style: TextStyle(color: cs.onError)),
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.lock_reset, color: cs.primary),
              label:
                  Text('Cambia password', style: TextStyle(color: cs.primary)),
              onPressed: onChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.surfaceVariant,
                foregroundColor: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
