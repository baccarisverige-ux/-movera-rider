import 'package:flutter/widgets.dart';
import 'package:movera_rider/app/app.dart';
import 'package:movera_rider/core/logging/app_log.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.info('app.start');
  runApp(const MoveraApp());
}
