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
<summary>Not translated into Finnish yet</summary>

- The ReactOS virtual floppy tool's tables in modules/rosapps (vfdmsg.mc 151,
  vfdmsg_lib.mc 63).
- getuname's Unicode character names, about 38,000 lines.
- Modules whose `.rc` includes none of its language files, so a fi-FI file
  would not be used: joy, storprop, winmm, write, and the English-only
  resources of tzres, shellbtrfs, wordpad, progman and conhost among others.
  Their `.rc` has to include its language files first.

</details>

<details>
<summary>Left in English on purpose</summary>

- bugcodes.mc, the bug check screen: the kernel looks its text up with
  LANG_NEUTRAL, which finds English, and draws it in the boot font; Windows
  keeps it English too.
- eventcreate's evtmsgstr.mc: its 65,536 messages are all `%1`, nothing to
  translate.

</details>

# Upcoming LiberNT-patches release

**In short:** the first release: everything **wekan/LiberNT** adds to upstream
LiberNT, as patches - the user interface and twelve **message tables** in
**Finnish**, and the **Release All**
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

Thanks to above GitHub users for their contributions and translators for their translations.
