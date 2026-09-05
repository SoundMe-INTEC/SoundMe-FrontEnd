import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background.dart';
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
      } else if (digits.isNotEmpty) {
        _controllers[index].text = digits[digits.length - 1];
      }
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.checkCredentials(
        widget.identification,
        widget.password,
      );

      if (mounted) {
        UIHelpers.showSuccess(context, 'Nuevo código OTP enviado a tu correo.');
        setState(() {
          _resendCooldown = 60;
          for (var c in _controllers) {
            c.clear();
          }
        });
        _startTimer();
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showError(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: _resendOtp,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _getVerificationCode();
    if (code.length < 6) return;

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final success = await authService.login(
        widget.identification,
        widget.password,
        otp: code,
      );

      if (success && mounted) {
        UIHelpers.showSuccess(context, '¡Sesión iniciada correctamente!');
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
            // Limpiar inputs si cancela
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const HeaderBackground(),
          SafeArea(
            child: Stack(
              children: [
                // CONTENIDO SCROLLABLE SEGURO ANTE TECLADO
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              children: [
                                const Spacer(flex: 2),
                                const SizedBox(height: 50),
                                const SoundMeLogo(),
                                const Spacer(flex: 1),
                                const Text(
                                  'Ingresa el código que hemos enviado a tu correo electrónico.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textGray,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (index) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                        child: SizedBox(
                                          height: 70,
                                          child: TextField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 26,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryNavy,
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(6),
                                            ],
                                            decoration: InputDecoration(
                                              counterText: '',
                                              filled: true,
                                              fillColor: AppColors.inputFillColor,
                                              contentPadding: const EdgeInsets.symmetric(
                                                vertical: 18,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            onChanged: (value) => _onDigitChanged(index, value),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      '¿No recibiste el código? ',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: (_resendCooldown > 0 || _isResending)
                                          ? null
                                          : _resendOtp,
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
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _resendCooldown > 0
                                                    ? AppColors.textGray
                                                    : AppColors.primaryNavy,
                                                decoration: _resendCooldown > 0
                                                    ? TextDecoration.none
                                                    : TextDecoration.underline,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryNavy,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            'Verificar',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const Spacer(flex: 3),
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
                      ),
                    );
                  },
                ),

                // BOTÓN DE REGRESO (al final del Stack para recibir toques)
                Positioned(
                  top: 8,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      tooltip: 'Regresar',
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
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
