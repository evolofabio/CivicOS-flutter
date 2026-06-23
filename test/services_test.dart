import 'package:civic_os/core/services/calendario_service.dart';
import 'package:civic_os/core/services/comune_config_service.dart';
import 'package:civic_os/core/services/comuni_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CalendarioService fallback for unknown frazione', () {
    final cal = CalendarioService.fallbackForFrazione('Unknown');
    expect(cal.length, 7);
    expect(cal.first['giorno'], 'Lunedì');
  });

  test('CalendarioService parsePerFrazione', () {
    final parsed = CalendarioService.parsePerFrazione({
      'perFrazione': {
        'Centro': [
          {'giorno': 'Lunedì', 'tipi': ['Umido'], 'variazione': null},
        ],
      },
    });
    expect(parsed['Centro']!.length, 1);
    expect(CalendarioService.tipiForDay(parsed['Centro']!, 'Lunedì'), {'Umido'});
  });

  test('ComuneConfigService defaults', () {
    final cfg = ComuneConfigService.parse(null);
    expect(cfg['categorieSegnalazione']!.isNotEmpty, true);
    expect(cfg['tipiIngombranti']!.contains('Mobili'), true);
  });

  test('ComuniCatalog normalizeName', () {
    expect(ComuniCatalog.normalizeName('Vibo Valentia', null), 'Vibo Valentia');
    expect(ComuniCatalog.normalizeName(null, 'vibo-valentia'), 'Vibo Valentia');
  });
}
