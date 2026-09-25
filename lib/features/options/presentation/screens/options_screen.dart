import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/services/translation_history_storage.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/options/domain/models/translation_item.dart';
import 'package:soundme_frontend/features/options/presentation/screens/permissions_screen.dart';
import 'package:soundme_frontend/features/options/presentation/screens/translation_list_screen.dart';
import 'package:soundme_frontend/core/providers/settings_provider.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';
import 'package:soundme_frontend/features/help/presentation/screens/help_faq_screen.dart';

import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  List<TranslationItem> _toTranslationItems(List<MockSignEntry> entries) {
    return entries
        .map(
          (e) => TranslationItem(
            id: e.id.toString(),
            text: e.palabra,
            imageUrl: e.imagenAsset,
            sign: e,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetings = ref.watch(mockGreetingsProvider);
    final commonPhrases = ref.watch(mockCommonPhrasesProvider);
    final emergencies = ref.watch(mockEmergenciesProvider);
    final isExplicit = ref.watch(explicitTranslationProvider);
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(title: 'Opciones'),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: headerTopOffset - MediaQuery.paddingOf(context).top,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Tarjeta: Historial
                    _buildOptionCard(
                      icon: Icons.history_rounded,
                      title: 'Historial',
                      subtitle: 'Revisa tus traducciones pasadas',
                      onTap: () async {
                        final historyEntries = await TranslationHistoryStorage()
                            .getRecentTranslations(limit: 20);

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TranslationListScreen(
                              title: 'Historial',
                              items: historyEntries
                                  .map(
                                    (entry) => TranslationItem(
                                      id: entry.id,
                                      text: entry.text,
                                      imageUrl: '',
                                      signsInOrder: entry.signsInOrder,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Bloque: Diccionario y Categorías
                    _buildDictionaryGroup(
                      context,
                      greetings: greetings,
                      commonPhrases: commonPhrases,
                      emergencies: emergencies,
                    ),

                    const SizedBox(height: 14),

                    // Tarjeta: Configuración de Modo de Traducción
                    _buildExplicitTranslationCard(context, ref, isExplicit),

                    const SizedBox(height: 14),

                    // Tarjeta: Notificaciones y Permisos
                    _buildOptionCard(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notificaciones y Permisos',
                      subtitle: 'Configura permisos de micrófono y avisos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PermissionsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Tarjeta: Ayuda y Preguntas Frecuentes
                    _buildOptionCard(
                      icon: Icons.help_outline_rounded,
                      title: 'Ayuda y Preguntas Frecuentes',
                      subtitle: 'Guía de uso, controles y dudas comunes',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpFaqScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    const Center(child: SoundMeLogo()),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primaryNavy,
              size: 26,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: titleColor ?? AppColors.primaryNavy,
            ),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: iconColor ?? AppColors.primaryNavy,
            size: 16,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildDictionaryGroup(
    BuildContext context, {
    required AsyncValue<List<MockSignEntry>> greetings,
    required AsyncValue<List<MockSignEntry>> commonPhrases,
    required AsyncValue<List<MockSignEntry>> emergencies,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
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
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primaryNavy,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diccionario',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Términos dominicanos organizados por categorías',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryNavy,
                  ),
                ],
              ),
            ),
          ),

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

  Widget _buildSubCategoryItem({
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final borderRadius = isLast
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          )
        : BorderRadius.zero;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cardBorderColor, width: 0.8),
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 2,
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.primaryNavy,
            size: 14,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildExplicitTranslationCard(
    BuildContext context,
    WidgetRef ref,
    bool isExplicit,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.spellcheck_rounded,
                color: AppColors.primaryNavy,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traducción Explícita',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isExplicit
                        ? 'Modo estricto: Solo coincidencias exactas.'
                        : 'Modo flexible: Corrige erratas y busca sinónimos.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isExplicit,
              activeTrackColor: AppColors.primaryNavy,
              onChanged: (val) {
                ref
                    .read(translationSettingsProvider.notifier)
                    .setExplicitTranslation(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
