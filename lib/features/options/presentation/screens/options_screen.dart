import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/options/domain/models/translation_item.dart';
import 'package:soundme_frontend/features/options/presentation/screens/permissions_screen.dart';
import 'package:soundme_frontend/features/options/presentation/screens/translation_list_screen.dart';
import 'package:soundme_frontend/features/dictionary/presentation/screens/dictionary_screen.dart';

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  /// Converts [MockSignEntry] list to [TranslationItem] list for the UI.
  List<TranslationItem> _toTranslationItems(List<MockSignEntry> entries) {
    return entries
        .map((e) => TranslationItem(
              id: e.id.toString(),
              text: e.palabra,
              imageUrl: e.imagenAsset,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetings = ref.watch(mockGreetingsProvider);
    final commonPhrases = ref.watch(mockCommonPhrasesProvider);
    final emergencies = ref.watch(mockEmergenciesProvider);
    final allSigns = ref.watch(allMockSignsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Banner decorativo superior
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBackground(title: 'Opciones'),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),

                  // Tarjeta: Historial (now with real mockup data)
                  _buildOptionCard(
                    icon: Icons.history,
                    title: 'Historial',
                    subtitle: 'Revisa tus traducciones pasadas',
                    onTap: () {
                      // Use the first 10 mockup entries as "history"
                      final historyItems = allSigns.whenOrNull(
                        data: (signs) => _toTranslationItems(
                          signs.take(10).toList(),
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TranslationListScreen(
                            title: 'Historial',
                            items: historyItems ?? const [],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Bloque: Diccionario y Categorías
                  _buildDictionaryGroup(
                    context,
                    greetings: greetings,
                    commonPhrases: commonPhrases,
                    emergencies: emergencies,
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta: Notificaciones y Permisos
                  _buildOptionCard(
                    icon: Icons.notifications_none,
                    title: 'Notificaciones y Permisos',
                    subtitle: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PermissionsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Widget del Logo oficial de SoundMe
                  const Center(
                    child: SizedBox(
                      width: 290,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SoundMeLogo(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget reutilizable para tarjetas principales
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Icon(
          icon,
          color: iconColor ?? AppColors.primaryNavy,
          size: 36,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: titleColor ?? AppColors.primaryNavy,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: (titleColor ?? AppColors.primaryNavy).withAlpha(204),
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: iconColor ?? AppColors.primaryNavy,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  // Grupo colapsable / desplegado del Diccionario — now with real data
  Widget _buildDictionaryGroup(
    BuildContext context, {
    required AsyncValue<List<MockSignEntry>> greetings,
    required AsyncValue<List<MockSignEntry>> commonPhrases,
    required AsyncValue<List<MockSignEntry>> emergencies,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400, width: 0.8),
      ),
      child: Column(
        children: [
          // Cabecera del Diccionario
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DictionaryScreen(),
                ),
              );
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: AppColors.primaryNavy,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diccionario',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Busca las palabras/frases que gustes y su interpretación en señas (completo)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: AppColors.primaryNavy.withAlpha(204),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryNavy,
                  ),
                ],
              ),
            ),
          ),

          // Sub-elementos integrados — now loading real mockup data
          _buildSubCategoryItem(
            title: 'Saludos básicos',
            onTap: () {
              final items = greetings.whenOrNull(
                data: (data) => _toTranslationItems(data),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranslationListScreen(
                    title: 'Saludos Básicos',
                    items: items ?? const [],
                  ),
                ),
              );
            },
          ),
          _buildSubCategoryItem(
            title: 'Frases comunes',
            onTap: () {
              final items = commonPhrases.whenOrNull(
                data: (data) => _toTranslationItems(data),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranslationListScreen(
                    title: 'Frases Comunes',
                    items: items ?? const [],
                  ),
                ),
              );
            },
          ),
          _buildSubCategoryItem(
            title: 'Emergencias',
            isLast: true,
            onTap: () {
              final items = emergencies.whenOrNull(
                data: (data) => _toTranslationItems(data),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranslationListScreen(
                    title: 'Emergencias',
                    items: items ?? const [],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Ítem de subcategoría
  Widget _buildSubCategoryItem({
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.8),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryNavy,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.primaryNavy,
          size: 14,
        ),
        onTap: onTap,
      ),
    );
  }
}
