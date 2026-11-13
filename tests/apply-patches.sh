#!/usr/bin/env bash
# Offline tests of releases/apply-patches.sh and releases/source-zips.py, on a
# small fixture upstream repository - no network, no LiberNT clone.
#
#   tests/apply-patches.sh
#
# Positive: both sections apply as commits, in order, with the version read
# from version.cmake; a second run gives the same commit hashes; the zips hold
# LiberNT/.git or not, keep the executable bit, and the zip without history is
# byte-identical from one run to the next.
# Negative: a patch that does not match its .sha256sum, a patch that does not
# apply, an existing destination and a bad release tag are each refused.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/libernt-patches-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
fails=0
ok()   { echo "ok   $*"; }
fail() { echo "FAIL $*"; fails=$((fails + 1)); }
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
g() { git -c user.name=Upstream -c user.email=up@example.org -c init.defaultBranch=main-nt10 "$@"; }

# The fixture upstream: a version.cmake, an English resource, a script.
UP="$TMP/upstream"
mkdir -p "$UP/sdk/include/reactos" "$UP/base/app/lang"
cat > "$UP/sdk/include/reactos/version.cmake" <<'EOF'
set(KERNEL_VERSION_MAJOR "0")
set(KERNEL_VERSION_MINOR "4")
set(KERNEL_VERSION_PATCH_LEVEL "17")
set(KERNEL_VERSION_BUILD_TYPE "dev")
EOF
printf 'LANGUAGE LANG_ENGLISH, SUBLANG_ENGLISH_US\nSTRINGTABLE\nBEGIN\n    1 "Hello"\nEND\n' > "$UP/base/app/lang/en-US.rc"
printf '#ifdef LANGUAGE_EN_US\n    #include "lang/en-US.rc"\n#endif\n' > "$UP/base/app/app.rc"
printf '#!/bin/sh\necho configured\n' > "$UP/configure.sh"; chmod +x "$UP/configure.sh"
g -C "$UP" init -q && g -C "$UP" add -A && GIT_COMMITTER_DATE=2026-11-01T00:00:00Z g -C "$UP" commit -q --date=2026-11-01T00:00:00Z -m "Upstream"

# The fixture patches: one in each section, made against the fixture upstream.
P="$TMP/patches"
mkdir -p "$P/dist/all" "$P/dist/translations"
cp -r "$ROOT/releases" "$P/"
W="$TMP/work"; g clone -q "$UP" "$W"
mkdir -p "$W/.github/workflows"; printf 'name: Release All\n' > "$W/.github/workflows/release-all.yml"
g -C "$W" add -A && g -C "$W" -c user.name='Lauri Ojansivu' -c user.email=x@xet7.org commit -q --date=2026-11-02T00:00:00Z -m "[CI] Release workflows"
g -C "$W" format-patch -q --stdout HEAD~1 > "$P/dist/all/0010-release-workflows.patch"
printf 'LANGUAGE LANG_FINNISH, SUBLANG_DEFAULT\nSTRINGTABLE\nBEGIN\n    1 "Hei"\nEND\n' > "$W/base/app/lang/fi-FI.rc"
printf '#ifdef LANGUAGE_FI_FI\n    #include "lang/fi-FI.rc"\n#endif\n' >> "$W/base/app/app.rc"
g -C "$W" add -A && g -C "$W" -c user.name='Lauri Ojansivu' -c user.email=x@xet7.org commit -q --date=2026-11-03T00:00:00Z -m "[TRANSLATION] Finnish"
g -C "$W" format-patch -q --stdout HEAD~1 > "$P/dist/translations/fi-FI.patch"
( cd "$P/dist/all" && sha256sum 0010-release-workflows.patch > 0010-release-workflows.sha256sum )
( cd "$P/dist/translations" && sha256sum fi-FI.patch > fi-FI.sha256sum )

run() { # <dest> [ref] -> output in $TMP/out.txt, env in $TMP/<dest>.env
  ( cd "$TMP" && UPSTREAM_URL="$UP" PATCHES_ENV="$TMP/$1.env" bash "$P/releases/apply-patches.sh" "$P" "$1" "${2:-}" ) > "$TMP/out.txt" 2>&1
}
val() { sed -n "s/^$2=//p" "$TMP/$1.env"; }

# Positive: both sections, in order, with the version.
if run one; then
  [ "$(val one PATCHES_APPLIED)" = 2 ] && ok "two patches applied as two commits" || fail "applied $(val one PATCHES_APPLIED), want 2"
  subjects="$(git -C "$TMP/one" log --format=%s -2 | tr '\n' '|')"
  [ "$subjects" = "[TRANSLATION] Finnish|[CI] Release workflows|" ] && ok "dist/all before dist/translations" || fail "order: $subjects"
  [ "$(val one LIBERNT_VERSION)" = 0.4.17 ] && [ "$(val one LIBERNT_BUILD_TYPE)" = dev ] && ok "version 0.4.17-dev from version.cmake" || fail "version $(val one LIBERNT_VERSION)-$(val one LIBERNT_BUILD_TYPE)"
  [ "$(val one UPSTREAM_COMMIT)" = "$(git -C "$UP" rev-parse HEAD)" ] && ok "upstream commit recorded" || fail "upstream commit"
  [ "$(git -C "$TMP/one" log -1 --format='%an <%ae>|%cn <%ce>')" = "Lauri Ojansivu <x@xet7.org>|Lauri Ojansivu <x@xet7.org>" ] && ok "author and committer" || fail "author/committer"
  grep -q 'Hei' "$TMP/one/base/app/lang/fi-FI.rc" && grep -q 'LANGUAGE_FI_FI' "$TMP/one/base/app/app.rc" && ok "the Finnish file and its include" || fail "Finnish file"
  [ "$(git -C "$TMP/one" rev-parse --abbrev-ref HEAD)" = libernt-patches ] && ok "branch libernt-patches" || fail "branch"
