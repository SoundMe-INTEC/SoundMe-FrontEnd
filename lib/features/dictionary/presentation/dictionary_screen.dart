import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import '../data/mock_dictionary_repository.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'word_detail_screen.dart';

import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  late Future<void> _loadDataFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ContextualSense? _selectedContextSense;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = MockDictionaryRepository.loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(title: 'Diccionario Dominicano'),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: headerTopOffset - MediaQuery.paddingOf(context).top,
              ),
              child: FutureBuilder<void>(
                future: _loadDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryNavy,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar datos: ${snapshot.error}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.accentRed,
                        ),
                      ),
                    );
                  }

                  bool foundBySynonym = false;
                  String suggestedWordName = '';

                  final cleanQuery = _searchQuery.trim().toUpperCase();
                  ContextualHomonym? activeHomonym;

                  if (cleanQuery.isNotEmpty) {
                    for (final h in MockDictionaryRepository.contextualHomonyms) {
                      final hUpper = h.palabra.toUpperCase();
                      if (cleanQuery == hUpper ||
                          cleanQuery.contains(hUpper) ||
                          hUpper.contains(cleanQuery)) {
                        activeHomonym = h;
                        break;
                      }
                    }
                  }

                  // Si la consulta tiene varias palabras, detectar si alguna es una keyword de una acepción
                  if (activeHomonym != null && _selectedContextSense == null) {
                    final queryWords = cleanQuery.split(RegExp(r'\s+'));
                    if (queryWords.length > 1) {
                      for (final sense in activeHomonym.acepciones) {
                        for (final kw in sense.keywords) {
                          if (queryWords.contains(kw)) {
                            _selectedContextSense = sense;
                            break;
                          }
                        }
                      }
                    }
                  }

                  List<MockDictionaryWord> words;
                  if (_selectedContextSense != null) {
                    // Filtrar a la seña de la acepción seleccionada
                    final targetSign = _selectedContextSense!.sign.toUpperCase();
                    words = MockDictionaryRepository.mockWords.where((word) {
                      final wUpper = word.palabra.toUpperCase();
                      return wUpper == targetSign || wUpper.contains(targetSign);
                    }).toList();
                  } else if (activeHomonym != null) {
                    // Mostrar señas que coinciden con el homónimo O con cualquiera de sus acepciones
                    final targetSigns = activeHomonym.acepciones
                        .map((a) => a.sign.toUpperCase())
                        .toSet();
                    words = MockDictionaryRepository.mockWords.where((word) {
                      final wUpper = word.palabra.toUpperCase();
                      return wUpper.contains(activeHomonym!.palabra.toUpperCase()) ||
                          targetSigns.any((ts) => wUpper == ts || wUpper.contains(ts));
                    }).toList();
                  } else {
                    words = MockDictionaryRepository.mockWords.where((word) {
                      return word.palabra.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                    }).toList();
                  }

                  if (words.isEmpty && _searchQuery.isNotEmpty) {
                    final synWords = MockDictionaryRepository.mockWords.where((
                      word,
                    ) {
                      return word.sinonimos.any(
                        (syn) => syn.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      );
                    }).toList();

                    if (synWords.isNotEmpty) {
                      words = synWords;
                      foundBySynonym = true;
                      suggestedWordName = synWords.first.palabra;
                    }
                  }

                  return Column(
                    children: [
                      // BUSCADOR PÍLDORA ELEGANTE
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.cardFillColor,
                            borderRadius: BorderRadius.circular(27),
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                            ),
                            boxShadow: AppColors.softShadow,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 36,
                                child: Center(
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: AppColors.primaryNavy,
                                    size: 22,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                      _selectedContextSense = null;
                                    });
                                  },
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar palabra o seña...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: _searchQuery.isEmpty
                                    ? const SizedBox.shrink()
                                    : IconButton(
                                        tooltip: 'Borrar búsqueda',
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 32,
                                              height: 32,
                                            ),
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          color: AppColors.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _selectedContextSense = null;
                                          });
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (activeHomonym != null)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 4.0,
                          ),
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.primaryNavy.withValues(alpha: 0.18),
                            ),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.psychology_alt_rounded,
                                      color: AppColors.primaryNavy,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Palabra homógrafa: ${activeHomonym.palabra}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                        Text(
                                          'La seña cambia según el contexto en la oración:',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildSenseChip(
                                      label: 'Todas las señas',
                                      isSelected: _selectedContextSense == null,
                                      onTap: () {
                                        setState(() {
                                          _selectedContextSense = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ...activeHomonym.acepciones.map((sense) {
                                      final isSel = _selectedContextSense?.sentido == sense.sentido;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: _buildSenseChip(
                                          label: '${sense.sentido} ➡️ ${sense.sign}',
                                          isSelected: isSel,
                                          onTap: () {
                                            setState(() {
                                              _selectedContextSense = isSel ? null : sense;
                                            });
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              if (_selectedContextSense != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 16,
                                        color: AppColors.primaryNavy,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Ejemplo: "${_selectedContextSense!.ejemplo}"',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      if (foundBySynonym)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 4.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primaryNavy,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No se encontró "$_searchQuery", mostrando término relacionado: $suggestedWordName',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.primaryNavy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Expanded(
                        child: words.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardFillColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.search_off_rounded,
                                          size: 48,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No se encontraron señas para "$_searchQuery"'
                                            : 'No hay señas disponibles',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Intenta buscar por sinónimos o verifica la ortografía.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth >= 600) {
                                    return GridView.builder(
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                        vertical: 8.0,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 400,
                                            mainAxisExtent: 125,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 12,
                                          ),
                                      itemCount: words.length,
                                      itemBuilder: (context, index) {
                                        return _buildWordCard(
                                          context,
                                          words[index],
                                        );
                                      },
                                    );
                                  }
                                  return ListView.builder(
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 8.0,
                                    ),
                                    itemCount: words.length,
                                    itemBuilder: (context, index) {
                                      return _buildWordCard(
                                        context,
                                        words[index],
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, MockDictionaryWord word) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WordDetailScreen(word: word),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Hero(
                  tag: 'word_image_${word.id}',
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      border: Border.all(color: AppColors.cardBorderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: word.signEntry != null
                        ? SignImage(
                            sign: word.signEntry!,
                            fit: BoxFit.contain,
                            width: 76,
                            height: 76,
                          )
                        : word.imagePaths.isNotEmpty
                        ? Image.asset(word.imagePaths.first, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        word.palabra,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        word.descripcion.isNotEmpty
                            ? word.descripcion
                            : 'Sin descripción',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                        maxLines: word.matchedSense != null ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (word.matchedSense != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '💡 Sentido: ${word.matchedSense!.sentido}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primaryNavy,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenseChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryNavy
                : AppColors.primaryNavy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryNavy
                  : AppColors.cardBorderColor,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.primaryNavy,
            ),
          ),
        ),
      ),
    );
  }
}
