import 'package:flutter/material.dart';
import 'differenziata_info_screen.dart';

class ProjectInfoScreen extends StatelessWidget {
  const ProjectInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF0D3B7A),
          fontWeight: FontWeight.bold,
        );
    final subtitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF0D3B7A),
          fontWeight: FontWeight.w600,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: Colors.black87,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final horizontalPadding = isWide ? constraints.maxWidth * 0.18 : 0.0;
        return Container(
          color: const Color(0xFFF8FAFD),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20 + horizontalPadding, 20, 20 + horizontalPadding, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardSection(
                    titleStyle: titleStyle, subtitleStyle: subtitleStyle),
                const SizedBox(height: 24),
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D3B7A), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CivicOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Civic Operating System',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Piattaforma Digitale Integrata per la Comunicazione Comune–Cittadino',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Introduzione
                CardSectionIntro(titleStyle: titleStyle, bodyStyle: bodyStyle),
                const SizedBox(height: 16),
                // Obiettivi
                CardSectionObiettivi(titleStyle: titleStyle),
                const SizedBox(height: 16),
                // Struttura
                CardSectionStruttura(titleStyle: titleStyle),
                const SizedBox(height: 16),
                // Funzionalità App
                CardSectionFunzionalitaApp(titleStyle: titleStyle),
                const SizedBox(height: 16),
                // Funzionalità Dashboard
                CardSectionFunzionalitaDashboard(titleStyle: titleStyle),
                const SizedBox(height: 16),
                // Benefici
                CardSectionBenefici(
                    titleStyle: titleStyle, subtitleStyle: subtitleStyle),
                const SizedBox(height: 16),
                // Innovazione
                CardSectionInnovazione(
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    bodyStyle: bodyStyle),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Helper widget sections ---
class CardSection extends StatelessWidget {
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  const CardSection({this.titleStyle, this.subtitleStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Raccolta Differenziata: guida e regole', style: titleStyle),
          const SizedBox(height: 12),
          const Text(
              'Scopri come funziona la raccolta differenziata, perché è importante e come separare correttamente i materiali. Leggi la guida completa per ogni categoria di rifiuto.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.info_outline),
            label: const Text('Guida raccolta differenziata'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D3B7A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DifferenziataInfoScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CardSectionIntro extends StatelessWidget {
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;
  const CardSectionIntro({this.titleStyle, this.bodyStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Introduzione', style: titleStyle),
          const SizedBox(height: 12),
          Text(
              'La crescente complessità della gestione dei servizi comunali richiede strumenti digitali moderni, efficienti e accessibili. I Comuni si trovano oggi a gestire numerosi canali di comunicazione con i cittadini: sportelli fisici, telefono, email, social network, siti istituzionali e applicazioni separate per servizi specifici.',
              style: bodyStyle),
          const SizedBox(height: 12),
          Text(
              'Il progetto propone lo sviluppo di una piattaforma digitale integrata, accessibile tramite applicazione mobile per i cittadini e dashboard gestionale per gli operatori comunali, con l\'obiettivo di centralizzare i servizi comunali, migliorare la comunicazione istituzionale e digitalizzare i processi operativi.',
              style: bodyStyle),
          const SizedBox(height: 12),
          Text(
              'La piattaforma si configura come una soluzione GovTech SaaS progettata per essere adottata da più Comuni contemporaneamente, garantendo efficienza amministrativa, semplificazione per i cittadini e capacità di analisi dei dati.',
              style: bodyStyle),
        ],
      ),
    );
  }
}

class CardSectionObiettivi extends StatelessWidget {
  final TextStyle? titleStyle;
  const CardSectionObiettivi({this.titleStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Obiettivi del progetto', style: titleStyle),
          const SizedBox(height: 16),
          _ObjectiveSection(
            icon: Icons.touch_app,
            title: 'Semplificazione dei servizi',
            items: [
              'Consultare il calendario della raccolta differenziata',
              'Ricevere comunicazioni ufficiali dal Comune',
              'Prenotare il ritiro di rifiuti ingombranti',
              'Segnalare problemi sul territorio',
              'Interagire con gli uffici comunali',
            ],
          ),
          const Divider(height: 32),
          _ObjectiveSection(
            icon: Icons.speed,
            title: 'Efficienza amministrativa',
            items: [
              'Gestione automatizzata delle richieste dei cittadini',
              'Organizzazione delle prenotazioni',
              'Diffusione comunicazioni pubbliche',
              'Raccolta e analisi delle segnalazioni territoriali',
            ],
          ),
          const Divider(height: 32),
          _ObjectiveSection(
            icon: Icons.devices,
            title: 'Digitalizzazione dei processi',
            items: [
              'Trasformare telefonate, sportelli, email e social media',
              'in processi digitali tracciabili, monitorabili e analizzabili',
            ],
          ),
          const Divider(height: 32),
          _ObjectiveSection(
            icon: Icons.accessibility_new,
            title: 'Inclusione digitale',
            items: [
              'Persone anziane',
              'Utenti con bassa familiarità tecnologica',
              'Interfaccia intuitiva e modalità semplificate',
            ],
          ),
        ],
      ),
    );
  }
}

class CardSectionStruttura extends StatelessWidget {
  final TextStyle? titleStyle;
  const CardSectionStruttura({this.titleStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Struttura della piattaforma', style: titleStyle),
          const SizedBox(height: 16),
          _StructureItem(
            icon: Icons.phone_android,
            title: 'App Mobile per i Cittadini',
            description:
                'Punto di accesso diretto tra cittadino e amministrazione comunale per gestire tutte le principali interazioni con il Comune.',
          ),
          const SizedBox(height: 12),
          _StructureItem(
            icon: Icons.dashboard,
            title: 'Dashboard Web per gli Operatori',
            description:
                'Piattaforma web gestionale per monitorare richieste, gestire segnalazioni e prenotazioni, inviare comunicazioni e analizzare dati.',
          ),
        ],
      ),
    );
  }
}

