# DDLCMM

Got bored and wanted my own drop in replacement of a mod manager for ddlc that was as dumbed down as possible while being functional. Keep in mind this is not 100% complete and I still need to finish up some stuff but I believe it is ready enough to be release to the public.

# Installation

Installing it is easy. Go into a clean ddlc install and move all of the game's files into a folder called "stored". Then, drop in the files included in the zip into the ddlc directory. Your ddlc directory should now look like this:
```
ddlc
├───data
├───stored
├───ddlcmm.exe
├───flutter_windows.dll
├───screen_retriever_plugin.dll
├───SteamFix.ps1
└───window_manager_plugin.dll
```
To make it truly drop in, go into your steam install of the game and follow the same steps as before but also rename "ddlcmm.exe" to "ddlc.exe" which will ensure steam launches it instead of base game. You can run the included powershell script as admin in the ddlc directory to fix permission issues in case your install is in a write protected folder like "program files (x86)". If you're using a custom folder for your steam install or are using a different drive, you won't need to run the script.