import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum EnNotificationPermission { granted, denied, permanentlyDenied, unknown }

class PermissionHandler extends ChangeNotifier {
  EnNotificationPermission _notificationPermission =
      EnNotificationPermission.denied;
  Future<EnNotificationPermission> get notificationPermission async {
    var state = await Permission.notification.status;
    _notificationPermission = convertStatus(state);
    return _notificationPermission;
  }

  EnNotificationPermission convertStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return EnNotificationPermission.granted;
      case PermissionStatus.denied:
        return EnNotificationPermission.denied;
      case PermissionStatus.permanentlyDenied:
        return EnNotificationPermission.permanentlyDenied;
      default:
        return EnNotificationPermission.unknown;
    }
  }

  Future checkPermission() async {
    _notificationPermission = await notificationPermission;
    notifyListeners();
  }

  // This class will handle permission requests and checks
}
