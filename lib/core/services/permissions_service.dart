import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Conditional imports are handled via kIsWeb checks.
// On web, permission_handler is a no-op; we use a web-specific implementation.
import 'package:permission_handler/permission_handler.dart';

final permissionsServiceProvider = Provider<PermissionsService>((ref) {
  return PermissionsService();
});

class PermissionsService {
  /// Solicita permisos de micrófono para la funcionalidad de STT
  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) {
      return _requestWebMicPermission();
    }
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Solicita permisos de notificaciones
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) {
      return _requestWebNotificationPermission();
    }
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Verifica si el permiso de micrófono ha sido concedido
  Future<bool> hasMicrophonePermission() async {
    if (kIsWeb) {
      // On web, we can't check without requesting — return false as default
      return false;
    }
    return await Permission.microphone.isGranted;
  }

  /// Verifica si el permiso de notificaciones ha sido concedido
  Future<bool> hasNotificationPermission() async {
    if (kIsWeb) {
      return false;
    }
    return await Permission.notification.isGranted;
  }

  /// Abre la configuración de la app en caso de permisos denegados permanentemente
  Future<void> openSettings() async {
    if (kIsWeb) {
      // On web, we can't open app settings.
      return;
    }
    await openAppSettings();
  }

  // ---------------------------------------------------------------------------
  // Web-specific implementations
  // ---------------------------------------------------------------------------

  /// Requests microphone permission via the browser's getUserMedia API.
  Future<bool> _requestWebMicPermission() async {
    try {
      // Use eval-based approach to avoid dart:html import issues on mobile builds.
      // In a real web build, this would call navigator.mediaDevices.getUserMedia.
      // For now, we return true as a mockup to allow testing the flow.
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Requests notification permission via the browser's Notification API.
  Future<bool> _requestWebNotificationPermission() async {
    try {
      // Same approach — in web builds the Notification API would be called.
      // Mockup returns true for testing flow.
      return true;
    } catch (_) {
      return false;
    }
  }
}
