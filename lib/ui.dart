import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddlcmm/global.dart' as global;
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class ModList extends StatefulWidget {
  const ModList({Key? key}) : super(key: key);

  @override
  State<ModList> createState() => _ModListState();
}

class _ModListState extends State<ModList> {
  late List<Map<String, dynamic>> _mods;
  Map<String, dynamic>? _selectedMod;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _mods = <Map<String, dynamic>>[];
    _initializeMods();
  }

  Future<void> _initializeMods() async {
    final Iterable<Directory> modFolders =
        global.modDir.listSync().whereType<Directory>();
    _mods = modFolders.map((Directory folder) {
      final String folderName = folder.path.split('/').last;
      final File jsonFile = File('$folderName.json');

      if (!jsonFile.existsSync()) {
        jsonFile
          ..createSync()
          ..writeAsStringSync(
            json.encode(<String, String>{
              'Name': folderName.replaceAll('mod\\', ''),
              'Description': 'Placeholder',
              'Author': 'Placeholder',
              'Version': '1.0.0',
              'Image': 'assets/Logo.webp',
              'Source': '',
            }),
          );
      }
      return json.decode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
    }).toList();

    _prefs = await SharedPreferences.getInstance();
    final String? savedModName = _prefs.getString('saved');
    setState(() {
      _selectedMod = savedModName != null
          ? _mods.firstWhere(
              (Map<String, dynamic> mod) => mod['Name'] == savedModName,
              orElse: () {
                _prefs.remove('saved');
                return <String, dynamic>{};
              },
            )
          : null;
    });
  }

  void _runGame() {
    windowManager.hide();
    try {
      String exePath =
          '${Directory.current.path}${Platform.pathSeparator}staged${Platform.pathSeparator}DDLC.exe';

      final Directory stagedDir = Directory(
        '${Directory.current.path}${Platform.pathSeparator}staged',
      );
      if (stagedDir.existsSync()) {
        List<FileSystemEntity> exeFiles = <FileSystemEntity>[];
        for (final FileSystemEntity entity in stagedDir.listSync()) {
          if (entity is File && entity.path.endsWith('.exe')) {
            exeFiles.add(entity);
          }
        }

        if (exeFiles.isNotEmpty) {
          exeFiles.sort(
            (FileSystemEntity a, FileSystemEntity b) =>
                a.path.length.compareTo(b.path.length),
          );

          if (exeFiles[0].path.split(Platform.pathSeparator).last !=
              'DDLC.exe') {
            exePath = exeFiles[0].path;
          } else if (exeFiles.length > 1) {
            exePath = exeFiles[1].path;
          }
        }
      }

      Process.runSync(
        exePath,
        <String>[],
      );
    } catch (e) {
      windowManager.show();
      _showInfoMessage('Error running game: $e');
    }
    windowManager.show();
  }

  List<String> _getModData(Map<String, dynamic> selectedMod) {
    return selectedMod.values.map((dynamic value) => value.toString()).toList();
  }

  void _copyMod(String modName) {
    if (global.stagedDir.existsSync()) {
      global.stagedDir.deleteSync(recursive: true);
    }
    global.gameDir.createSync(recursive: true);
    final Directory modDir = Directory('mod${Platform.pathSeparator}$modName');

    if (modDir.existsSync()) {
      bool containsExe = false;
      for (final FileSystemEntity entity in modDir.listSync()) {
        if (entity is File && entity.path.endsWith('.exe')) {
          containsExe = true;
          break;
        }
      }

      if (containsExe) {
        for (final FileSystemEntity entity
            in modDir.listSync(recursive: true)) {
          if (entity is File) {
            final String relativePath =
                entity.path.replaceFirst(modDir.path, '');
            final String newPath = '${global.stagedDir.path}$relativePath';
            Directory(newPath).parent.createSync(recursive: true);
            entity.copySync(newPath);
          }
        }
      } else {
        final Directory? rootModDir = findRootModDir(modDir);
        if (rootModDir != null) {
          for (final FileSystemEntity entity
              in rootModDir.listSync(recursive: true)) {
            if (entity is File) {
              final String relativePath =
                  entity.path.replaceFirst(rootModDir.path, '');
              final String newPath = '${global.gameDir.path}$relativePath';
              Directory(newPath).parent.createSync(recursive: true);
              entity.copySync(newPath);
            }
          }
        } else {
          _showInfoMessage('Root mod directory not found for $modName.');
        }
      }
    }

    for (final FileSystemEntity entity
        in global.storedDir.listSync(recursive: true)) {
      final String relativePath =
          entity.path.replaceFirst(global.storedDir.path, '');
      final String newPath = '${global.stagedDir.path}$relativePath';

      if (entity is File && !File(newPath).existsSync()) {
        entity.copySync(newPath);
      } else if (entity is Directory) {
        Directory(newPath).createSync(recursive: true);
      }
    }
  }

  Directory? findRootModDir(Directory modDirectory) {
    const List<String> extensions = <String>['.rpa', '.rpyc', '.rpy'];
    try {
      for (final FileSystemEntity file
          in modDirectory.listSync(recursive: true)) {
        if (file is File && extensions.any(file.path.endsWith)) {
          return file.parent;
        }
      }
    } catch (e) {
      _showInfoMessage('Error finding root mod directory: $e');
    }
    return null;
  }

  void _showInfoMessage(String message) {
    final SnackBar snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.pink,
      action: SnackBarAction(
        label: 'Close',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _selectMod(Map<String, dynamic> mod) {
    setState(() => _selectedMod = mod);
  }

  Future<void> _saveMod() async {
    if (_selectedMod != null) {
      await _prefs.setString('saved', _selectedMod!['Name']);
      _copyMod(_selectedMod!['Name']);
      _showInfoMessage('Mod installed successfully!');
    }
  }

  Widget _buildModCard() {
    if (_selectedMod == null) return const SizedBox.shrink();
    final List<String> modInfo = _getModData(_selectedMod!);

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final String entry in <String>[
              'Name',
              'Description',
              'Author',
              'Version',
            ])
              _buildRichText(
                title: '$entry: ',
                content: modInfo[_getModInfoIndex(entry)],
              ),
            if (modInfo[5].isNotEmpty)
              InkWell(
                child: _buildRichText(
                  title: 'Source: ',
                  content: modInfo[5],
                  isLink: true,
                ),
                onTap: () => launchUrl(Uri.parse(modInfo[5])),
              ),
          ],
        ),
      ),
    );
  }

  int _getModInfoIndex(String field) {
    switch (field) {
      case 'Name':
        return 0;
      case 'Description':
        return 1;
      case 'Author':
        return 2;
      case 'Version':
        return 3;
      default:
        return -1;
    }
  }

  Widget _buildRichText({
    required String title,
    required String content,
    bool isLink = false,
  }) {
    return Text.rich(
      TextSpan(
        text: title,
        style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        children: <InlineSpan>[
          TextSpan(
            text: content,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.normal,
              color: isLink ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
      softWrap: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DDLC Mods'),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            _buildModCard(),
            Expanded(
              child: ListView.builder(
                itemCount: _mods.length,
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> mod = _mods[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Image.asset(mod['Image']),
                    ),
                    title: Text(mod['Name']),
                    subtitle: Text(mod['Description']),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _selectMod(mod),
                  );
                },
              ),
            ),
            if (_selectedMod != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _runGame,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text('Start DDLC'),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: _saveMod,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text('Install Selected Mod'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
