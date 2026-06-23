import 'package:flutter/material.dart';

class DifferenziataInfoScreen extends StatelessWidget {
  const DifferenziataInfoScreen({Key? key}) : super(key: key);

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

    return Container(
      color: const Color(0xFFF8FAFD),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cos\'è la raccolta differenziata?', style: titleStyle),
            const SizedBox(height: 12),
            Text(
              'La raccolta differenziata è il sistema di separazione dei rifiuti domestici in base alla tipologia di materiale, per favorire il riciclo e ridurre l\'impatto ambientale. Ogni materiale deve essere conferito nell\'apposito contenitore.',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),
            Text('Come funziona', style: subtitleStyle),
            const SizedBox(height: 12),
            Text(
              'Ogni categoria di rifiuto (umido, plastica, carta, vetro, metalli, secco residuo) deve essere separata e conferita secondo le regole comunali. Segui sempre il calendario e le istruzioni fornite dal Comune.',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),
            Text('Guida per categoria', style: subtitleStyle),
            const SizedBox(height: 12),
            _categoryGuide(bodyStyle),
          ],
        ),
      ),
    );
  }

  Widget _categoryGuide(TextStyle? bodyStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryItem('Umido',
            'Scarti di cucina, avanzi di cibo, fondi di caffè, bucce. No plastica, metalli o vetro.'),
        _categoryItem('Plastica',
            'Bottiglie, flaconi, vaschette, imballaggi. Sciacquare e schiacciare. No giocattoli, no oggetti in plastica dura.'),
        _categoryItem('Carta',
            'Giornali, quaderni, scatole, cartoni. No carta sporca di cibo, no scontrini.'),
        _categoryItem('Vetro',
            'Bottiglie, barattoli, vasetti. Sciacquare. No ceramica, no lampadine.'),
        _categoryItem('Metalli',
            'Lattine, barattoli, fogli di alluminio. Sciacquare. No oggetti ingombranti.'),
        _categoryItem('Secco residuo',
            'Tutto ciò che non può essere riciclato: mozziconi, spugne, penne, carta oleata.'),
      ],
    );
  }

  Widget _categoryItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
