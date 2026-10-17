import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Evaluación diagnóstica exhaustiva de 120 frases para el traductor LSRD', () async {
    final service = MockupDataService();
    await service.getAll();

    final Map<String, List<String>> categories = {
      '1. Saludos, Despedidas y Cortesía': [
        'hola buenos días a todos',
        'buenas tardes cómo estás hoy',
        'buenas noches que descanses bien',
        'mucho gusto en conocerte amigo',
        'muchas gracias por tu gran ayuda',
        'por favor ayúdame con esto',
        'de nada siempre a la orden',
        'hasta luego nos vemos mañana',
        'adiós que te vaya muy bien',
        'disculpe dónde queda el baño por favor',
      ],
      '2. Familia, Hogar y Relaciones Personales': [
        'mi mamá y mi papá cuidan a la familia con amor',
        'tengo dos hermanos y una hermana menor',
        'mi abuelo y mi abuela viven en el campo',
        'mi hijo juega con su perro en la casa',
        'mi amiga vino ayer a visitarme',
        'nosotros cenamos juntos en la mesa todas las noches',
        'mi tío tiene una casa bonita cerca del mar',
        'mi prima se casó el mes pasado',
        'los niños juegan en el parque con la pelota',
        'yo quiero mucho a mi familia',
      ],
      '3. Universidad, Educación y Proyecto SoundMe': [
        'nosotros somos estudiantes de ingeniería en intec',
        'soundme traduce voz y texto a lengua de señas dominicana',
        'los profesores enseñan matemáticas y ciencias en la escuela',
        'mañana tenemos que entregar el proyecto final de grado',
        'la educación es un derecho fundamental para todas las personas',
        'estudiamos en la biblioteca de la universidad todos los días',
        'la presentación del software fue un gran éxito',
        'queremos aprender lengua de señas para comunicarnos mejor',
        'el estudiante aprobó el examen difícil con buena nota',
        'la tecnología de inteligencia artificial ayuda a la inclusión social',
      ],
      '4. Salud, Medicina y Emergencias': [
        'necesito un doctor urgente porque me siento muy enfermo',
        'llama a una ambulancia por favor hay un accidente grave',
        'tengo un dolor fuerte en el pecho y en el brazo',
        'la enfermera me dio la medicina en el hospital',
        'los bomberos apagaron el fuego peligroso en el edificio',
        'el paciente tiene fiebre alta y dolor de cabeza',
        'tómese esta pastilla con agua después del almuerzo',
        'la clínica de salud abre temprano en la mañana',
        'auxilio socorro ayúdenme por favor',
        'tenga calma y respire despacio',
      ],
      '5. Desambiguación Contextual de Homónimos': [
        'la llama de la vela quema con fuerza en la oscuridad',
        'hoy alimenté a una llama en el campo de la montaña',
        'mi madre me llama por teléfono todos los domingos',
        'voy al banco a retirar dinero y pagar la tarjeta',
        'nos sentamos en un banco del parque a conversar',
        'me siento en la silla para descansar un momento',
        'siento mucha alegría y emoción en el corazón',
        'brindamos con una copa de vino tinto en la cena',
        'mi hermano vino temprano a mi casa hoy',
        'el cura dio la misa en la iglesia el domingo',
      ],
      '6. Alimentación, Cocina y Restaurantes': [
        'queremos comer arroz con habichuela y carne al mediodía',
        'el desayuno incluye café con leche, pan y queso',
        'vamos a cocinar una cena deliciosa para los invitados',
        'por favor tráigame un vaso de agua fría',
        'la comida en este restaurante es muy buena y sabrosa',
        'tengo mucha hambre y sed después de hacer ejercicio',
        'compramos frutas frescas como guineo, piña y mango en el mercado',
        'el pastel de chocolate es mi postre favorito',
        'la sopa de verduras está muy caliente',
        'pedimos la cuenta para pagar la comida',
      ],
      '7. Ciudad, Transporte y Direcciones': [
        'dónde está la estación del metro más cercana',
        'el carro dobló a la derecha en la próxima esquina',
        'viajamos en autobús hacia santiago de los caballeros',
        'el avión despegó del aeropuerto a tiempo',
        'camine dos cuadras derecho y luego cruce la calle',
        'el semáforo cambió a luz roja y el conductor frenó',
        'no encuentro las llaves de mi carro',
        'el parque central de la ciudad es muy grande y limpio',
        'tomamos un taxi para llegar rápido a la reunión',
        'la tienda de ropa queda frente a la farmacia',
      ],
      '8. Tiempo, Calendario y Clima': [
        'qué hora es en este momento',
        'hoy es lunes y mañana es martes de trabajo',
        'hace mucho calor y sol durante el verano',
        'en el mes de diciembre celebramos la navidad en familia',
        'ayer llovió fuertemente con truenos y viento',
        'la cita es el próximo viernes a las tres de la tarde',
        'el tiempo pasa muy rápido cuando estamos ocupados',
        'hace frío en las noches de invierno en la montaña',
        'la primavera trae flores y colores bonitos',
        'nos vemos el fin de semana para descansar',
      ],
      '9. Trabajo, Profesiones y Tecnología': [
        'me dedico a la programación de software y desarrollo web',
        'el abogado defiende los derechos de su cliente en el tribunal',
        'el ingeniero diseñó un sistema eficiente y moderno',
        'trabajo ocho horas diarias en una oficina del centro',
        'envié el archivo adjunto por correo electrónico a mi jefe',
        'la computadora portátil se quedó sin batería',
        'el policía vigila la seguridad del vecindario con atención',
        'el maestro enseña la lección a los estudiantes en el aula',
        'busco un empleo nuevo con buen salario',
        'esta aplicación móvil facilita la vida cotidiana de las personas',
      ],
      '10. Emociones, Estados de Ánimo y Sensaciones': [
        'estoy muy feliz y agradecido con la vida',
        'ella se siente triste y preocupada por la noticia',
        'tengo miedo a la oscuridad y a las alturas',
        'estamos muy cansados después de una larga jornada de trabajo',
        'siento sorpresa y asombro por este maravilloso resultado',
        'él está enojado porque perdió el autobús de la mañana',
        'tengo la esperanza y la fe de que todo saldrá bien',
        'siento mucha paz y tranquilidad en este lugar',
        'el niño llora porque le duele la rodilla',
        'sonreír todos los días mejora la salud y el ánimo',
      ],
      '11. Dominicanismos, Cultura y Frases Típicas': [
        'vamos a darnos un baño en la playa de boca chica',
        'en república dominicana el béisbol es el deporte rey',
        'nos comemos un sancocho sabroso cuando llueve',
        'el malecón de santo domingo es un lugar hermoso para pasear',
        'vamos a escuchar merengue y bachata en la fiesta',
        'el plátano con salami y queso frito es nuestro desayuno típico',
        'los dominicanos somos personas alegres, amables y solidarias',
        'disfrutamos del carnaval dominicano con música y alegría',
        'un vaso de morir soñando frío cae muy bien con este calor',
        'dios bendiga a nuestra hermosa patria dominicana',
      ],
      '12. Frases Complejas, Conectores y Condicionales': [
        'si estudias con disciplina y constancia vas a triunfar',
        'queremos viajar pero no tenemos suficiente dinero ahorrado',
        'sin embargo continuamos trabajando con entusiasmo para lograrlo',
        'aunque el camino sea difícil nunca debemos rendirnos',
        'no pude asistir a la reunión porque estuve ocupado todo el día',
        'si necesitas ayuda puedes llamarme a cualquier hora',
        'a pesar de los problemas logramos terminar el proyecto a tiempo',
        'primero investigamos el problema y después creamos la solución',
        'mientras tú cocinas el almuerzo yo voy a limpiar la casa',
        'todos juntos podemos construir un país más justo e inclusivo',
      ],
    };

    int totalFrases = 0;
    int totalExitosas = 0;
    final Map<String, int> spelledWordCounts = {};
    final Map<String, int> notFoundWordCounts = {};
    int totalSignsCount = 0;
    int totalSpelledSignsCount = 0;

    print('\n========================================================================');
    print('  INFORME DE EVALUACIÓN DE 120 ORACIONES VARIADAS - SOUNDME LSRD');
    print('========================================================================\n');

    for (final cat in categories.entries) {
      print('\n------------------------------------------------------------------------');
      print('>>> ${cat.key.toUpperCase()} (${cat.value.length} frases)');
      print('------------------------------------------------------------------------');

      int catFrases = 0;
      int catExitosas = 0;

      for (final phrase in cat.value) {
        totalFrases++;
        catFrases++;

        final res = await service.translatePhrase(phrase);
        if (res.matchedSigns.isNotEmpty) {
          totalExitosas++;
          catExitosas++;
        }

        totalSignsCount += res.matchedSigns.length;

        for (final sp in res.spelledWords) {
          spelledWordCounts[sp] = (spelledWordCounts[sp] ?? 0) + 1;
        }
        for (final nf in res.notFoundWords) {
          notFoundWordCounts[nf] = (notFoundWordCounts[nf] ?? 0) + 1;
        }

        final directSigns = res.matchedSigns.where((s) => s.categoria != 'Deletreo').toList();
        final spelledSigns = res.matchedSigns.where((s) => s.categoria == 'Deletreo').toList();
        totalSpelledSignsCount += spelledSigns.length;

        final directStr = directSigns.map((s) => s.palabra).join(' -> ');
        print('Frase [$totalFrases]: "$phrase"');
        print('  • Señas Directas (${directSigns.length}): [ $directStr ]');
        if (res.spelledWords.isNotEmpty) {
          print('  • Dactilología (${res.spelledWords.length} palabras): ${res.spelledWords}');
        }
        if (res.notFoundWords.isNotEmpty) {
          print('  • No Encontradas: ${res.notFoundWords}');
        }
      }

      print('>> Subtotal Categoría: $catExitosas / $catFrases exitosas.');
    }

    print('\n========================================================================');
    print('                      RESUMEN GLOBAL DIAGNÓSTICO');
    print('========================================================================');
    print('Total de Frases Evaluadas: $totalFrases');
    print('Frases con traducción exitosa: $totalExitosas / $totalFrases (${(totalExitosas / totalFrases * 100).toStringAsFixed(1)}%)');
    print('Total de Señas Generadas: $totalSignsCount (Directas: ${totalSignsCount - totalSpelledSignsCount}, Dactilología: $totalSpelledSignsCount)');
    print('Palabras que cayeron en deletreo (${spelledWordCounts.length} únicas):');
    final sortedSpelled = spelledWordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sortedSpelled.take(30)) {
      print('   - ${e.key}: ${e.value} veces');
    }
    print('Palabras No Encontradas (${notFoundWordCounts.length} únicas):');
    final sortedNotFound = notFoundWordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sortedNotFound.take(30)) {
      print('   - ${e.key}: ${e.value} veces');
    }
    print('========================================================================\n');

    expect(totalFrases, equals(120));
    expect(totalExitosas, equals(120));
  });
}
