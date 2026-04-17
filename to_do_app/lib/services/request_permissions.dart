import 'package:permission_handler/permission_handler.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/services/permission_handler.dart';

class RequestPermissions {
  late PermissionHandler _permissionHandler;
  RequestPermissions() {
    _permissionHandler = PermissionHandler();
  }
  Future<void> requestNotificationPermission() async {
    // Implementation for requesting notification permission
    if (_permissionHandler.notificationPermission ==
        EnNotificationPermission.denied) {
      // Request permission logic here
      await NotificationService.requestNotificationPermission();
      await _permissionHandler.checkPermission();
    } else if (_permissionHandler.notificationPermission ==
        EnNotificationPermission.permanentlyDenied) {
      openAppSettings();
      await _permissionHandler.checkPermission();

      // Guide user to settings
    }
  }
}
