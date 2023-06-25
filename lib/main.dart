import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

final modDir = Directory('mod');
final stagedDir = Directory('staged');
final storedDir = Directory('stored');
final gameDir = Directory('staged\\game');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (!modDir.existsSync()) {
    modDir.createSync();
  }
  if (!stagedDir.existsSync()) {
    stagedDir.createSync();
  }
  if (!storedDir.existsSync()) {
    storedDir.createSync();
  }
  runApp(const DDLCMM());
}

class DDLCMM extends StatelessWidget {
  const DDLCMM({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const ModList(),
    );
  }
}

void runGame() {
  windowManager.hide();
  Process.runSync('${Directory.current.path.toString()}\\staged\\ddlc.exe', []);
  windowManager.show();
}

String getModData(selectedMod) {
  Map<String, dynamic> jsonData = selectedMod;
  List<String> data = [];
  jsonData.forEach((key, value) {
    if (key != 'Image') 
      {data.add('$key: $value');
    }
  });
  String result = data.join('\n');
  return result;
}

void copyMod(String modName) {
  if (stagedDir.existsSync()) {
    stagedDir.deleteSync(recursive: true);
  }
  gameDir.createSync(recursive: true);

  final rootModDir = findrootModDir(Directory('mod\\$modName'));

  if (rootModDir != null) {
    rootModDir.listSync(recursive: true).forEach((entity) {
      if (entity is File) {
        final relativePath = entity.path.replaceFirst(rootModDir.path, '');
        final newPath = gameDir.path + relativePath;
        Directory(newPath).parent.createSync(recursive: true);
        entity.copySync(newPath);
      }
    });
  }

  storedDir.listSync(recursive: true).forEach((entity) {
    if (entity is File) {
      final relativePath = entity.path.replaceFirst(storedDir.path, '');
      final newPath = stagedDir.path + relativePath;
      if (!File(newPath).existsSync()) {
        entity.copySync(newPath);
      }
    } else if (entity is Directory) {
      final relativePath = entity.path.replaceFirst(storedDir.path, '');
      final newPath = stagedDir.path + relativePath;
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

class ModList extends StatefulWidget {
  const ModList({super.key});

  @override
  State<ModList> createState() => _ModListState();
}

class _ModListState extends State<ModList> {
  List<Map<String, dynamic>> _mods = [];
  Map<String, dynamic>? _selectedMod;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initMods();
  }

  Future<void> _initMods() async {
    final List<FileSystemEntity> modFolders = modDir.listSync();
    final List<Map<String, dynamic>> mods = [];

    for (final FileSystemEntity folder in modFolders) {
      if (folder is Directory) {
        final String folderName = folder.path.split('/').last;
        final File jsonFile = File('$folderName.json');

        if (!jsonFile.existsSync()) {
          jsonFile.createSync();
          jsonFile.writeAsStringSync(json.encode({
            'Name': folderName.replaceAll("mod\\", ""),
            'Description': 'Placeholder',
            'Author': 'Placeholder',
            'Version': '1.0.0',
            'Image': '',
            'Source': '',
          }));
        }

        final Map<String, dynamic> modData =
            json.decode(jsonFile.readAsStringSync());
        mods.add(modData);
      }
    }

    _prefs = await SharedPreferences.getInstance();
    final String? savedModName = _prefs!.getString('saved');

    setState(() {
      _mods = mods;
        try {
          if (savedModName != null) {
            _selectedMod = mods.firstWhere((Map<String, dynamic> mod) => mod['Name'] == savedModName);
        }
        } catch (e) {
        _selectedMod = null;
      }
    });
  }

  void _selectMod(Map<String, dynamic> mod) {
    setState(() => _selectedMod = mod);
  }

  Future<void> _saveMod() async {
    await _prefs!.setString('saved', _selectedMod!['Name']);
    copyMod(_selectedMod!['Name']);
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
          children: [
            if (_selectedMod != null)
              Card(
                color: Colors.white,
                elevation: 4.0,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    getModData(_selectedMod),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _mods.length,
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> mod = _mods[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Image.asset('assets/Logo.webp'),
                    ),
                    title: Text(mod['Name']),
                    subtitle: Text(mod['Description']),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _selectMod(mod),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_selectedMod != null) 
                ElevatedButton(
                  onPressed: runGame,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.pink,
                  ),
                  child: const Text('Start DDLC'),
                ),
                const SizedBox(width: 8.0),
                if (_selectedMod != null) 
                  ElevatedButton(
                    onPressed: _saveMod,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.pink,
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