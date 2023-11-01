import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddlcmm/utils.dart';
import 'package:ddlcmm/global.dart' as global;
import 'package:url_launcher/url_launcher.dart';

class ModList extends StatefulWidget {
  const ModList({super.key});

  @override
  State<ModList> createState() => _ModListState();
}

class _ModListState extends State<ModList> {
  List<Map<String, dynamic>> _mods = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedMod;
  SharedPreferences? _prefs;
  final ModUtils utils = ModUtils();

  @override
  void initState() {
    super.initState();
    _initMods();
  }

  Future<void> _initMods() async {
    final List<FileSystemEntity> modFolders = global.modDir.listSync();
    final List<Map<String, dynamic>> mods = <Map<String, dynamic>>[];

    for (final FileSystemEntity folder in modFolders) {
      if (folder is Directory) {
        final String folderName = folder.path.split('/').last;
        final File jsonFile = File('$folderName.json');

        if (!jsonFile.existsSync()) {
          jsonFile.createSync();
          jsonFile.writeAsStringSync(
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
            (Map<String, dynamic> mod) => mod['Name'] == savedModName,
          );
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
    List<String> modInfo = <String>[];
    if (_selectedMod != null) {
      modInfo = utils.getModData(_selectedMod!);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('DDLC Mods'),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            if (_selectedMod != null)
              Card(
                color: Colors.white,
                elevation: 4.0,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text.rich(
                        textAlign: TextAlign.left,
                        softWrap: true,
                        TextSpan(
                          text: 'Name: ',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <InlineSpan>[
                            TextSpan(
                              text: modInfo[0],
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        textAlign: TextAlign.left,
                        softWrap: true,
                        TextSpan(
                          text: 'Description: ',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <InlineSpan>[
                            TextSpan(
                              text: modInfo[1],
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        textAlign: TextAlign.left,
                        softWrap: true,
                        TextSpan(
                          text: 'Author: ',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <InlineSpan>[
                            TextSpan(
                              text: modInfo[2],
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        textAlign: TextAlign.left,
                        softWrap: true,
                        TextSpan(
                          text: 'Version: ',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <InlineSpan>[
                            TextSpan(
                              text: modInfo[3],
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (modInfo[5] != '')
                        InkWell(
                          child: Text.rich(
                            textAlign: TextAlign.left,
                            softWrap: true,
                            TextSpan(
                              text: 'Source: ',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                              children: <InlineSpan>[
                                TextSpan(
                                  text: modInfo[5],
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => launchUrl(
                            Uri.parse(
                              modInfo[5],
                            ),
                          ),
                        ),
                    ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
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
