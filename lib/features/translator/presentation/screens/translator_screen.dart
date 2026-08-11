import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _textController = TextEditingController();
  String _selectedSpeed = 'Lento (3s)';
  bool _isListening = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 20),

                  // WIDGET SEÑALES (Área de Renderizado de Señas/Avatar)
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      color: AppColors.cardFillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.g_translate,
                        size: 120,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // WIDGET TRANSCRIPCIÓN / INPUT DE TEXTO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardFillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _textController,
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Esperando audio...',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              color: AppColors.textGray,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '¡También puedes escribir lo que deseas traducir!',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard, color: AppColors.primaryNavy),
                              onPressed: () {
                                // Foco al teclado
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BARRA DE CONTROLES (Reproducción y Velocidad)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botones de control de reproducción
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: AppColors.primaryNavy, size: 28),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause, color: AppColors.primaryNavy, size: 28),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop, color: AppColors.primaryNavy, size: 28),
                            onPressed: () {},
                          ),
                        ],
                      ),

                      // Dropdown / Selector de Velocidad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardFillColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedSpeed,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textGray),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                          items: <String>['Lento (3s)', 'Normal (2s)', 'Rápido (1s)']
                              .map((String value) {
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
                    onTap: () {
                      setState(() => _isListening = !_isListening);
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : AppColors.primaryNavy,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNavy.withAlpha(50),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 45,
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