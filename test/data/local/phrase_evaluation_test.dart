import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Batería completa de pruebas de traducción para el jurado', () async {
    final service = MockupDataService();
    await service.getAll();

    final categories = <String, List<String>>{
      '1. Frases de la consulta del usuario': [
        'me dedico a la orquestación',
        'hoy me monté en una llama',
        'ayer la llamé',
        'quiero estudiar por mucho tiempo en el intec',
        'yo soy soundme',
      ],
      '2. Presentación del proyecto y contexto universitario (INTEC)': [
        'buenos días distinguidos jurados',
        'nosotros somos estudiantes de ingeniería en intec',
        'bienvenidos a la presentación de soundme',
        'este proyecto ayuda a la comunidad sorda',
        'nuestra aplicación traduce voz a lengua de señas dominicana',
      ],
      '3. Desambiguación de homónimos por contexto (Demostración de IA)': [
        'hoy alimenté a una llama en el campo',
        'la llama de la vela quema con fuerza',
        'mi madre me llama por teléfono',
        'voy al banco a retirar dinero y pagar',
        'nos sentamos en un banco del parque a descansar',
        'me siento en la silla de la sala',
        'siento mucha alegría por esta presentación',
      ],
      '4. Cortesía y conversación cotidiana (Frases cortas y medianas)': [
        'hola cómo estás',
        'mucho gusto en conocerte',
        'por favor ayúdame',
        'muchas gracias por su atención',
        'dónde está el baño',
        'no entiendo puedes repetir por favor',
      ],
      '5. Frases largas, complejas y conectores': [
        'ayer fui al hospital porque me dolía mucho la cabeza',
        'mañana tenemos que entregar el proyecto final en la universidad',
        'me dedico a la música y al arte',
        'queremos mejorar la comunicación entre personas sordas y oyentes',
        'mi familia y yo vivimos en santo domingo',
      ],
      '6. Emergencias y salud': [
        'necesito un doctor urgente',
        'tengo dolor de estómago fuerte',
        'llama a una ambulancia por favor',
        'hubo un fuego peligroso',
      ],
    };

    print('\n================================================================');
    print('  INFORME DIAGNÓSTICO DEL TRADUCTOR - SOUNDME PARA EL JURADO');
    print('================================================================\n');

    int totalFrases = 0;
    int totalExitosas = 0;

    for (final entry in categories.entries) {
      print('----------------------------------------------------------------');
      print(' ${entry.key.toUpperCase()}');
      print('----------------------------------------------------------------');

      for (final phrase in entry.value) {
        totalFrases++;
        final res = await service.translatePhrase(phrase);

        final signsStr = res.matchedSigns.map((s) => s.palabra).join(' -> ');
        final isSpelled = res.spelledWords.isNotEmpty;
        final hasNotFound = res.notFoundWords.isNotEmpty;

        if (res.matchedSigns.isNotEmpty) {
          totalExitosas++;
        }

        print('Frase: "$phrase"');
        print('  • Señas: [ $signsStr ]');
        if (isSpelled) {
          print('  • Dactilología: ${res.spelledWords}');
        }
        if (hasNotFound) {
          print('  • No encontradas: ${res.notFoundWords}');
        }
        print('');
      }
    }

    print('================================================================');
    print('RESUMEN: $totalExitosas / $totalFrases frases procesadas con éxito.');
    print('================================================================\n');
  });
}
