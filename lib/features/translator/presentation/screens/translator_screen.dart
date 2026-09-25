import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/providers/settings_provider.dart';
import 'package:soundme_frontend/core/services/translation_history_storage.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/help/presentation/screens/help_faq_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});
  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedSpeed = 'Normal (2s)';
  bool _isListening = false;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  final TranslationHistoryStorage _historyStorage = TranslationHistoryStorage();

  // Translation state
  List<MockSignEntry> _matchedSigns = [];
  int _currentSignIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;
  Timer? _debounceTimer;
  Timer? _silenceTimer;
  String _statusText = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _suggestedSentences = [
    'HOLA CÓMO ESTÁS',
    'YO ESTOY MUY FELIZ',
    'GRACIAS POR TU AYUDA',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _silenceTimer?.cancel();
            if (mounted && _isListening) {
              _stopListeningAndTranslate();
            }
          }
        },
        onError: (error) {
          _silenceTimer?.cancel();
          if (mounted && _isListening) {
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.value = 0.0;
            });
          }
        },
      );
    } catch (_) {
      _speechEnabled = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _debounceTimer?.cancel();
    _focusNode.dispose();
    _textController.dispose();
    _playTimer?.cancel();
    if (_isListening || _speechToText.isListening) {
      _speechToText.stop();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    final text = value.trim();
    if (text.isEmpty) {
      _pausePlayback();
      setState(() {
        _matchedSigns = [];
        _currentSignIndex = 0;
        _statusText = '';
      });
      return;
    }

    setState(() {
      _statusText = '';
    });
  }

  Future<void> _translateText([
    String? predefinedText,
    bool unfocus = true,
  ]) async {
    _debounceTimer?.cancel();
    _silenceTimer?.cancel();
    if (unfocus) {
      _focusNode.unfocus();
    }

    if (_isListening || _speechToText.isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.value = 0.0;
      });
    }

    if (predefinedText != null) {
      _textController.text = predefinedText;
    }
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _pausePlayback();
      setState(() {
        _matchedSigns = [];
        _currentSignIndex = 0;
        _statusText = '';
      });
      return;
    }

    _pausePlayback();

    final service = ref.read(mockupDataServiceProvider);
    final isExplicit = ref.read(explicitTranslationProvider);
    final result = await service.translatePhrase(text, explicit: isExplicit);

    if (!mounted) {
      return;
    }

    if (result.matchedSigns.isNotEmpty) {
      await _historyStorage.saveTranslation(
        text,
        signsInOrder: result.matchedSigns.map((sign) => sign.palabra).toList(),
      );
    }

    setState(() {
      _matchedSigns = result.matchedSigns;
      _currentSignIndex = 0;
      if (result.matchedSigns.isEmpty) {
        _statusText = 'No se encontró coincidencia para: "$text"';
      } else {
        _statusText =
            'Traducción: ${result.matchedSigns.length} ${result.matchedSigns.length == 1 ? "seña" : "señas"}';
        if (result.spelledWords.isNotEmpty) {
          _statusText += ' (deletreo: ${result.spelledWords.join(", ")})';
        }
        if (result.notFoundWords.isNotEmpty) {
          _statusText +=
              ' - No encontradas: ${result.notFoundWords.join(", ")}';
        }
      }
    });

    if (result.matchedSigns.isNotEmpty) {
      _startPlayback();
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      if ((_isListening || _speechToText.isListening) && mounted) {
        _stopListeningAndTranslate();
      }
    });
  }

  Future<void> _stopListeningAndTranslate() async {
    _silenceTimer?.cancel();
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.value = 0.0;
      });
      await _translateText(null, true);
    }
  }

  void _toggleMicrophone() async {
    _focusNode.unfocus();

    // Si ya se está escuchando o el motor reporta listening, DETENER y ENVIAR AUTOMÁTICAMENTE
    if (_isListening || _speechToText.isListening) {
      await _stopListeningAndTranslate();
      return;
    }

    // Inicializar si no estaba listo
    if (!_speechEnabled) {
      bool init = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _silenceTimer?.cancel();
            if (mounted && _isListening) {
              _stopListeningAndTranslate();
            }
          }
        },
        onError: (error) {
          _silenceTimer?.cancel();
          if (mounted && _isListening) {
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.value = 0.0;
            });
          }
        },
      );
      if (mounted) {
        setState(() => _speechEnabled = init);
      }
      if (!init) {
        return;
      }
    }

    // Iniciar escucha
    setState(() {
      _isListening = true;
      _textController.clear();
      _pulseController.repeat(reverse: true);
    });
    _resetSilenceTimer();

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
          _resetSilenceTimer();

          // Si el resultado es final, auto-enviar inmediatamente
          if (result.finalResult) {
            _stopListeningAndTranslate();
          }
        }
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Duration get _playbackInterval {
    switch (_selectedSpeed) {
      case 'Rápido (1s)':
        return const Duration(seconds: 1);
      case 'Normal (2s)':
        return const Duration(seconds: 2);
      case 'Lento (3s)':
      default:
        return const Duration(seconds: 3);
    }
  }

  void _startPlayback() {
    _playTimer?.cancel();
    if (_matchedSigns.isEmpty) {
      return;
    }

    setState(() {
      _isPlaying = true;
      if (_currentSignIndex >= _matchedSigns.length - 1) {
        _currentSignIndex = 0;
      }
    });

    _playTimer = Timer.periodic(_playbackInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentSignIndex < _matchedSigns.length - 1) {
          _currentSignIndex++;
        } else {
          _pausePlayback();
        }
      });
    });
  }

  void _pausePlayback() {
    _playTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _skipNext() {
    if (_matchedSigns.isEmpty) {
      return;
    }
    _pausePlayback();
    setState(() {
      if (_currentSignIndex < _matchedSigns.length - 1) {
        _currentSignIndex++;
      }
    });
  }

  void _skipPrevious() {
    if (_matchedSigns.isEmpty) {
      return;
    }
    _pausePlayback();
    setState(() {
      if (_currentSignIndex > 0) {
        _currentSignIndex--;
      }
    });
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.primaryNavy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Guía Rápida del Traductor',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildHelpQuickItem(
                    icon: Icons.mic_rounded,
                    title: 'Traducción por Voz',
                    description:
                        'Toca el micrófono central y habla con claridad. Tras 3 segundos de pausa, se traducirá automáticamente.',
                  ),
                  _buildHelpQuickItem(
                    icon: Icons.keyboard_alt_outlined,
                    title: 'Traducción por Texto',
                    description:
                        'Escribe tu mensaje en la caja inferior o pulsa una sugerencia rápida para ver la secuencia de señas.',
                  ),
                  _buildHelpQuickItem(
                    icon: Icons.speed_rounded,
                    title: 'Velocidad y Controles',
                    description:
                        'Usa play/pausa y flechas para analizar cada seña. Regula el ritmo en Lento (3s), Normal (2s) o Rápido (1s).',
                  ),
                  _buildHelpQuickItem(
                    icon: Icons.spellcheck_rounded,
                    title: 'Deletreo Dactilológico',
                    description:
                        'Las palabras sin seña oficial directa en LSRD se mostrarán deletreadas letra a letra con el abecedario en señas.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpFaqScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 20),
                      label: const Text(
                        'Ver Guía Completa y FAQ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpQuickItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cardFillColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSign = _matchedSigns.isNotEmpty
        ? _matchedSigns[_currentSignIndex]
        : null;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardBottom > 0 || _focusNode.hasFocus;
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AdminHeaderBackground(
                title: 'Traductor',
                trailing: IconButton(
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Ayuda del Traductor',
                  onPressed: _showHelpSheet,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: headerTopOffset - MediaQuery.paddingOf(context).top,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxHeight < 650;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),

                            // REPRODUCTOR MULTIMEDIA RESPONSIVO
                            Container(
                              constraints: BoxConstraints(
                                minHeight: isSmallScreen ? 200 : 250,
                                maxHeight: isSmallScreen ? 280 : 340,
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.cardFillColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.cardBorderColor,
                                ),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: LayoutBuilder(
                                builder: (context, playerConstraints) {
                                  if (currentSign == null) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryNavy
                                                    .withValues(alpha: 0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.g_translate_rounded,
                                                size: 48,
                                                color: AppColors.primaryNavy,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Escribe o usa el micrófono\npara comenzar la traducción',
                                              textAlign: TextAlign.center,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textDark,
                                                    height: 1.3,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Traducción a Lengua de Señas Dominicana',
                                              textAlign: TextAlign.center,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final bool isCompact =
                                      playerConstraints.maxHeight < 280;

                                  return Column(
                                    children: [
                                      // Imagen de la Seña
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.04),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: SignImage(
                                                sign: currentSign,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Textos descriptivos
                                      Text(
                                        currentSign.palabra,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: isCompact ? 18 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                      if (currentSign.categoria == 'Deletreo' ||
                                          currentSign.infoAdicional ==
                                              'Deletreo')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentRed
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Deletreo Dactilológico',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.accentRed,
                                                  ),
                                            ),
                                          ),
                                        )
                                      else if (currentSign.gestoFacial !=
                                              null &&
                                          currentSign.gestoFacial!.isNotEmpty &&
                                          currentSign.gestoFacial != 'Neutral')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryNavy
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Gesto facial: ${currentSign.gestoFacial}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.primaryNavy,
                                                  ),
                                            ),
                                          ),
                                        ),

                                      // CONTROLES DEL REPRODUCTOR
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 8.0,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Slider Linea de tiempo
                                            Row(
                                              children: [
                                                Text(
                                                  '${_currentSignIndex + 1}',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                ),
                                                Expanded(
                                                  child: SliderTheme(
                                                    data: SliderTheme.of(context).copyWith(
                                                      trackHeight: 4,
                                                      thumbShape:
                                                          const RoundSliderThumbShape(
                                                            enabledThumbRadius:
                                                                6,
                                                          ),
                                                      overlayShape:
                                                          const RoundSliderOverlayShape(
                                                            overlayRadius: 14,
                                                          ),
                                                    ),
                                                    child: Slider(
                                                      value: _currentSignIndex
                                                          .toDouble(),
                                                      min: 0,
                                                      max:
                                                          (_matchedSigns
                                                                  .length >
                                                              1
                                                          ? (_matchedSigns
                                                                        .length -
                                                                    1)
                                                                .toDouble()
                                                          : 1.0),
                                                      activeColor:
                                                          AppColors.primaryNavy,
                                                      inactiveColor:
                                                          Colors.grey.shade300,
                                                      onChanged: (value) {
                                                        if (_matchedSigns
                                                                .length <=
                                                            1) {
                                                          return;
                                                        }
                                                        _pausePlayback();
                                                        setState(() {
                                                          _currentSignIndex =
                                                              value.toInt();
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${_matchedSigns.length}',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            // Botones de reproducción y velocidad
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                DropdownButton<String>(
                                                  value: _selectedSpeed,
                                                  underline: const SizedBox(),
                                                  icon: const Icon(
                                                    Icons.speed_rounded,
                                                    size: 18,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                  items:
                                                      <String>[
                                                        'Lento (3s)',
                                                        'Normal (2s)',
                                                        'Rápido (1s)',
                                                      ].map((String value) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                  onChanged: (newValue) {
                                                    if (newValue != null) {
                                                      setState(
                                                        () => _selectedSpeed =
                                                            newValue,
                                                      );
                                                      if (_isPlaying) {
                                                        _startPlayback();
                                                      }
                                                    }
                                                  },
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .skip_previous_rounded,
                                                        color: AppColors
                                                            .primaryNavy,
                                                      ),
                                                      onPressed:
                                                          _currentSignIndex > 0
                                                          ? _skipPrevious
                                                          : null,
                                                    ),
                                                    Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: AppColors
                                                                .primaryNavy,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: IconButton(
                                                        icon: Icon(
                                                          _isPlaying
                                                              ? Icons
                                                                    .pause_rounded
                                                              : Icons
                                                                    .play_arrow_rounded,
                                                          color: Colors.white,
                                                          size: 26,
                                                        ),
                                                        onPressed: _isPlaying
                                                            ? _pausePlayback
                                                            : _startPlayback,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.skip_next_rounded,
                                                        color: AppColors
                                                            .primaryNavy,
                                                      ),
                                                      onPressed:
                                                          _currentSignIndex <
                                                              _matchedSigns
                                                                      .length -
                                                                  1
                                                          ? _skipNext
                                                          : null,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 48),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // INPUT TEXT & MIC & CHIPS
                            Column(
                              children: [
                                // TEXT INPUT
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardFillColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.cardBorderColor,
                                    ),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _textController,
                                          focusNode: _focusNode,
                                          maxLines: 2,
                                          minLines: 1,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textDark,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _isListening
                                                ? 'Escuchando tu voz...'
                                                : 'Escribe aquí para traducir...',
                                            hintStyle:
                                                GoogleFonts.plusJakartaSans(
                                                  fontSize: 15,
                                                  color: _isListening
                                                      ? AppColors.accentRed
                                                      : AppColors.textSecondary,
                                                  fontWeight: _isListening
                                                      ? FontWeight.bold
                                                      : FontWeight.w400,
                                                ),
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                          onChanged: _onTextChanged,
                                          onSubmitted: (_) =>
                                              _translateText(null, true),
                                        ),
                                      ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryNavy,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _translateText(null, true),
                                          iconSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (_statusText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _statusText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // BIG MIC BUTTON (CON ANIMACIÓN DE PULSO Y AUTO-ENVÍO)
                                Column(
                                  children: [
                                    GestureDetector(
                                      key: const Key('translator_mic_button'),
                                      onTap: _toggleMicrophone,
                                      child: ScaleTransition(
                                        scale: _isListening
                                            ? _pulseAnimation
                                            : const AlwaysStoppedAnimation(1.0),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          width: _isListening ? 82 : 72,
                                          height: _isListening ? 82 : 72,
                                          decoration: BoxDecoration(
                                            color: _isListening
                                                ? AppColors.accentRed
                                                : AppColors.primaryNavy,
                                            shape: BoxShape.circle,
                                            boxShadow: _isListening
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.accentRed
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      blurRadius: 24,
                                                      spreadRadius: 8,
                                                    ),
                                                    BoxShadow(
                                                      color: AppColors.accentRed
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 36,
                                                      spreadRadius: 16,
                                                    ),
                                                  ]
                                                : [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .primaryNavy
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                          ),
                                          child: Icon(
                                            _isListening
                                                ? Icons.mic
                                                : Icons.mic_none_rounded,
                                            color: Colors.white,
                                            size: _isListening ? 40 : 34,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isListening
                                          ? 'Escuchando... Toca para detener y enviar'
                                          : 'Toca el micrófono para dictar',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: _isListening
                                            ? AppColors.accentRed
                                            : AppColors.textSecondary,
                                        fontWeight: _isListening
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // ORACIONES SUGERIDAS (CHIPS)
                                SizedBox(
                                  height: 38,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _suggestedSentences.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: ActionChip(
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(
                                            color: AppColors.cardBorderColor,
                                          ),
                                          elevation: 1,
                                          shadowColor: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          label: Text(
                                            _suggestedSentences[index],
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppColors.primaryNavy,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          onPressed: () => _translateText(
                                            _suggestedSentences[index],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: isKeyboardOpen ? 8 : 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
