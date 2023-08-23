import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:ddlcmm/global.dart' as global;

class ModUtils {
  void runGame() {
    windowManager.hide();
    Process.runSync(
        '${Directory.current.path.toString()}\\staged\\ddlc.exe', []);
    windowManager.show();
  }

  String getModData(selectedMod) {
    Map<String, dynamic> jsonData = selectedMod;
    List<String> data = [];
    jsonData.forEach((key, value) {
      if (key != 'Image') {
        data.add('$key: $value');
      }
    });
    String result = data.join('\n');
    return result;
  }

  void copyMod(String modName) {
    if (global.stagedDir.existsSync()) {
      global.stagedDir.deleteSync(recursive: true);
    }
    global.gameDir.createSync(recursive: true);

    final rootModDir = findrootModDir(Directory('mod\\$modName'));

    if (rootModDir != null) {
      rootModDir.listSync(recursive: true).forEach((entity) {
        if (entity is File) {
          final relativePath = entity.path.replaceFirst(rootModDir.path, '');
          final newPath = global.gameDir.path + relativePath;
          Directory(newPath).parent.createSync(recursive: true);
          entity.copySync(newPath);
        }
      });
    }

    global.storedDir.listSync(recursive: true).forEach((entity) {
      if (entity is File) {
        final relativePath =
            entity.path.replaceFirst(global.storedDir.path, '');
        final newPath = global.stagedDir.path + relativePath;
        if (!File(newPath).existsSync()) {
          entity.copySync(newPath);
        }
      } else if (entity is Directory) {
        final relativePath =
            entity.path.replaceFirst(global.storedDir.path, '');
        final newPath = global.stagedDir.path + relativePath;
        Directory(newPath).createSync(recursive: true);
      }
    });
  }

  Directory? findrootModDir(Directory modDirectory) {
    for (final extension in ['.rpa', '.rpyc', '.rpy']) {
      for (final file in modDirectory.listSync(recursive: true)) {
        if (file is File && file.path.endsWith(extension)) {
          return file.parent;
        }
      }
    }
    return null;
  }
}
