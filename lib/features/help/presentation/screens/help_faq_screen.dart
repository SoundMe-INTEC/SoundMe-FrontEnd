import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';
import 'package:soundme_frontend/features/options/presentation/screens/permissions_screen.dart';

class HelpFaqScreen extends StatefulWidget {
  final int initialTabIndex;

  const HelpFaqScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  final List<String> _categories = [
    'Todas',
    'Traductor y Voz',
    'Reproductor',
    'LSRD y Señas',
    'Diccionario y Ajustes',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(
                  height: 65,
                ), // Espacio para el header con back button
                // BARRA DE BÚSQUEDA
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardFillColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'Buscar en la ayuda o preguntas frecuentes...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textGray,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primaryNavy,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.textGray,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ),

                // SELECTOR DE CATEGORÍAS (CHIPS)
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryNavy,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryNavy,
                          backgroundColor: AppColors.cardFillColor,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryNavy
                                  : Colors.transparent,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // PESTAÑAS: GUÍA DE USO Y FAQ
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryNavy,
                  unselectedLabelColor: AppColors.textGray,
                  indicatorColor: AppColors.primaryNavy,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.menu_book_outlined, size: 20),
                      text: 'Guía de Uso',
                    ),
                    Tab(
                      icon: Icon(Icons.help_outline_rounded, size: 20),
                      text: 'Preguntas Frecuentes',
                    ),
                  ],
                ),

                // CONTENIDO DE LAS PESTAÑAS
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildGuideTab(), _buildFaqTab()],
                  ),
                ),
              ],
            ),
          ),

          // HEADER CON BOTÓN REGRESAR
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(title: 'Centro de Ayuda & FAQ'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PESTAÑA 1: GUÍA DE USO PASO A PASO
  // ==========================================
  Widget _buildGuideTab() {
    final guideItems = _getFilteredGuideItems();

    if (guideItems.isEmpty) {
      return _buildEmptyResults(
        'No se encontraron temas en la guía con el filtro seleccionado.',
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        ...guideItems.map((item) => _buildGuideCard(item)),
        const SizedBox(height: 24),
        _buildSupportCard(),
        const SizedBox(height: 16),
        const Center(child: SoundMeLogo()),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGuideCard(_GuideItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.primaryNavy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
            if (item.steps.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...item.steps.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryNavy,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$idx',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 1.3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (item.actionLabel != null && item.onAction != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: item.onAction,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primaryNavy,
                  ),
                  label: Text(
                    item.actionLabel!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PESTAÑA 2: PREGUNTAS FRECUENTES (FAQ)
  // ==========================================
  Widget _buildFaqTab() {
    final faqItems = _getFilteredFaqItems();

    if (faqItems.isEmpty) {
      return _buildEmptyResults(
        'No se encontraron preguntas frecuentes con el criterio buscado.',
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        ...faqItems.map((item) => _buildFaqTile(item)),
        const SizedBox(height: 24),
        _buildSupportCard(),
        const SizedBox(height: 16),
        const Center(child: SoundMeLogo()),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFaqTile(_FaqItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.primaryNavy,
              size: 20,
            ),
          ),
          title: Text(
            item.question,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              item.category,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textGray,
              ),
            ),
          ),
          children: [
            const Divider(color: Colors.black12, height: 16),
            Text(
              item.answer,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.45,
                color: AppColors.textDark,
              ),
            ),
            if (item.actionLabel != null && item.onAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: item.onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: Text(
                    item.actionLabel!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TARJETA DE SOPORTE Y CONTACTO
  // ==========================================
  Widget _buildSupportCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                '¿Necesitas más ayuda?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Si tienes dudas sobre señas de la LSRD, sugerencias para el catálogo o problemas técnicos, nuestro equipo de soporte está a tu disposición:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.35,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.email_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'soporte@soundme.org',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SoundMe v1.0.0 LSRD Edition • Certificado para accesibilidad universal',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 54,
              color: AppColors.textGray,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FILTRADO Y DATOS DE LA GUÍA
  // ==========================================
  List<_GuideItem> _getFilteredGuideItems() {
    final items = _getAllGuideItems();
    return items.where((item) {
      final matchesCategory =
          _selectedCategory == 'Todas' || item.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;

      return item.title.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery) ||
          item.steps.any((s) => s.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  List<_GuideItem> _getAllGuideItems() {
    return [
      _GuideItem(
        icon: Icons.mic_rounded,
        title: 'Traducción por Voz a Señas',
        category: 'Traductor y Voz',
        description:
            'Convierte tus oraciones habladas en señas oficiales en tiempo real utilizando el reconocimiento vocal inteligente.',
        steps: [
          'Presiona el botón circular del micrófono en la pantalla del Traductor.',
          'El botón se iluminará en rojo con un pulso continuo indicando que está escuchando.',
          'Pronuncia tu mensaje con claridad a un ritmo natural.',
          'Al hacer una pausa de 3 segundos o presionar nuevamente el botón, el sistema procesará la voz y comenzará la reproducción de señas.',
        ],
        actionLabel: 'Ver Permisos de Micrófono',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PermissionsScreen()),
        ),
      ),
      _GuideItem(
        icon: Icons.keyboard_rounded,
        title: 'Traducción por Texto y Sugerencias',
        category: 'Traductor y Voz',
        description:
            'Escribe cualquier frase u oración o selecciona recomendaciones preconfiguradas para traducir de inmediato.',
        steps: [
          'Toca el cuadro de texto en la parte inferior e ingresa tu mensaje.',
          'El motor analiza el texto reactivamente mientras escribes.',
          'Presiona la tecla Enter o el botón circular azul de envío para procesar la traducción completa.',
          'También puedes pulsar sugerencias rápidas como "HOLA CÓMO ESTÁS" para pruebas instantáneas.',
        ],
      ),
      _GuideItem(
        icon: Icons.video_collection_rounded,
        title: 'Controles del Reproductor Multimedia',
        category: 'Reproductor',
        description:
            'Aprende a pausar, avanzar seña a seña y regular la cadencia para un estudio y comprensión detallados.',
        steps: [
          'Play / Pausa: Detén la animación en cualquier postura de manos para ver la postura exacta.',
          'Flechas Anterior / Siguiente: Navega paso a paso por cada una de las señas que componen la frase.',
          'Barra de Tiempo Deslizante: Arrastra el punto para moverte directamente a cualquier punto de la oración.',
          'Selector de Velocidad: Ajusta el tiempo entre Lento (3s para aprender), Normal (2s para conversación) y Rápido (1s).',
        ],
      ),
      _GuideItem(
        icon: Icons.sign_language_rounded,
        title: 'Lengua de Señas Dominicana (LSRD) y Deletreo',
        category: 'LSRD y Señas',
        description:
            'Comprende cómo se representan las señas oficiales, los gestos faciales y las palabras que requieren deletreo manual.',
        steps: [
          'Seña Oficial: Palabra o concepto que cuenta con un gesto registrado en el estándar LSRD.',
          'Deletreo Dactilológico: Cuando una palabra (como un nombre de persona o término técnico) no tiene seña fija, SoundMe muestra la etiqueta de deletreo y ejecuta el alfabeto manual letra por letra.',
          'Gesto Facial: Observa las indicaciones debajo de la seña (Pregunta, Admiración o Neutral) para aplicar la expresión facial adecuada.',
        ],
      ),
      _GuideItem(
        icon: Icons.tune_rounded,
        title: 'Modos de Traducción: Flexible vs. Explícito',
        category: 'Diccionario y Ajustes',
        description:
            'Personaliza cómo el motor procesa las palabras en la pantalla de Opciones.',
        steps: [
          'Modo Flexible (Recomendado): Corrige automáticamente erratas de escritura (ej. "avogado" -> "abogado") y busca sinónimos si la palabra exacta no existe.',
          'Modo Explícito: Busca únicamente coincidencias idénticas. Si no existe, recurre al deletreo dactilológico estricto sin sustitución.',
          'Puedes alternar este modo en la pestaña de Opciones mediante el interruptor interactivo.',
        ],
      ),
      _GuideItem(
        icon: Icons.menu_book_rounded,
        title: 'Explorador y Diccionario de Señas',
        category: 'Diccionario y Ajustes',
        description:
            'Consulta el catálogo completo de señas, clasificado en categorías esenciales para la vida cotidiana.',
        steps: [
          'Accede desde el menú principal o la barra de navegación al Diccionario.',
          'Explora categorías especializadas: Saludos Básicos, Frases Comunes y Emergencias.',
          'Usa el buscador para localizar palabras específicas y ver su descripción gestual detallada.',
        ],
        actionLabel: 'Ir al Diccionario',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DictionaryScreen()),
        ),
      ),
      _GuideItem(
        icon: Icons.wifi_off_rounded,
        title: 'Funcionamiento Local y Modo Offline',
        category: 'Diccionario y Ajustes',
        description:
            'SoundMe está diseñado para funcionar en cualquier lugar sin depender de una conexión activa a internet.',
        steps: [
          'La base de datos de señas y el vocabulario residen en el almacenamiento interno mediante SQLite.',
          'Puedes traducir por texto y consultar el diccionario completo de forma 100% offline.',
          'El reconocimiento de voz funciona con el motor nativo del dispositivo, requiriendo datos únicamente para el modelo de voz si tu teléfono no tiene dictado offline habilitado.',
        ],
      ),
    ];
  }

  // ==========================================
  // FILTRADO Y DATOS DE PREGUNTAS FRECUENTES
  // ==========================================
  List<_FaqItem> _getFilteredFaqItems() {
    final items = _getAllFaqItems();
    return items.where((item) {
      final matchesCategory =
          _selectedCategory == 'Todas' || item.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;

      return item.question.toLowerCase().contains(_searchQuery) ||
          item.answer.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<_FaqItem> _getAllFaqItems() {
    return [
      _FaqItem(
        question: '¿Por qué el micrófono no me escucha o se detiene solo?',
        category: 'Traductor y Voz',
        answer:
            'Existen dos motivos frecuentes:\n1. Permiso no otorgado: Verifica en Opciones > Notificaciones y Permisos que el acceso al micrófono esté encendido.\n2. Detección automática de pausa: SoundMe detiene la escucha tras 3 segundos de silencio para procesar la traducción de inmediato. Si necesitas pensar tu frase, puedes hablar en tramos o utilizar la entrada de texto.',
        actionLabel: 'Verificar Permisos',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PermissionsScreen()),
        ),
      ),
      _FaqItem(
        question:
            '¿Qué significa cuando una seña dice "Deletreo Dactilológico"?',
        category: 'LSRD y Señas',
        answer:
            'En la Lengua de Señas Dominicana (LSRD), muchos nombres propios, términos extranjeros o palabras poco frecuentes no tienen una seña única. En esos casos, la comunidad sorda recurre al alfabeto dactilológico (deletreo manual). SoundMe identifica estas palabras y muestra la seña oficial de cada letra de manera secuencial.',
      ),
      _FaqItem(
        question: '¿Cómo cambio la velocidad con la que se muestran las señas?',
        category: 'Reproductor',
        answer:
            'En la pantalla del Traductor, justo debajo de la tarjeta donde se muestra la imagen de la seña, encontrarás el selector de velocidad. Puedes elegir entre:\n• Lento (3s): Perfecto para quienes están aprendiendo a ejecutar la seña.\n• Normal (2s): Ritmo estándar y cómodo para la mayoría de situaciones.\n• Rápido (1s): Para quienes ya dominan el vocabulario y desean una lectura más ágil.',
      ),
      _FaqItem(
        question: '¿Puedo usar la aplicación sin conexión a internet?',
        category: 'Diccionario y Ajustes',
        answer:
            '¡Sí! Todo el catálogo de señas, imágenes y el diccionario están almacenados localmente en tu dispositivo. La traducción por texto y la consulta del diccionario funcionan perfectamente en modo avión o sin cobertura móvil.',
      ),
      _FaqItem(
        question:
            '¿Cuál es la diferencia entre Traducción Flexible y Traducción Explícita?',
        category: 'Diccionario y Ajustes',
        answer:
            '• Traducción Flexible (Modo por defecto): Si escribes una palabra con faltas leves de ortografía o un sinónimo, el sistema lo corrige para ofrecerte la mejor seña disponible.\n• Traducción Explícita (Estricto): No aplica correcciones ni sustitución de sinónimos. Si la palabra exacta no existe en el diccionario oficial, pasará directamente al deletreo letra por letra. Puedes cambiar este ajuste en la pantalla de Opciones.',
      ),
      _FaqItem(
        question:
            '¿Las señas mostradas corresponden a la Lengua de Señas Dominicana oficial?',
        category: 'LSRD y Señas',
        answer:
            'Sí. SoundMe ha sido estructurado respetando la normativa y glosario de la Lengua de Señas Dominicana (LSRD), avalado bajo los lineamientos y documentación del Consejo Nacional de Discapacidad (CONADIS).',
      ),
      _FaqItem(
        question:
            '¿Cómo puedo aprender señas por temas o categorías específicas?',
        category: 'Diccionario y Ajustes',
        answer:
            'Puedes entrar a la sección de Diccionario (desde el menú de Inicio o desde la barra inferior) y navegar por los grupos temáticos: "Saludos Básicos", "Frases Comunes" y "Emergencias", o escribir cualquier palabra en el buscador para ver su postura y descripción gestual.',
        actionLabel: 'Abrir Diccionario',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DictionaryScreen()),
        ),
      ),
      _FaqItem(
        question:
            '¿Qué hago si una palabra no produce ninguna seña ni deletreo?',
        category: 'Traductor y Voz',
        answer:
            'Si envías una cadena con caracteres especiales no reconocidos o símbolos aislados, el sistema indicará "No se encontró coincidencia". Te sugerimos escribir la palabra con caracteres en español estándar (incluyendo ñ y tildes habituales) o usar una frase más concisa.',
      ),
      _FaqItem(
        question:
            '¿Cómo puedo reportar una seña incorrecta o solicitar una nueva?',
        category: 'Traductor y Voz',
        answer:
            'Agradecemos profundamente el aporte de la comunidad. Puedes escribirnos a soporte@soundme.org indicando la palabra, la descripción del gesto y, si es posible, una referencia visual. Nuestro equipo lingüístico revisará la solicitud para la próxima actualización del catálogo.',
      ),
    ];
  }
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String category;
  final String description;
  final List<String> steps;
  final String? actionLabel;
  final VoidCallback? onAction;

  _GuideItem({
    required this.icon,
    required this.title,
    required this.category,
    required this.description,
    required this.steps,
    this.actionLabel,
    this.onAction,
  });
}

class _FaqItem {
  final String question;
  final String category;
  final String answer;
  final String? actionLabel;
  final VoidCallback? onAction;

  _FaqItem({
    required this.question,
    required this.category,
    required this.answer,
    this.actionLabel,
    this.onAction,
  });
}
