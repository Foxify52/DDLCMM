import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddlcmm/utils.dart';
import 'package:ddlcmm/global.dart' as global;

class ModList extends StatefulWidget {
  const ModList({super.key});

  @override
  State<ModList> createState() => _ModListState();
}

class _ModListState extends State<ModList> {
  List<Map<String, dynamic>> _mods = [];
  Map<String, dynamic>? _selectedMod;
  SharedPreferences? _prefs;
  final utils = ModUtils();

  @override
  void initState() {
    super.initState();
    _initMods();
  }

  Future<void> _initMods() async {
    final List<FileSystemEntity> modFolders = global.modDir.listSync();
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
          _selectedMod = mods.firstWhere(
              (Map<String, dynamic> mod) => mod['Name'] == savedModName);
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
    utils.copyMod(_selectedMod!['Name']);
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
                    utils.getModData(_selectedMod),
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
                    onPressed: utils.runGame,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text('Start DDLC'),
                  ),
                const SizedBox(width: 8.0),
                if (_selectedMod != null)
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
