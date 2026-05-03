import 'package:permission_handler/permission_handler.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/services/permission_handler.dart';

class RequestPermissions {
  late PermissionHandler _permissionHandler;
  RequestPermissions() {
    _permissionHandler = PermissionHandler();
  }
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
