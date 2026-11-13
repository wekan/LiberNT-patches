#!/usr/bin/env bash
# Clone upstream LiberNT WITH ITS HISTORY and apply this repository's changes on
# top of it as ordinary git commits, so what is left is a LiberNT repository
# whose `git log` shows upstream's history followed by the LiberNT-patches
# commits.
#
#   apply-patches.sh <patches-root> <dest-dir> [ref]
#
#   patches-root  where THIS repository is checked out
#   dest-dir      the LiberNT repository to create; must not exist yet. The
#                 release workflows use "LiberNT", which is the top directory of
#                 both LiberNT-<tag>-source-*.zip files.
#   ref           upstream branch, tag or commit (full or abbreviated) to build;
#                 empty = upstream's default branch (main-nt10), unreleased
#                 changes included.
#
# The commits, in this order, on a branch named libernt-patches:
#   1. dist/all/*.patch           code, build and workflow changes
#   2. dist/translations/*.patch  translations
# each verified against its .sha256sum and applied with `git am --3way`, in
# name order: a `git format-patch` file keeps its own author, date and message.
# --keep-non-patch strips only format-patch's "[PATCH]": LiberNT's subjects
# begin with a "[COMPONENT]" of their own, which plain `git am` would remove.
#
# The commits are REPRODUCIBLE: the committer is PATCH_AUTHOR and the committer
# date is each patch's own date, so the same upstream commit and the same patches
# give the same commit hashes on every run. That is what lets Release All Missing
# make a release's source again from the commits in its source.env.
#
# Prints, and writes to the file PATCHES_ENV when it is set, and under GitHub
# Actions to GITHUB_OUTPUT (keys in lower case):
#   SOURCE_REF          the ref that was asked for
#   UPSTREAM_COMMIT     the upstream commit it resolved to
#   UPSTREAM_SHORT      its first 11 characters, as upstream's own tags use
#   LIBERNT_VERSION     MAJOR.MINOR.PATCH_LEVEL from sdk/include/reactos/version.cmake
#   LIBERNT_BUILD_TYPE  its KERNEL_VERSION_BUILD_TYPE ("dev"), possibly empty
#   PATCHED_COMMIT      the top commit of the libernt-patches branch
#   PATCHES_APPLIED     how many commits were added
#
# UPSTREAM_URL overrides where upstream is cloned from (the tests use a local
# fixture repository, so they run with no network). PATCH_AUTHOR is the
# committer of every commit.
set -euo pipefail

usage='usage: apply-patches.sh <patches-root> <dest-dir> [ref]'
PATCHES="$(cd "${1:?$usage}" && pwd)"
DEST="${2:?$usage}"
REF="${3:-}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/LiberNT/LiberNT.git}"
PATCH_AUTHOR="${PATCH_AUTHOR:-Lauri Ojansivu <x@xet7.org>}"
NAME="${PATCH_AUTHOR% <*}"
EMAIL="${PATCH_AUTHOR##*<}"; EMAIL="${EMAIL%>}"

[ ! -e "$DEST" ] || { echo "apply-patches.sh: $DEST already exists" >&2; exit 1; }

# The whole history: the zip "with history" is this repository. Every branch
# comes along as well, so a branch or an older commit is a valid ref.
echo "Cloning ${UPSTREAM_URL} with its whole history..."
git clone --quiet --no-checkout "$UPSTREAM_URL" "$DEST"
cd "$DEST"
if [ -z "$REF" ]; then
  COMMIT="$(git rev-parse --verify 'HEAD^{commit}')"
  REF="$(git symbolic-ref --short HEAD)"
elif COMMIT="$(git rev-parse --verify -q "origin/$REF^{commit}")"; then
  :
elif COMMIT="$(git rev-parse --verify -q "$REF^{commit}")"; then
  :
else
  git fetch --quiet origin "$REF"
  COMMIT="$(git rev-parse --verify 'FETCH_HEAD^{commit}')"
fi
git checkout --quiet -B libernt-patches "$COMMIT"

ver() { sed -n "s/^set(KERNEL_VERSION_$1 \"\(.*\)\")\$/\1/p" sdk/include/reactos/version.cmake; }
VERSION="$(ver MAJOR).$(ver MINOR).$(ver PATCH_LEVEL)"
BUILD_TYPE="$(ver BUILD_TYPE)"
case "$VERSION" in *[!0-9.]*|.*|*..*|*.) echo "apply-patches.sh: no version in sdk/include/reactos/version.cmake ($VERSION)" >&2; exit 1 ;; esac
echo "Upstream ${REF} is ${COMMIT} (LiberNT ${VERSION}${BUILD_TYPE:+-$BUILD_TYPE})."

export GIT_COMMITTER_NAME="$NAME" GIT_COMMITTER_EMAIL="$EMAIL"
git config user.name "$NAME"
git config user.email "$EMAIL"
applied=0
for section in all translations; do
  for p in "$PATCHES/dist/$section"/*.patch; do
    [ -e "$p" ] || continue
    n="$(basename "$p")"
    ( cd "$PATCHES/dist/$section" && sha256sum --quiet -c "${n%.patch}.sha256sum" ) || {
      echo "::error::dist/${section}/${n} does not match its .sha256sum. Regenerate it; see docs/Design/Patch-format.md." >&2
      exit 1
    }
    echo "Applying ${section}/${n}"
    before="$(git rev-list --count HEAD)"
    git am --quiet --3way --keep-non-patch --committer-date-is-author-date "$p" || {
      git am --abort || true
      echo "::error::dist/${section}/${n} does not apply to upstream ${REF} (${COMMIT}). Re-port it; see docs/Design/Patch-format.md." >&2
      exit 1
    }
    applied=$((applied + $(git rev-list --count HEAD) - before))
  done
done

PATCHED="$(git rev-parse HEAD)"
echo "Applied ${applied} commit(s) onto upstream ${REF} at ${COMMIT}: libernt-patches is ${PATCHED}."
git log --oneline --no-decorate "${COMMIT}..HEAD"

out="$(printf 'SOURCE_REF=%s\nUPSTREAM_COMMIT=%s\nUPSTREAM_SHORT=%s\nLIBERNT_VERSION=%s\nLIBERNT_BUILD_TYPE=%s\nPATCHED_COMMIT=%s\nPATCHES_APPLIED=%s\n' \
  "$REF" "$COMMIT" "${COMMIT:0:11}" "$VERSION" "$BUILD_TYPE" "$PATCHED" "$applied")"
printf '%s\n' "$out"
cd - >/dev/null
[ -z "${PATCHES_ENV:-}" ] || printf '%s\n' "$out" > "$PATCHES_ENV"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  printf '%s\n' "$out" | while IFS='=' read -r k v; do
    printf '%s=%s\n' "$(printf '%s' "$k" | tr 'A-Z' 'a-z')" "$v"
  done >> "$GITHUB_OUTPUT"
fi
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Source"
    echo ""
    echo "| Upstream | Ref | Commit | Version | LiberNT-patches commits |"
    echo "|----------|-----|--------|---------|-------------------------|"
    echo "| LiberNT/LiberNT | ${REF} | \`${COMMIT}\` | ${VERSION}${BUILD_TYPE:+-$BUILD_TYPE} | ${applied} |"
  } >> "$GITHUB_STEP_SUMMARY"
fi
