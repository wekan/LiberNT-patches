#!/usr/bin/env bash
# The real patches on real upstream LiberNT: they apply, keep their subjects,
# add what they say, and give the same commits on a second run.
#
#   tests/real-upstream.sh [upstream-url-or-path] [ref]
#
# Defaults: the LiberNT checkout beside this repository (WeKan's .tools/w/LiberNT),
# which has upstream's history, at its upstream/main-nt10 when it has that
# remote; else https://github.com/LiberNT/LiberNT.git at main-nt10 (a 1 GB clone).
# EXPECT_TREE, when set, is the tree the patched commit must have.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="${1:-}"; REF="${2:-}"
if [ -z "$URL" ] && [ -d "$ROOT/../LiberNT/.git" ]; then
  URL="$ROOT/../LiberNT"
  [ -n "$REF" ] || REF="$(git -C "$URL" rev-parse -q --verify upstream/main-nt10 || true)"
fi
URL="${URL:-https://github.com/LiberNT/LiberNT.git}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/libernt-real.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
fails=0
ok()   { echo "ok   $*"; }
fail() { echo "FAIL $*"; fails=$((fails + 1)); }

run() {
  ( cd "$TMP" && UPSTREAM_URL="$URL" PATCHES_ENV="$TMP/$1.env" bash "$ROOT/releases/apply-patches.sh" "$ROOT" "$1" "$REF" ) > "$TMP/$1.log" 2>&1
}
val() { sed -n "s/^$2=//p" "$TMP/$1.env"; }

echo "Upstream: $URL ${REF:-(default branch)}"
if ! run one; then fail "the patches do not apply: $(tail -3 "$TMP/one.log")"; echo "real-upstream tests: $fails failure(s)"; exit 1; fi
want="$(ls "$ROOT"/dist/all/*.patch "$ROOT"/dist/translations/*.patch | wc -l)"
[ "$(val one PATCHES_APPLIED)" = "$want" ] && ok "$want patches applied as $want commits on $(val one UPSTREAM_SHORT)" || fail "applied $(val one PATCHES_APPLIED), want $want"
git -C "$TMP/one" log --format=%s -"$want" | grep -qx '\[TRANSLATION\] Translate the user interface into Finnish (fi-FI)' && ok "the [TRANSLATION] subject is kept" || fail "translation subject: $(git -C "$TMP/one" log --format=%s -1)"
git -C "$TMP/one" log --format=%s -"$want" | grep -q '^\[CI\] ' && ok "the [CI] subject is kept" || fail "CI subject"
for f in release-all.yml release-all-missing.yml release-build.yml; do
  [ -f "$TMP/one/.github/workflows/$f" ] || fail "no .github/workflows/$f"
done
ok "the three release workflows are in it"
n="$(git -C "$TMP/one" diff --name-only "$(val one UPSTREAM_COMMIT)" HEAD | grep -cE '/lang/([^/]*_)?(fi-FI|Fi)\.rc$')"
[ "$n" -ge 200 ] && ok "$n Finnish resource files added or changed" || fail "only $n Finnish resource files"
# Every Finnish include points at a file that exists.
broken=0
while IFS= read -r rc; do
  d="$(dirname "$rc")"
  for inc in $(grep -oE '"[^"]*lang/(fi-FI|[A-Za-z]*_?Fi)\.rc"' "$TMP/one/$rc" | tr -d '"'); do
    [ -e "$TMP/one/$d/$inc" ] || { echo "     $rc -> $inc"; broken=$((broken + 1)); }
  done
done < <(git -C "$TMP/one" diff --name-only "$(val one UPSTREAM_COMMIT)" HEAD | grep -E '\.rc$' | grep -v '/lang/')
[ "$broken" -eq 0 ] && ok "every Finnish include it adds points at a file" || fail "$broken broken Finnish include(s)"
if [ -n "${EXPECT_TREE:-}" ]; then
  [ "$(git -C "$TMP/one" rev-parse 'HEAD^{tree}')" = "$EXPECT_TREE" ] && ok "the patched tree is the expected one" || fail "tree $(git -C "$TMP/one" rev-parse 'HEAD^{tree}'), want $EXPECT_TREE"
fi
if run two; then
  [ "$(val two PATCHED_COMMIT)" = "$(val one PATCHED_COMMIT)" ] && ok "the same commit on a second run: $(val one PATCHED_COMMIT)" || fail "not reproducible"
else fail "the second run failed"; fi

echo
echo "real-upstream tests: $fails failure(s)"
[ "$fails" -eq 0 ]
