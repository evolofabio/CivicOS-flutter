import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_os/core/services/comuni_catalog.dart';
import 'package:civic_os/features/account/account_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool seniorMode;
  final bool notificationsEnabled;
  final String comuneSelezionato;
  final String frazioneSelezionata;
  final Function(bool) onSeniorModeChanged;
  final Function(bool) onNotificationsChanged;
  final Function(String) onComuneChanged;
  final Function(String) onFrazioneChanged;
  final Function(bool) onPrivacyConsentChanged;
  final bool privacyConsent;
  final Function(bool) onDarkModeChanged;

  const SettingsScreen({
    super.key,
    required this.seniorMode,
    required this.notificationsEnabled,
    required this.comuneSelezionato,
    required this.frazioneSelezionata,
    required this.onSeniorModeChanged,
    required this.onNotificationsChanged,
    required this.onComuneChanged,
    required this.onFrazioneChanged,
    required this.onPrivacyConsentChanged,
    required this.privacyConsent,
    required this.onDarkModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _seniorMode;
  late bool _notificationsEnabled;
  late bool _privacyConsent;
  late String _comune;
  late String _frazione;

  @override
  void initState() {
    super.initState();
    _seniorMode = widget.seniorMode;
    _notificationsEnabled = widget.notificationsEnabled;
    _privacyConsent = widget.privacyConsent;
    _comune = widget.comuneSelezionato;
    _frazione = widget.frazioneSelezionata;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Notifiche
          SwitchListTile(
            title: const Text('Abilita notifiche'),
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              widget.onNotificationsChanged(v);
            },
          ),
          const Divider(),
          // Modalità Senior
          SwitchListTile(
            title: const Text('Modalità Senior'),
            value: _seniorMode,
            onChanged: (v) {
              setState(() => _seniorMode = v);
              widget.onSeniorModeChanged(v);
            },
          ),
          const Divider(),
          // Comune e frazione
          ListTile(
            title: const Text('Comune'),
            subtitle: Text(_comune),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Seleziona Comune'),
                    children: [
                      SizedBox(
                        width: 320,
                        height: 400,
                        child: ListView(
                          children: [
                            ...ComuniCatalog.nomi.map(
                              (c) => ListTile(
                                title: Text(c),
                                selected: c == _comune,
                                onTap: () => Navigator.pop(context, c),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
              if (selected != null && selected != _comune) {
                setState(() {
                  _comune = selected;
                  // reset frazione se non più valida
                  final fraz = ComuniCatalog.frazioniStatiche(_comune);
                  if (!fraz.contains(_frazione)) {
                    _frazione = fraz.isNotEmpty ? fraz.first : '';
                  }
                });
                widget.onComuneChanged(_comune);
                widget.onFrazioneChanged(_frazione);
              }
            },
          ),
          ListTile(
            title: const Text('Frazione'),
            subtitle: Text(_frazione),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final frazioni = ComuniCatalog.frazioniStatiche(_comune);
              if (frazioni.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Nessuna frazione disponibile per questo comune.',
                    ),
                  ),
                );
                return;
              }
              final selected = await showDialog<String>(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Seleziona Frazione'),
                    children: [
                      SizedBox(
                        width: 320,
                        height: 400,
                        child: ListView(
                          children: [
                            ...frazioni.map(
                              (f) => ListTile(
                                title: Text(f),
                                selected: f == _frazione,
                                onTap: () => Navigator.pop(context, f),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
              if (selected != null && selected != _frazione) {
                setState(() => _frazione = selected);
                widget.onFrazioneChanged(_frazione);
              }
            },
          ),
          const Divider(),
          // Privacy/consensi
          SwitchListTile(
            title: const Text('Consenso privacy e dati'),
            value: _privacyConsent,
            onChanged: (v) {
              setState(() => _privacyConsent = v);
              widget.onPrivacyConsentChanged(v);
            },
          ),
          const Divider(),
          // Placeholder per altre impostazioni
          ListTile(
            title: const Text('Lingua'),
            subtitle: const Text('Italiano'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Seleziona lingua'),
                  children: [
                    ListTile(
                      title: const Text('Italiano'),
                      onTap: () => Navigator.pop(context, 'it'),
                    ),
                    ListTile(
                      title: const Text('English'),
                      onTap: () => Navigator.pop(context, 'en'),
                    ),
                  ],
                ),
              );
              if (selected != null) {
                // TODO: implementa cambio lingua globale
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lingua selezionata: $selected')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Tema scuro'),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: widget.onDarkModeChanged,
            ),
          ),
          ListTile(
            title: const Text('Gestione account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              final displayName =
                  (user?.displayName != null &&
                      user!.displayName!.trim().isNotEmpty)
                  ? user.displayName!
                  : user?.email ?? 'Utente';
              final email = user?.email ?? '';
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AccountScreen(
                    userName: displayName,
                    userEmail: email,
                    onLogout: () {
                      Navigator.of(context).pop();
                      // TODO: implementa logout globale
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logout eseguito')),
                      );
                    },
                    onChangePassword: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cambia password'),
                          content: const Text('Funzionalità in sviluppo.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
