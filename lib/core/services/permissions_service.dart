import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionsServiceProvider = Provider<PermissionsService>((ref) {
  return PermissionsService();
});

class PermissionsService {
  /// Solicita permisos de micrófono para la funcionalidad de STT
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Solicita permisos de notificaciones
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Verifica si el permiso de micrófono ha sido concedido
  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Verifica si el permiso de notificaciones ha sido concedido
  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  /// Abre la configuración de la app en caso de permisos denegados permanentemente
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
