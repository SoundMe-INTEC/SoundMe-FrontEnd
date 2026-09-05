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

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String _selectedSpeed = 'Normal (2s)';
  bool _isListening = false;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;

  // Translation state
  List<MockSignEntry> _matchedSigns = [];
  int _currentSignIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;
  String _statusText = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _suggestedSentences = [
    'HOLA CÓMO ESTÁS',
    'YO ESTOY MUY FELIZ',
    'GRACIAS POR TU AYUDA'
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted && _isListening) {
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.value = 0.0;
            });
            _translateText();
          }
        }
      },
      onError: (error) {
        if (mounted && _isListening) {
          setState(() {
            _isListening = false;
            _pulseController.stop();
            _pulseController.value = 0.0;
          });
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _playTimer?.cancel();
    _speechToText.stop();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _translateText([String? predefinedText]) async {
    if (_isListening) {
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
    if (text.isEmpty) return;

    _pausePlayback();

    final service = ref.read(mockupDataServiceProvider);
    final words = text.toUpperCase().split(RegExp(r'[\s,¿?¡!]+'));
    final List<MockSignEntry> found = [];
    final List<String> notFound = [];

    for (final word in words) {
      if (word.isEmpty) continue;
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
        _statusText = 'No se encontró coincidencia para: $text';
      } else {
        _statusText = 'Frase de ${found.length} señas';
        if (notFound.isNotEmpty) {
          _statusText += ' - Faltan: ${notFound.join(", ")}';
        }
      }
    });

    if (found.isNotEmpty) _startPlayback();
  }

  void _toggleMicrophone() async {
    if (!_speechEnabled) {
      bool init = await _speechToText.initialize();
      setState(() => _speechEnabled = init);
      if (!init) return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.value = 0.0;
      });
      _translateText();
    } else {
      setState(() {
        _isListening = true;
        _textController.clear();
        _pulseController.repeat(reverse: true);
      });
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
        },
        localeId: 'es_ES',
      );
    }
  }

  Duration get _playbackInterval {
    switch (_selectedSpeed) {
      case 'Rápido (1s)': return const Duration(seconds: 1);
      case 'Normal (2s)': return const Duration(seconds: 2);
      case 'Lento (3s)': default: return const Duration(seconds: 3);
    }
  }

  void _startPlayback() {
    _playTimer?.cancel();
    if (_matchedSigns.isEmpty) return;

    setState(() {
      _isPlaying = true;
      if (_currentSignIndex >= _matchedSigns.length - 1) {
        _currentSignIndex = 0; // restart if at the end
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
    if (_matchedSigns.isEmpty) return;
    _pausePlayback();
    setState(() {
      if (_currentSignIndex < _matchedSigns.length - 1) {
        _currentSignIndex++;
      }
    });
  }
  
  void _skipPrevious() {
    if (_matchedSigns.isEmpty) return;
    _pausePlayback();
    setState(() {
      if (_currentSignIndex > 0) {
        _currentSignIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSign = _matchedSigns.isNotEmpty ? _matchedSigns[_currentSignIndex] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: AdminHeaderBackground()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // REPRODUCTOR MULTIMEDIA
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardFillColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
                        ]
                      ),
                      child: currentSign != null
                          ? Column(
                              children: [
                                // Imagen de la Seña
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        currentSign.imagenAsset,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 80, color: AppColors.primaryNavy),
                                      ),
                                    ),
                                  ),
                                ),
                                // Textos descriptivos
                                Text(
                                  currentSign.palabra,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                ),
                                if (currentSign.gesto.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                    child: Text(
                                      currentSign.gesto,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textGray),
                                    ),
                                  ),
                                  
                                // CONTROLES DEL REPRODUCTOR
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    children: [
                                      // Slider Linea de tiempo
                                      Row(
                                        children: [
                                          Text('${_currentSignIndex + 1}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 4,
                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                              ),
                                              child: Slider(
                                                value: _currentSignIndex.toDouble(),
                                                min: 0,
                                                max: (_matchedSigns.length > 1 ? (_matchedSigns.length - 1).toDouble() : 1.0),
                                                activeColor: AppColors.primaryNavy,
                                                inactiveColor: Colors.grey.shade300,
                                                onChanged: (value) {
                                                  if (_matchedSigns.length <= 1) return;
                                                  _pausePlayback();
                                                  setState(() {
                                                    _currentSignIndex = value.toInt();
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          Text('${_matchedSigns.length}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                                        ],
                                      ),
                                      // Botones de reproducción y velocidad
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          DropdownButton<String>(
                                            value: _selectedSpeed,
                                            underline: const SizedBox(),
                                            icon: const Icon(Icons.speed, size: 18, color: AppColors.textGray),
                                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textGray),
                                            items: <String>['Lento (3s)', 'Normal (2s)', 'Rápido (1s)'].map((String value) {
                                              return DropdownMenuItem<String>(value: value, child: Text(value));
                                            }).toList(),
                                            onChanged: (newValue) {
                                              if (newValue != null) {
                                                setState(() => _selectedSpeed = newValue);
                                                if (_isPlaying) _startPlayback(); // restart timer with new speed
                                              }
                                            },
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.skip_previous_rounded, color: AppColors.primaryNavy),
                                                onPressed: _currentSignIndex > 0 ? _skipPrevious : null,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryNavy.withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.primaryNavy, size: 28),
                                                  onPressed: _isPlaying ? _pausePlayback : _startPlayback,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.skip_next_rounded, color: AppColors.primaryNavy),
                                                onPressed: _currentSignIndex < _matchedSigns.length - 1 ? _skipNext : null,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 60), // Balance to keep play buttons centered
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_translate, size: 80, color: AppColors.primaryNavy),
                                  SizedBox(height: 8),
                                  Text('Escribe o usa una sugerencia\npara traducir', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textGray)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // INPUT TEXT & MIC & CHIPS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // TEXT INPUT
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardFillColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                maxLines: 2,
                                minLines: 1,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: 'Escribe aquí para traducir...',
                                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppColors.textGray),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _translateText(),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                color: AppColors.primaryNavy,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded, color: Colors.white),
                                onPressed: () => _translateText(),
                                iconSize: 20,
                              ),
                            )
                          ],
                        ),
                      ),
                      
                      if (_statusText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _statusText,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryNavy),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // BIG MIC BUTTON
                      GestureDetector(
                        onTap: _toggleMicrophone,
                        child: ScaleTransition(
                          scale: _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _isListening ? Colors.red : AppColors.primaryNavy,
                              shape: BoxShape.circle,
                              boxShadow: _isListening ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 8,
                                )
                              ] : [
                                BoxShadow(
                                  color: AppColors.primaryNavy.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ORACIONES SUGERIDAS (CHIPS)
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _suggestedSentences.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                backgroundColor: Colors.white,
                                elevation: 1,
                                shadowColor: Colors.black12,
                                label: Text(
                                  _suggestedSentences[index],
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.primaryNavy,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () => _translateText(_suggestedSentences[index]),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
