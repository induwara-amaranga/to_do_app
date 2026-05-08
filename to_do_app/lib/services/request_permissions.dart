import 'package:permission_handler/permission_handler.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/providers/permission_handler.dart';

class RequestPermissions {
  late PermissionHandler _permissionHandler;
  RequestPermissions() {
    _permissionHandler = PermissionHandler();
  }

  /*there are two types to request permissions
      1. through android dialog(for denied or not granted permissions)
      2. through app settings (for permanently denied permissions)
  */
  Future<void> requestNotificationPermission() async {
    final current = await _permissionHandler.notificationPermission;
    if (current == EnNotificationPermission.denied) {
      await NotificationService.requestNotificationPermission();
      await _permissionHandler.checkPermission();
    } else if (current == EnNotificationPermission.permanentlyDenied) {
      openAppSettings();
      await _permissionHandler.checkPermission();
    }
  }
}
