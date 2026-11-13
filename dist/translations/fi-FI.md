# fi-FI

LiberNT's user interface in Finnish: 213 fi-FI resource files, added or
completed, and the 196 module `.rc` files that include them.

## What it changes

- Every module that includes its language files gets a fi-FI resource with the
  same controls, ids, sizes and format specifiers as its en-US one, and an
  `#ifdef LANGUAGE_FI_FI` include beside the others, in alphabetical order.
- Finnish resources that had English left in them are translated, LiberNT
  Setup's upgrade, update and install-from-Windows pages among them.
- The shell folders are named as the Finnish userenv, mmsys and syssetup
  create them - "Käynnistä-valikko\\Kaikki ohjelmat", "Ohjelmat\\Yhteiset
  tiedostot" - so shell32 names the folders that exist and
  interop:LocaleTests finds them alike.
- kernel32's code page and location names (winnls) are in Finnish.

## What it leaves in English, on purpose

Names that Finnish Windows shows in English too: country names that are the
same in Finnish, protocol and standard names (ISDN, PPTP, EBCDIC, KOI8),
property and identifier names, file extensions, key names on keyboards, and
the GPL license text.

## Not translated yet

The message tables are in their own patch, fi-FI-messages.patch, and what is
left of them and of the rest is in the TODO Later of
[CHANGELOG.md](../../CHANGELOG.md).
