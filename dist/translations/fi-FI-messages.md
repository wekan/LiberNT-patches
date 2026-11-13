# fi-FI messages

Finnish in LiberNT's message tables (`.mc`): each gets `Finnish=0x40B:MSG0040B`
in its `LanguageNames` and a `Language=Finnish` block in every message, with the
same `%1`, `%n`, `%0` and `%%` inserts as the English. Command names,
switches, values typed as shown and column layouts stay as they are.

| Table | Messages | What it is |
|-------|----------|------------|
| base/system/diskpart/diskpart_msg.mc | 53 | DiskPart's command help |
| base/applications/rapps/rappsmsg.mc | 2 | RAPPS install and remove |
| sdk/include/reactos/mc/bootmsg.mc | 3 | the boot manager |
| sdk/include/reactos/mc/neteventmsg.mc | 59 | event log and Service Control Manager |
| sdk/include/reactos/mc/ntiologc.mc | 39 | the I/O errors drivers log |
| sdk/include/reactos/mc/pciclass.mc | 100 | PCI device class names (Device Manager) |
| sdk/include/reactos/mc/net_msg.mc | 42 | the net command's help |
| base/applications/network/arp/arp_msg.mc | 11 | the arp command |
| sdk/include/reactos/mc/sacmsg.mc | 118 | the Special Administration Console |
| sdk/include/reactos/mc/ntstatus.mc | 693 | the NTSTATUS texts |
| sdk/include/reactos/mc/errcodes.mc | 2191 | the system error texts of FormatMessage |
| sdk/include/reactos/mc/netmsgmsg.mc | 1416 | the network messages: NET command output, NERR_*, alerts, event texts |
| modules/rosapps/applications/cmdutils/vfdcmd/vfdmsg.mc | 151 | vfd.exe, the virtual floppy tool: errors, prompts, help |
| modules/rosapps/lib/vfdlib/vfdmsg_lib.mc | 63 | vfd.dll's dialogs, which take their labels from it |

sacmsg.mc had no `LanguageNames`; English is listed as windmc's default
`English=0x409:MSG00001`, so its binary and header stay byte for byte the same.
A help text upstream has not written yet ("NET FILE ...", "<Add ... here>")
keeps its English, as every other language of the table has.
A text that an earlier table already has gets the same Finnish. In
netmsgmsg.mc the day names and AM/PM suffixes are Finnish because NET USER
/TIMES reads them from the table to parse what is typed, and column headers
keep their column positions.

vfd.exe compares a typed answer with fixed letters, so its prompts keep Y, N,
R, F, C, O and T and say them in Finnish. The patch also makes vfd.exe convert
what it prints with `CharToOemA`: it printed the ANSI texts to the OEM console
as they were, which only ASCII survives. `tests/real-upstream.sh` compiles each
table as ANSI or Unicode as its CMakeLists says, and checks that conversion.
`tests/real-upstream.sh` compiles every changed table with the windmc of the
patched tree and requires a Finnish binary from each.

Left in English on purpose:

- bugcodes.mc, the bug check screen: the kernel looks its text up with
  LANG_NEUTRAL, which finds English, and draws it in the boot font - as
  Windows, it stays English.
- eventcreate's evtmsgstr.mc: its 65,536 messages are all `%1`.
