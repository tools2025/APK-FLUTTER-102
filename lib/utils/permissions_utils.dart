import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [
    Permission.storage,
    Permission.notification,
    Permission.manageExternalStorage,
  ].request();
}