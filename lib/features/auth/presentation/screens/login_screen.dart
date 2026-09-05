import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/features/auth/data/auth_service.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/two_step_auth_screen.dart';
import 'package:soundme_frontend/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:soundme_frontend/core/utils/ui_helpers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _doLogin() async {
    setState(() => _isLoading = true);
    final identification = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final authService = ref.read(authServiceProvider);

      if (identification.isEmpty || password.isEmpty) {
        throw Exception('Por favor ingresa identificación y contraseña');
      }

      final requiresOtp = await authService.checkCredentials(
        identification,
        password,
      );
      if (!mounted) return;

      if (requiresOtp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TwoStepAuthScreen(
              identification: identification,
              password: password,
            ),
          ),
        );
      } else {
        final success = await authService.login(identification, password);
        if (!success) {
          throw Exception('No se pudo iniciar sesión.');
        }
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showError(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: _doLogin,
          onCancel: () {},
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 1. FONDO DECORATIVO
            const HeaderBackground(),

            // 2. CONTENIDO INTERACTIVO
            SafeArea(
              child: Column(
                children: [
                  // MARGEN SUPERIOR FIJO PARA EL LOGO
                  const SizedBox(height: 150),

                  // LOGO Y SUBTÍTULO (Se mantiene fijo arriba)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: SoundMeLogo(),
                  ),

                  // FORMULARIO CON SCROLL INDEPENDIENTE (Evita el overflow al abrir el teclado)
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Espaciado entre el logo y el formulario
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
                                      color: AppColors.textGray,
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
                                      color: AppColors.textGray,
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputFillColor,
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
                                      color: AppColors.textGray,
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
                                      color: AppColors.textGray,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputFillColor,
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
                                        color: AppColors.primaryNavy,
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
                                        color: AppColors.primaryNavy,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // BOTÓN INICIAR SESIÓN
                                SizedBox(
                                  width: double.infinity,
                                  height: 62,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _doLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryNavy,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                        : const Text(
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
                                      color: AppColors.primaryNavy,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),

                                // Espaciador dinámico inferior
                                const Spacer(flex: 2),

                                // COPYRIGHT FOOTER
                                const Text(
                                  '© 2026 SoundMe. Todos los derechos reservados.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppColors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}