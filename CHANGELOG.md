# Platforms

LiberNT built from upstream + these patches, at these platforms:

- [Releases](https://github.com/wekan/LiberNT/releases)
- [Upstream LiberNT](https://github.com/LiberNT/LiberNT)
- [How the build works](docs/Design/How-the-build-works.md)

Each release clones upstream `main-nt10` (or the ref asked for) with its whole
history, applies `dist/all/` and then `dist/translations/` as git commits, and
puts on a release of wekan/LiberNT the source zipped with and without its git
history and the boot CD and disk images of i386, amd64, arm64-raspberry,
riscv64-spacemit-k1 and ppc. Upstream's own releases are mirrored there too.

# TODO Later

<details>
<summary>Left in English on purpose</summary>

- bugcodes.mc, the bug check screen: the kernel looks its text up with
  LANG_NEUTRAL, which finds English, and draws it in the boot font; Windows
  keeps it English too.
- eventcreate's evtmsgstr.mc: its 65,536 messages are all `%1`, nothing to
  translate.
- storprop's disk policies page: its only resource is a dialog upstream has
  not finished - both radio buttons at one place, no handler - and does not
  build in, so nothing of it is shown in any language.

</details>

# Upcoming LiberNT-patches release

**In short:** the first release: everything **wekan/LiberNT** adds to upstream
LiberNT, as patches - the user interface, fourteen **message tables**, the
**Unicode character names** and the **time zones** in **Finnish**, and the **Release All**
and **Release All Missing** workflows, which build releases from upstream and
these patches, with the source **with and without its git history**, the
**boot CD and disk images**, and **upstream's own releases** mirrored.

This release adds the following new features:

<details>
<summary><a href="https://github.com/wekan/LiberNT-patches/commit/bb650d2e4a08ed42fb8bd146b001adbedcf190fe">The Finnish translation and the release workflows of LiberNT, as patches to upstream</a>. Thanks to xet7.</summary>

`dist/translations/fi-FI.patch` is LiberNT's user interface in Finnish: 213
fi-FI resource files added or completed, with the same controls, ids and
format specifiers as en-US, and their includes. The shell folders are named as
the Finnish userenv, mmsys and syssetup create them, so interop:LocaleTests
finds them alike, and kernel32's code page and location names are Finnish.

`dist/all/0010-release-workflows.patch` is wekan/LiberNT's Release All and
Release All Missing. They clone upstream with its whole history, apply these
patches with `releases/apply-patches.sh` as reproducible commits - the same
upstream commit gives the same commits, so Release All Missing makes a
release's source again from its `source.env` - and release
`LiberNT-<tag>-source-with-history.zip` (1.2 GB today) and
`-without-history.zip` (213 MB), the images of every platform LiberNT's own
CI builds, from that zip, and upstream's own releases, mirrored without
replacing a file. `git am --keep-non-patch` keeps LiberNT's `[COMPONENT]`
subjects, which plain `git am` strips.

`tests/apply-patches.sh` tests the scripts offline on a fixture repository:
the order, the version, the same commits twice, the zips with and without
`.git`, the executable bit, the zip without history byte-identical, and the
refusal of a changed patch, a patch that does not apply, an existing
destination and a bad tag. `tests/real-upstream.sh` applies the real patches
to upstream d02ef2e0db2 and checks the result against the tree expected.

</details>

and adds the following translations:

<details>
<summary><a href="https://github.com/wekan/LiberNT-patches/commit/65b2940b01f6faf84b489d2a27cb8ac93ae0334b">Finnish in nine of LiberNT's message tables, and tests that compile them</a>. Thanks to xet7.</summary>

`dist/translations/fi-FI-messages.patch` gives 427 messages a Finnish block:
DiskPart's command help, the net and arp commands, the event log and Service
Control Manager, the I/O errors drivers log, the PCI device class names Device
Manager shows, the Special Administration Console, RAPPS and the boot manager.
Each table gets `Finnish=0x40B:MSG0040B`, with the same `%1`, `%n`, `%0` and
`%%` inserts as the English; sacmsg.mc, which had no `LanguageNames`, lists
English as windmc's default so its binary stays byte for byte the same.

`tests/real-upstream.sh` builds windmc from the patched tree and compiles every
changed table, requiring a Finnish binary from each. It also stopped piping
`git log` into `grep -q`, which under pipefail failed once there were more
commits than grep read.

</details>

<details>
<summary><a href="https://github.com/wekan/LiberNT-patches/commit/1f48d0139ba48d692e2f1be747fc77496aa4d8f4">Finnish in the system error, NTSTATUS and network message tables</a>. Thanks to xet7.</summary>

The three largest message tables of `sdk/include/reactos/mc` get Finnish too:
errcodes.mc's 2,191 system error texts that FormatMessage gives every program,
ntstatus.mc's 693 NTSTATUS texts and netmsgmsg.mc's 1,416 network messages -
NET command output, the NERR_* errors and the alert and event log texts. Each
keeps the English inserts, line breaks and `\n` escapes; a text an earlier
table has gets the same Finnish, the day names and AM/PM suffixes NET USER
/TIMES parses are Finnish alike, and column headers keep their positions.

`tests/real-upstream.sh` applies the patches to upstream 22a5170d535 and
compiles all twelve changed tables with windmc, each with a Finnish binary; the
Finnish binaries have the same message ids as the English ones.

</details>

<details>
<summary><a href="https://github.com/wekan/LiberNT-patches/commit/39ce394ce6d3b8ebd2f5ddee93e0d9470a6694b0">Finnish in the virtual floppy tool, printed in the console's code page</a>. Thanks to xet7.</summary>

vfd.exe's 151 messages - its errors, prompts and command help - and the 63 of
vfd.dll, which label its open, save and property dialogs, are in Finnish. The
prompts keep the letters vfd.exe compares the answer with (Y, N, R, F, C, O,
T). vfd.exe printed its ANSI texts to the console, which is OEM, as they were:
only ASCII came out right, so it now converts them with `CharToOemA` first,
and the English output stays the same.

`tests/real-upstream.sh` compiles every table as ANSI or Unicode as its
CMakeLists says, as the build does - before, it compiled them all as Unicode -
and checks vfd.exe's five conversions. The C change was not compiled here:
there is no LiberNT toolchain on this machine.

</details>

<details>
<summary><a href="https://github.com/wekan/LiberNT-patches/commit/4992b1a836cd0ff20fef155da3e808d903b02d99">Finnish Unicode character names for getuname, and their generator</a>. Thanks to xet7.</summary>

`dist/translations/fi-FI-getuname.patch` gives getuname.dll - the names
Character Map shows - a fi-FI.rc with all 37,966 names of en-US.rc, by the
same ids: "Latinalainen iso kirjain A, jossa akuutti", "Hangul-tavu Ga",
"Oikealle osoittava nuoli palkista". A letter's own name is kept as written and
the diacritics use the terms of Finnish typography.

`tools/getuname-fi` generates the file from en-US.rc with a glossary and the
rules where Finnish word order differs, so a change upstream makes to the
English names is regenerated rather than hand-edited. `tests/real-upstream.sh`
checks the ids, the include and that the file is exactly the generator's
output. `releases/apply-patches.sh` now takes the patches in byte order, so a
release's commit hashes no longer depend on the machine's locale.

</details>

<details>
<summary><a href="https://github.com/wekan/LiberNT-patches/commit/295cb5809e7e71aa3578fa1c31d2013e590c68a8">Finnish for the modules whose .rc carried only English</a>. Thanks to xet7.</summary>

WordPad, write, the Game Controllers control panel, the multimedia errors of
winmm, the console host, Program Manager, the time zone names of tzres and the
Btrfs pages of Explorer carry their English resources in their own `.rc` and
included no Finnish file, so the user interface translation did not reach
them. `dist/translations/fi-FI-modules.patch` gives each a Finnish file
translated from its current English block - same ids, controls and printf
inserts - included under `LANGUAGE_FI_FI`; the time zones read "Länsi-Euroopan
normaaliaika" and "(UTC+02:00) Helsinki, Kiova, Riika, Sofia, Tallinna, Vilna".

`tests/real-upstream.sh` checks the eight includes, and now accepts a subject
with several components such as `[WORDPAD][WRITE]`, which it took for one that
had lost its component. storprop is left in English on purpose: its only
dialog is unfinished upstream and not built in.

</details>

Thanks to above GitHub users for their contributions and translators for their translations.
