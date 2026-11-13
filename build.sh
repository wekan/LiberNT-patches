#!/usr/bin/env bash
# LiberNT-patches menu.
#
#   ./build.sh source [ref]        clone upstream LiberNT into ./LiberNT and apply the patches
#   ./build.sh zips [tag]          zip ./LiberNT with and without its history into ./out
#   ./build.sh test                the offline tests
#   ./build.sh test-real [url [ref]]  the real patches on real upstream LiberNT
#   ./build.sh release-all [ref]   run Release All of wekan/LiberNT on GitHub
#   ./build.sh release-all-missing [tag]
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"
# Temporary files beside the checkout, not in a small /tmp: WeKan's .tools/tmp
# when this is WeKan's .tools/w/LiberNT-patches.
if [ -z "${TMPDIR:-}" ] && [ -d "$root/../../tmp" ]; then export TMPDIR="$(cd "$root/../../tmp" && pwd)"; fi
command="${1:-}"
if [ -z "$command" ]; then
  printf '1) Clone upstream LiberNT into ./LiberNT and apply the patches
2) Zip ./LiberNT with and without its history into ./out
3) Run the offline tests
4) Apply the real patches to real upstream LiberNT
5) Release All (GitHub Actions of wekan/LiberNT)
6) Release All Missing (GitHub Actions of wekan/LiberNT)
0) Exit
Selection: '
  read -r choice
  case "$choice" in
    1) command=source;; 2) command=zips;; 3) command=test;; 4) command=test-real;;
    5) command=release-all;; 6) command=release-all-missing;; 0) exit 0;;
    *) echo 'Invalid selection' >&2; exit 2;;
  esac
else
  shift
fi
case "$command" in
  source)
    rm -rf LiberNT
    bash releases/apply-patches.sh . LiberNT "${1:-}" ;;
  zips)
    [ -d LiberNT/.git ] || { echo "No ./LiberNT: run ./build.sh source first." >&2; exit 1; }
    python3 -I releases/source-zips.py LiberNT out "${1:-local-$(git -C LiberNT rev-parse --short=11 HEAD)}" ;;
  test)
    bash tests/apply-patches.sh ;;
  test-real)
    bash tests/real-upstream.sh "$@" ;;
  release-all)
    exec gh workflow run release-all.yml -R wekan/LiberNT ${1:+-f ref="$1"} ;;
  release-all-missing)
    exec gh workflow run release-all-missing.yml -R wekan/LiberNT ${1:+-f tag="$1"} ;;
  *) echo "Usage: $0 [source [ref]|zips [tag]|test|test-real [url [ref]]|release-all [ref]|release-all-missing [tag]]" >&2; exit 2 ;;
esac