class CardSectionFunzionalitaApp extends StatelessWidget {
  final TextStyle? titleStyle;
  const CardSectionFunzionalitaApp({this.titleStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Funzionalità App Cittadini', style: titleStyle),
          const SizedBox(height: 16),
          _FeatureTile(
            icon: Icons.calendar_month,
            title: 'Calendario raccolta differenziata',
            desc:
                'Tipo di rifiuto del giorno, giorni futuri, variazioni straordinarie e notifiche automatiche.',
          ),
          _FeatureTile(
            icon: Icons.local_shipping,
            title: 'Prenotazione ritiro ingombranti',
            desc:
                'Selezione tipologia, inserimento indirizzo, scelta data e invio richiesta guidato.',
          ),
          _FeatureTile(
            icon: Icons.report_problem,
            title: 'Segnalazione problemi',
            desc:
                'Rifiuti abbandonati, discariche abusive, cestini pieni, degrado urbano con foto e posizione GPS.',
          ),
          _FeatureTile(
            icon: Icons.notifications_active,
            title: 'Comunicazioni e avvisi',
            desc:
                'Variazioni servizio rifiuti, allerte meteo, comunicazioni istituzionali, eventi pubblici.',
          ),
          _FeatureTile(
            icon: Icons.history,
            title: 'Storico richieste',
            desc:
                'Segnalazioni inviate, prenotazioni effettuate, stato avanzamento delle richieste.',
          ),
        ],
      ),
    );
  }
}

class CardSectionFunzionalitaDashboard extends StatelessWidget {
  final TextStyle? titleStyle;
  const CardSectionFunzionalitaDashboard({this.titleStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Funzionalità Dashboard Operatori', style: titleStyle),
          const SizedBox(height: 16),
          _FeatureTile(
            icon: Icons.monitor_heart,
            title: 'Monitoraggio segnalazioni',
            desc:
                'Visualizzazione per tipologia, stato, posizione e data. Presa in carico e assegnazione operatori.',
          ),
          _FeatureTile(
            icon: Icons.inventory,
            title: 'Gestione prenotazioni',
            desc:
                'Programmazione ritiri, modifica date, aggiornamento stato e gestione percorsi di raccolta.',
          ),
          _FeatureTile(
            icon: Icons.send,
            title: 'Invio comunicazioni',
            desc:
                'Notifiche a tutti i cittadini, a specifiche zone o categorie di utenti.',
          ),
          _FeatureTile(
            icon: Icons.analytics,
            title: 'Analisi dati e statistiche',
            desc:
                'Segnalazioni ricevute, tipologie più frequenti, prenotazioni e partecipazione cittadini.',
          ),
        ],
      ),
    );
  }
}

class CardSectionBenefici extends StatelessWidget {
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  const CardSectionBenefici({this.titleStyle, this.subtitleStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Benefici', style: titleStyle),
          const SizedBox(height: 16),
          Text('Per i Cittadini', style: subtitleStyle),
          const SizedBox(height: 8),
          _BenefitChip(label: 'Accesso semplificato ai servizi'),
          _BenefitChip(label: 'Riduzione tempi di attesa'),
          _BenefitChip(label: 'Maggiore trasparenza'),
          _BenefitChip(label: 'Partecipazione civica attiva'),
          const SizedBox(height: 16),
          Text('Per i Comuni', style: subtitleStyle),
          const SizedBox(height: 8),
          _BenefitChip(label: 'Migliore organizzazione servizi'),
          _BenefitChip(label: 'Riduzione costi operativi'),
          _BenefitChip(label: 'Comunicazione istituzionale efficace'),
          _BenefitChip(label: 'Raccolta dati strategici'),
        ],
      ),
    );
  }
}

class CardSectionInnovazione extends StatelessWidget {
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? bodyStyle;
  const CardSectionInnovazione(
      {this.titleStyle, this.subtitleStyle, this.bodyStyle, super.key});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Innovazione e scalabilità', style: titleStyle),
          const SizedBox(height: 12),
          Text(
              'La piattaforma è progettata come sistema multi-tenant: può essere adottata da più Comuni contemporaneamente mantenendo i dati separati.',
              style: bodyStyle),
          const SizedBox(height: 12),
          Text('Estensioni future:', style: subtitleStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('Pagamenti digitali')),
              Chip(label: Text('Servizi anagrafici')),
              Chip(label: Text('Prenotazione appuntamenti')),
              Chip(label: Text('Gestione tributi locali')),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Helper widgets (unchanged) ---

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ObjectiveSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _ObjectiveSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0D3B7A), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D3B7A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF0D3B7A))),
                  Expanded(
                      child: Text(item, style: const TextStyle(height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }
}

class _StructureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _StructureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D3B7A), size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                        color: Colors.grey[700], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D3B7A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0D3B7A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final String label;
  const _BenefitChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00897B), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
