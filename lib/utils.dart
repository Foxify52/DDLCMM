import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:ddlcmm/global.dart' as global;

class ModUtils {
  void runGame() {
    windowManager.hide();
    Process.runSync(
      '${Directory.current.path.toString()}\\staged\\ddlc.exe',
      <String>[],
    );
    windowManager.show();
  }

  List<String> getModData(Map<String, dynamic> selectedMod) {
    Map<String, dynamic> jsonData = selectedMod;
    List<String> data = <String>[];
    jsonData.forEach((String key, dynamic value) {
      data.add(value);
    });
    return data;
  }

  void copyMod(String modName) {
    if (global.stagedDir.existsSync()) {
      global.stagedDir.deleteSync(recursive: true);
    }
    global.gameDir.createSync(recursive: true);

    final Directory? rootModDir = findrootModDir(Directory('mod\\$modName'));

    if (rootModDir != null) {
      rootModDir.listSync(recursive: true).forEach((FileSystemEntity entity) {
        if (entity is File) {
          final String relativePath =
              entity.path.replaceFirst(rootModDir.path, '');
          final String newPath = global.gameDir.path + relativePath;
          Directory(newPath).parent.createSync(recursive: true);
          entity.copySync(newPath);
        }
      });
    }

    global.storedDir
        .listSync(recursive: true)
        .forEach((FileSystemEntity entity) {
      if (entity is File) {
        final String relativePath =
            entity.path.replaceFirst(global.storedDir.path, '');
        final String newPath = global.stagedDir.path + relativePath;
        if (!File(newPath).existsSync()) {
          entity.copySync(newPath);
        }
      } else if (entity is Directory) {
        final String relativePath =
            entity.path.replaceFirst(global.storedDir.path, '');
        final String newPath = global.stagedDir.path + relativePath;
        Directory(newPath).createSync(recursive: true);
      }
    });
  }

  Directory? findrootModDir(Directory modDirectory) {
    for (final String extension in <String>['.rpa', '.rpyc', '.rpy']) {
      for (final FileSystemEntity file
          in modDirectory.listSync(recursive: true)) {
        if (file is File && file.path.endsWith(extension)) {
          return file.parent;
        }
      }
    }
    return null;
  }
}
