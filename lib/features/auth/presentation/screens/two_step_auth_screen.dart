import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:soundme_frontend/features/auth/data/auth_service.dart';
import 'package:soundme_frontend/core/utils/ui_helpers.dart';

class TwoStepAuthScreen extends ConsumerStatefulWidget {
  final String identification;
  final String password;
  final bool requiresOtp;

  const TwoStepAuthScreen({
    super.key,
    required this.identification,
    required this.password,
    this.requiresOtp = true,
  });

  @override
  ConsumerState<TwoStepAuthScreen> createState() => _TwoStepAuthScreenState();
}

class _TwoStepAuthScreenState extends ConsumerState<TwoStepAuthScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (int i = 0; i < 6; i++) {
      final index = i;
      _focusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[index].text.isEmpty &&
            index > 0) {
          _focusNodes[index - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        if (mounted) setState(() => _resendCooldown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getVerificationCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length > 1) {
        for (int i = 0; i < 6 && (index + i) < 6 && i < digits.length; i++) {
          _controllers[index + i].text = digits[i];
        }
        final nextIndex = (index + digits.length).clamp(0, 5);
        if (nextIndex < 5) {
          _focusNodes[nextIndex].requestFocus();
        } else {
          _focusNodes[5].unfocus();
        }
        if (_getVerificationCode().length == 6) {
          _verifyOtp();
        }
        return;
      }
    }

    if (value.isNotEmpty) {
      _controllers[index].text = value.substring(value.length - 1);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    if (_getVerificationCode().length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.checkCredentials(widget.identification, widget.password);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nuevo código enviado con éxito',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      setState(() => _resendCooldown = 60);
      _startTimer();
    } catch (e) {
      if (mounted) {
        UIHelpers.showError(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: _resendOtp,
          onCancel: () {},
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _getVerificationCode();
    if (code.length < 6) {
      UIHelpers.showError(
        context,
        message: 'Por favor ingresa los 6 dígitos del código.',
        onRetry: () => _focusNodes[0].requestFocus(),
        onCancel: () {},
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final isValid = await authService.login(widget.identification, widget.password, otp: code);

      if (isValid && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          (route) => false,
        );
      } else if (mounted) {
        throw Exception('El código OTP ingresado es inválido.');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showError(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: _verifyOtp,
          onCancel: () {
            for (var c in _controllers) {
              c.clear();
            }
            _focusNodes[0].requestFocus();
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 1. CABECERA FIJA CON BOTÓN DE REGRESAR
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HeaderWithBackButton(title: 'Verificación 2FA'),
            ),

            // 2. CONTENIDO PRINCIPAL SCROLLABLE (SIN COLISIÓN CON LOGO)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: headerTopOffset - MediaQuery.paddingOf(context).top),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      const SoundMeLogo(),
                      const SizedBox(height: 24),

                      // TARJETA DE VERIFICACIÓN 2FA
                      Container(
                        padding: const EdgeInsets.all(22.0),
                        decoration: BoxDecoration(
                          color: AppColors.cardFillColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.cardBorderColor),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                color: AppColors.primaryNavy,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Código de Seguridad',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingresa el código de 6 dígitos enviado a tu correo electrónico registrado.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // CASILLAS DE CÓDIGO OTP (6 DÍGITOS)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                    child: SizedBox(
                                      height: 60,
                                      child: TextField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryNavy,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: AppColors.cardBorderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: AppColors.cardBorderColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
                                          ),
                                        ),
                                        onChanged: (value) => _onDigitChanged(index, value),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 18),

                            // REENVIAR CÓDIGO
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '¿No recibiste el código? ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: (_resendCooldown > 0 || _isResending) ? null : _resendOtp,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: _isResending
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryNavy,
                                          ),
                                        )
                                      : Text(
                                          _resendCooldown > 0
                                              ? 'Reenviar en ${_resendCooldown}s'
                                              : 'Reenviar código',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _resendCooldown > 0
                                                ? AppColors.textSecondary
                                                : AppColors.primaryNavy,
                                            decoration: _resendCooldown > 0
                                                ? TextDecoration.none
                                                : TextDecoration.underline,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BOTÓN VERIFICAR
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryNavy.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Verificar',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        '© 2026 SoundMe. Todos los derechos reservados.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