else fail "apply-patches.sh failed: $(tail -3 "$TMP/out.txt")"; fi

# Positive: reproducible commits, by ref too.
if run two "$(git -C "$UP" rev-parse --short HEAD)"; then
  [ "$(val two PATCHED_COMMIT)" = "$(val one PATCHED_COMMIT)" ] && ok "the same commits on a second run, by abbreviated commit" || fail "not reproducible: $(val one PATCHED_COMMIT) vs $(val two PATCHED_COMMIT)"
else fail "second run failed: $(tail -3 "$TMP/out.txt")"; fi

# Negative: the destination exists.
if run one; then fail "an existing destination was overwritten"; else grep -q 'already exists' "$TMP/out.txt" && ok "negative: an existing destination is refused" || fail "existing destination message"; fi

# Negative: a patch that does not match its checksum.
cp "$P/dist/translations/fi-FI.patch" "$TMP/fi-FI.patch.orig"
printf '\n' >> "$P/dist/translations/fi-FI.patch"
if run tampered; then fail "a tampered patch was applied"; else grep -q 'does not match its .sha256sum' "$TMP/out.txt" && ok "negative: a patch that does not match its .sha256sum stops the run" || fail "checksum message: $(tail -2 "$TMP/out.txt")"; fi
cp "$TMP/fi-FI.patch.orig" "$P/dist/translations/fi-FI.patch"

# Negative: a patch that does not apply - upstream changed the same lines.
printf '#ifdef LANGUAGE_EN_US\n    #include "lang/en-US.rc"\n#endif\n#ifdef LANGUAGE_FI_FI\n    #include "lang/other.rc"\n#endif\n' > "$UP/base/app/app.rc"
printf 'other\n' > "$UP/base/app/lang/fi-FI.rc"
g -C "$UP" add -A && g -C "$UP" commit -q -m "Upstream changes the same lines"
if run conflict; then fail "a conflicting patch was applied"; else grep -q 'does not apply to upstream' "$TMP/out.txt" && ok "negative: a patch that does not apply stops the run, naming it" || fail "conflict message: $(tail -2 "$TMP/out.txt")"; fi

# The zips.
Z1="$TMP/z1"; Z2="$TMP/z2"
if python3 -I "$ROOT/releases/source-zips.py" "$TMP/one" "$Z1" v1-test > /dev/null && python3 -I "$ROOT/releases/source-zips.py" "$TMP/two" "$Z2" v1-test > /dev/null; then
  names() { python3 -I -c 'import sys,zipfile; print("\n".join(zipfile.ZipFile(sys.argv[1]).namelist()))' "$1"; }
  names "$Z1/LiberNT-v1-test-source-with-history.zip" | grep -qx 'LiberNT/.git/HEAD' && ok "the zip with history has LiberNT/.git" || fail "no .git in the zip with history"
  if names "$Z1/LiberNT-v1-test-source-without-history.zip" | grep -q '^LiberNT/\.git/'; then fail "the zip without history has .git"; else ok "the zip without history has no LiberNT/.git"; fi
  names "$Z1/LiberNT-v1-test-source-without-history.zip" | grep -qx 'LiberNT/base/app/lang/fi-FI.rc' && ok "the patched files are in it, under LiberNT/" || fail "patched file missing from the zip"
  ( cd "$Z1" && sha256sum --quiet -c ./*.sha256 ) && ok "both .sha256 files verify" || fail ".sha256 files"
  cmp -s "$Z1/LiberNT-v1-test-source-without-history.zip" "$Z2/LiberNT-v1-test-source-without-history.zip" && ok "the zip without history is byte-identical on a second run" || fail "the zip without history differs between runs"
  mkdir -p "$TMP/unz" && ( cd "$TMP/unz" && unzip -q "$Z1/LiberNT-v1-test-source-without-history.zip" ) && [ -x "$TMP/unz/LiberNT/configure.sh" ] && ok "unzip keeps configure.sh executable" || fail "executable bit lost"
else fail "source-zips.py failed"; fi
if python3 -I "$ROOT/releases/source-zips.py" "$TMP/one" "$TMP/z3" "../escape" > /dev/null 2>&1; then fail "a tag with a / was accepted"; else ok "negative: a release tag with a / is refused"; fi

echo
echo "apply-patches tests: $fails failure(s)"
[ "$fails" -eq 0 ]
