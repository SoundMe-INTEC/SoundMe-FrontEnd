import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
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

  Future<void> _toggleMicrophone(bool value) async {
    final permissionsService = ref.read(permissionsServiceProvider);
    if (value) {
      final granted = await permissionsService.requestMicrophonePermission();
      if (!granted && mounted) {
        _showSettingsDialog('micrófono');
      } else if (mounted) {
        setState(() {
          _microphoneEnabled = granted;
        });
      }
    } else {
      // Cannot revoke programmatically
      _showSettingsDialog('micrófono');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final permissionsService = ref.read(permissionsServiceProvider);
    if (value) {
      final granted = await permissionsService.requestNotificationPermission();
      if (!granted && mounted) {
        _showSettingsDialog('notificaciones');
      } else if (mounted) {
        setState(() {
          _notificationsEnabled = granted;
        });
      }
    } else {
      // Cannot revoke programmatically
      _showSettingsDialog('notificaciones');
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Requerido'),
        content: Text(
            'Para modificar el acceso a $permissionName, debes ir a la configuración de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(permissionsServiceProvider).openSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBackground(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          'PERMISOS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildToggleCard(
                          icon: Icons.notifications_none,
                          title: 'Notificaciones',
                          subtitle: 'Activa las notificaciones de la aplicación.',
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                        ),
                        const SizedBox(height: 16),
                        _buildToggleCard(
                          icon: Icons.mic_none,
                          title: 'Micrófono',
                          subtitle: 'Permite a la app usar tu micrófono.',
                          value: _microphoneEnabled,
                          onChanged: _toggleMicrophone,
                        ),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        SizedBox(height: 24),
                        SizedBox(
                          width: 270,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SoundMeLogo(),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryNavy,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: AppColors.primaryNavy.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primaryNavy,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}