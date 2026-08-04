import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/widgets/header_background.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/two_step_auth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Constantes de estilo compartidas con HomeScreen
  static const Color primaryNavy = Color(0xFF002D62);
  static const Color textGray = Color(0xFF747474);
  static const Color inputFillColor = Color(0xFFE7EAEE);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. FONDO DECORATIVO
          const HeaderBackground(),

          // 2. CONTENIDO INTERACTIVO
          SafeArea(
            child: Stack(
              children: [

                // FORMULARIO PRINCIPAL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // LOGO Y SUBTÍTULO
                      const SizedBox(height: 60),
                      const SoundMeLogo(),

                      const Spacer(flex: 1),

                      // CAMPO: IDENTIFICACIÓN
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Identificación',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textGray,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'XXXXXXXXXXX',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: textGray,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // CAMPO: CONTRASEÑA
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Contraseña',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textGray,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          hintStyle: const TextStyle(
                            color: textGray,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: primaryNavy,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      // LINK: OLVIDASTE TU CONTRASEÑA
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Lógica de recuperación
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: primaryNavy,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BOTÓN INICIAR SESIÓN (Mismo estilo que botones del Home)
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TwoStepAuthScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // LINK DE AYUDA
                      TextButton(
                        onPressed: () {
                          // TODO: Lógica de ayuda
                        },
                        child: const Text(
                          '¿No eres Administrador? ¡Ayúdanos!',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: primaryNavy,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // COPYRIGHT FOOTER
                      const Text(
                        '© 2026 SoundMe. Todos los derechos reservados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: textGray,
                        ),
                      ),
                      const SizedBox(height: 16),
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