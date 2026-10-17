import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import '../data/mock_dictionary_repository.dart';

class WordDetailScreen extends StatefulWidget {
  final MockDictionaryWord word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  int _currentFrame = 0;
  Timer? _timer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Auto-play if there are multiple images
    if (widget.word.signEntry == null && widget.word.imagePaths.length > 1) {
      _togglePlayPause();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.word.signEntry != null) return;
    if (widget.word.imagePaths.length <= 1) return; // No animation needed

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (mounted) {
          setState(() {
            _currentFrame = (_currentFrame + 1) % widget.word.imagePaths.length;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMultipleFrames =
        widget.word.signEntry == null && widget.word.imagePaths.length > 1;
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(title: widget.word.palabra),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: headerTopOffset - MediaQuery.paddingOf(context).top,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Hero(
                        tag: 'word_image_${widget.word.id}',
                        child: Container(
                          width: double.infinity,
                          height: 280,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardFillColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                            ),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: widget.word.signEntry != null
                                ? SignImage(
                                    sign: widget.word.signEntry!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: 280,
                                  )
                                : widget.word.imagePaths.isNotEmpty
                                ? Image.asset(
                                    widget.word.imagePaths[_currentFrame],
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => const Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 70,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 70,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (hasMultipleFrames)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryNavy,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descripción',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.word.descripcion.isNotEmpty
                                ? widget.word.descripcion
                                : 'Sin descripción disponible.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Gesto (Cómo se hace)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.cardFillColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.cardBorderColor,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primaryNavy,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.word.gesto.isNotEmpty
                                        ? widget.word.gesto
                                        : 'No hay instrucciones del gesto disponibles.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: AppColors.primaryNavy,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.word.contextualHomonym != null) ...[
                            const SizedBox(height: 24),
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
                                  child: Text(
                                    'Significados según el contexto',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Esta palabra es homógrafa en español ("${widget.word.contextualHomonym!.palabra}"). En Lengua de Señas Dominicana (LSRD), la seña cambia según el sentido de la frase:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...widget.word.contextualHomonym!.acepciones.map((sense) {
                              final isCurrent = sense.sign.trim().toUpperCase() == widget.word.palabra.trim().toUpperCase();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primaryNavy.withValues(alpha: 0.05)
                                      : AppColors.cardFillColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrent ? AppColors.primaryNavy : AppColors.cardBorderColor,
                                    width: isCurrent ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isCurrent
                                              ? Icons.check_circle_rounded
                                              : Icons.radio_button_unchecked_rounded,
                                          color: isCurrent ? AppColors.primaryNavy : AppColors.textSecondary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${sense.sentido} ➡️ Seña: ${sense.sign}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryNavy,
                                            ),
                                          ),
                                        ),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryNavy,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Seña actual',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      sense.descripcion,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppColors.textDark,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (sense.ejemplo.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Ejemplo: "${sense.ejemplo}"',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (!isCurrent) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () {
                                            MockDictionaryWord? altWord;
                                            for (final w in MockDictionaryRepository.mockWords) {
                                              if (w.palabra.trim().toUpperCase() == sense.sign.trim().toUpperCase()) {
                                                altWord = w;
                                                break;
                                              }
                                            }
                                            if (altWord != null) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => WordDetailScreen(word: altWord!),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                          label: Text('Ver seña de "${sense.sign}"'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primaryNavy,
                                            textStyle: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
