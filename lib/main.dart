import 'package:ddlcmm/ui.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ddlcmm/global.dart' as global;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (!global.modDir.existsSync()) {
    global.modDir.createSync();
  }
  if (!global.stagedDir.existsSync()) {
    global.stagedDir.createSync();
  }
  if (!global.storedDir.existsSync()) {
    global.storedDir.createSync();
  }
  runApp(const DDLCMM());
}

class DDLCMM extends StatelessWidget {
  const DDLCMM({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, fontFamily: 'Quicksand'),
      home: const ModList(),
    );
  }
}
