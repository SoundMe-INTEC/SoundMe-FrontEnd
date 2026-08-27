import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final TextEditingController _textController = TextEditingController();
  String _selectedSpeed = 'Lento (3s)';
  bool _isListening = false;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;

  // Translation state
  List<MockSignEntry> _matchedSigns = [];
  int _currentSignIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted && _isListening) {
             setState(() { _isListening = false; });
             _translateText();
          }
        }
      },
      onError: (error) {
         if (mounted && _isListening) {
             setState(() { _isListening = false; });
         }
      }
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _playTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  /// Translates the input text by searching the mockup dictionary.
  Future<void> _translateText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final service = ref.read(mockupDataServiceProvider);

    // Split text into words and try to find each one
    final words = text.toUpperCase().split(RegExp(r'[\s,]+'));
    final List<MockSignEntry> found = [];
    final List<String> notFound = [];

    for (final word in words) {
      if (word.isEmpty) continue;

      // Try exact match strictly (no partial fallback)
      final exact = await service.findFlexible(word);
      if (exact != null) {
        found.add(exact);
      } else {
        notFound.add(word);
      }
    }

    setState(() {
      _matchedSigns = found;
      _currentSignIndex = 0;
      
      if (found.isEmpty) {
        _statusText = 'No se encontró coincidencia exacta para: $text';
      } else {
        _statusText = 'Frase encontrada (${found.length} señas)';
        if (notFound.isNotEmpty) {
          _statusText += ' - Faltan: ${notFound.join(", ")}';
        }
      }
    });

    // Auto-play if we found results
    if (found.isNotEmpty) {
      _startPlayback();
    }
  }

  /// Translates speech to text using the real microphone.
  void _toggleMicrophone() async {
    if (!_speechEnabled) {
      bool initialized = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
               setState(() { _isListening = false; });
               _translateText();
            }
          }
        },
        onError: (error) {
           if (mounted && _isListening) {
               setState(() { _isListening = false; });
           }
        }
      );
      setState(() {
        _speechEnabled = initialized;
      });
      if (!initialized) return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      _translateText();
    } else {
      setState(() {
        _isListening = true;
        _textController.clear();
      });
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
        },
        localeId: 'es_ES', // Assuming Spanish since app is in Spanish
      );
    }
  }

  /// Returns the playback interval based on selected speed.
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
    _stopPlayback();
    if (_matchedSigns.isEmpty) return;

    setState(() {
      _isPlaying = true;
      _currentSignIndex = 0;
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
          _stopPlayback();
        }
      });
    });
  }

  void _pausePlayback() {
    _playTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _stopPlayback() {
    _playTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentSignIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSign =
        _matchedSigns.isNotEmpty ? _matchedSigns[_currentSignIndex] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BANNER SUPERIOR DECORATIVO
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBackground(),
          ),

          // 2. CONTENIDO PRINCIPAL DE TRADUCCIÓN
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // WIDGET SEÑALES — Area de renderizado de señas
                  Flexible(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardFillColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: currentSign != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        currentSign.imagenAsset,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 80,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 8, left: 12, right: 12),
                                  child: Text(
                                    currentSign.palabra,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ),
                                if (currentSign.gesto.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8, left: 12, right: 12),
                                    child: Text(
                                      currentSign.gesto,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ),
                                if (_matchedSigns.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '${_currentSignIndex + 1} / ${_matchedSigns.length}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.g_translate,
                                    size: 80,
                                    color: AppColors.primaryNavy,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Escribe o habla\npara traducir',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // WIDGET TRANSCRIPCIÓN / INPUT DE TEXTO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardFillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _textController,
                          maxLines: 2,
                          minLines: 1,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Escribe aquí para traducir...',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: AppColors.textGray,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _translateText(),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _statusText.isNotEmpty
                                    ? _statusText
                                    : '¡También puedes escribir lo que deseas traducir!',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: _statusText.isNotEmpty
                                      ? AppColors.primaryNavy
                                      : AppColors.textGray,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_rounded,
                                  color: AppColors.primaryNavy),
                              onPressed: _translateText,
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BARRA DE CONTROLES (Reproducción y Velocidad)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botones de control de reproducción
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow,
                                color: AppColors.primaryNavy, size: 28),
                            onPressed:
                                _matchedSigns.isNotEmpty ? _startPlayback : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause,
                                color: AppColors.primaryNavy, size: 28),
                            onPressed:
                                _isPlaying ? _pausePlayback : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop,
                                color: AppColors.primaryNavy, size: 28),
                            onPressed:
                                _matchedSigns.isNotEmpty ? _stopPlayback : null,
                          ),
                        ],
                      ),

                      // Dropdown / Selector de Velocidad
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardFillColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedSpeed,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.textGray),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                          items: <String>[
                            'Lento (3s)',
                            'Normal (2s)',
                            'Rápido (1s)'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() => _selectedSpeed = newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // BOTÓN ESCUCHAR (Micrófono)
                  GestureDetector(
                    onTap: _toggleMicrophone,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isListening ? 100 : 80,
                      height: _isListening ? 100 : 80,
                      decoration: BoxDecoration(
                        color:
                            _isListening ? Colors.red : AppColors.primaryNavy,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? Colors.red
                                    : AppColors.primaryNavy)
                                .withAlpha(80),
                            blurRadius: _isListening ? 20 : 10,
                            spreadRadius: _isListening ? 4 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}