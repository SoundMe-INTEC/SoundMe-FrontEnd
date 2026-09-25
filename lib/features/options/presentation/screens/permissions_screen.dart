import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/core/services/permissions_service.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _notificationsEnabled = false;
  bool _microphoneEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissionsService = ref.read(permissionsServiceProvider);
    final hasMic = await permissionsService.hasMicrophonePermission();
    final hasNotif = await permissionsService.hasNotificationPermission();

    if (mounted) {
      setState(() {
        _microphoneEnabled = hasMic;
        _notificationsEnabled = hasNotif;
      });
    }
  }

  Future<bool> _showPrePermissionDialog(String type) async {
    final title = type == 'micrófono'
        ? 'Acceso al Micrófono'
        : 'Permitir Notificaciones';
    final content = type == 'micrófono'
        ? 'Activar el micrófono te permitirá dictar frases y que la aplicación las traduzca automáticamente a lenguaje de señas. ¿Deseas conceder el permiso?'
        : 'Las notificaciones nos permitirán avisarte de nuevas señas agregadas al diccionario o recordatorios para que sigas aprendiendo. ¿Deseas habilitarlas?';

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            content: Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Ahora No',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Entendido',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _toggleMicrophone(bool value) async {
    final permissionsService = ref.read(permissionsServiceProvider);
    if (value) {
      final userAgreed = await _showPrePermissionDialog('micrófono');
      if (!userAgreed) return;

      final granted = await permissionsService.requestMicrophonePermission();
      if (!granted && mounted) {
        _showSettingsDialog('micrófono');
      } else if (mounted) {
        setState(() {
          _microphoneEnabled = granted;
        });
      }
    } else {
      _showSettingsDialog('micrófono');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final permissionsService = ref.read(permissionsServiceProvider);
    if (value) {
      final userAgreed = await _showPrePermissionDialog('notificaciones');
      if (!userAgreed) return;

      final granted = await permissionsService.requestNotificationPermission();
      if (!granted && mounted) {
        _showSettingsDialog('notificaciones');
      } else if (mounted) {
        setState(() {
          _notificationsEnabled = granted;
        });
      }
    } else {
      _showSettingsDialog('notificaciones');
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permiso Requerido',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        content: Text(
          'Para modificar el acceso a $permissionName, debes ir a la configuración de la aplicación.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(permissionsServiceProvider).openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Abrir Configuración',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: headerTopOffset - MediaQuery.paddingOf(context).top,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildToggleCard(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notificaciones',
                        subtitle: 'Activa avisos y novedades de la aplicación.',
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                      ),
                      const SizedBox(height: 14),
                      _buildToggleCard(
                        icon: Icons.mic_none_rounded,
                        title: 'Micrófono',
                        subtitle:
                            'Permite dictar frases para traducir a la Lengua de Señas Dominicana.',
                        value: _microphoneEnabled,
                        onChanged: _toggleMicrophone,
                      ),

                      const SizedBox(height: 48),

                      const Center(child: SoundMeLogo()),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(title: 'Permisos'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryNavy, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primaryNavy,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
