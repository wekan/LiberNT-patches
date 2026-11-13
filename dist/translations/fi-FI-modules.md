# fi-FI modules

Finnish for the modules whose `.rc` carries its English resources itself and
included no Finnish file, so the user interface translation could not reach
them. Each gets a Finnish file translated from its current English block - the
same ids, controls, menus and printf inserts, only the texts changed - and an
include under `LANGUAGE_FI_FI`, with `#pragma code_page(65001)` where the
`.rc` had none.

| Module | Finnish file | What it is |
|--------|--------------|------------|
| base/applications/wordpad | lang/fi-FI.rc | WordPad, from the MENUEX block of wordpad.rc (with the Lists submenu the older lang files lack) |
| base/applications/write | lang/Fi.rc | write.exe, which starts WordPad |
| dll/cpl/joy | lang/fi-FI.rc | the Game Controllers control panel |
| dll/win32/winmm | lang/winmm_Fi.rc | the MCI, wave and MIDI error texts every multimedia program shows |
| base/system/conhost | lang/fi-FI.rc | the console host's menu and settings dialogs |
| base/shell/progman | lang/fi-FI.rc | Program Manager, from new_resources.rc |
| dll/win32/tzres | lang/fi-FI.rc | the time zone names: "Länsi-Euroopan normaaliaika", "(UTC+02:00) Helsinki, Kiova, Riika, Sofia, Tallinna, Vilna" |
| dll/shellext/shellbtrfs | lang/fi-FI.rc | the Btrfs pages of Explorer: properties, balance, scrub, devices, send and receive |

joy's and winmm's existing lang/ files are older than their `.rc` and no longer
built; they are left as they are. storprop is not here: its only resource is a
dialog upstream has not finished and does not build in.
