# How the build works

This repository holds no LiberNT source. It holds what
[wekan/LiberNT](https://github.com/wekan/LiberNT) adds to upstream
[LiberNT/LiberNT](https://github.com/LiberNT/LiberNT), as patches, and the
scripts that apply them. wekan/LiberNT is upstream with these patches applied;
its workflows are one of the patches, so they come from here too.

## The two repositories

| Repository | What is in it |
|------------|---------------|
| wekan/LiberNT-patches (this one) | `dist/` patches, `releases/` scripts, `tests/`, docs |
| wekan/LiberNT | upstream's history, these patches on top, and the releases |

The workflows run in wekan/LiberNT, because that is where the releases are:
`GITHUB_TOKEN` writes to the releases of its own repository, so no other
token is needed. They clone this repository - it is public - at the commit
asked for.

## Release All

`gh workflow run release-all.yml -R wekan/LiberNT [-f ref=...] [-f patches_ref=...]`

1. **source** - clones this repository and runs
   [releases/apply-patches.sh](../../releases/apply-patches.sh): upstream is
   cloned with its whole history, every patch is applied with
   `git am --3way`. Then [releases/source-zips.py](../../releases/source-zips.py)
   zips the result twice:

   | File | What it is |
   |------|------------|
   | `LiberNT-<tag>-source-with-history.zip` | `LiberNT/` with `LiberNT/.git` |
   | `LiberNT-<tag>-source-without-history.zip` | the same without `LiberNT/.git` |
   | `LiberNT-<tag>-source.env` | `UPSTREAM_COMMIT`, `PATCHES_COMMIT` and `PATCHED_COMMIT` |

   It creates the release - a prerelease while version.cmake says `dev` -
   uploads these with a `.sha256` each, and hands the zip without history to
   the builds.
2. **build** - one job per platform of LiberNT's own CI (i386 with GCC;
   amd64, arm64-raspberry, riscv64-spacemit-k1 and ppc with Clang) unzips that
   source and builds `bootcd.iso`, `LiberNT.img`, `LiberNT.vhd` and
   `LiberNT.vhdx`, zipped as `LiberNT-<tag>-<platform>-<image>.zip`, each with
   a `.sha256`. Every image is built from the same zip that is on the release.
3. **mirror** - copies upstream's own releases to releases of the same tag,
   name, notes and files on wekan/LiberNT: its builds and its ICU, FFmpeg and
   Mesa payloads. A release or a file already there is kept; one file is on the
   runner at a time, because together they are larger than its disk.

The tag is `v<MAJOR>.<MINOR>.<PATCH_LEVEL>[-<BUILD_TYPE>]-wekan-<YYYYMMDD>-<upstream commit>`,
for example `v0.4.17-dev-wekan-20261113-d02ef2e0db2`, from upstream's
sdk/include/reactos/version.cmake. The `-wekan-` tells it from upstream's
mirrored tags (`nt10.0-043-...`, `icu-72.1-1`).

## Release All Missing

`gh workflow run release-all-missing.yml -R wekan/LiberNT [-f tag=...]`

Completes a release - the newest `-wekan-` one by default: the source files and
the platforms it lacks a file of, uploading only absent files, and the
upstream releases mirrored. Its source is made again from the commits in the
release's `source.env`: the commits are reproducible (the committer and the
committer date come from the patches, not from the run), so the same upstream
commit and the same patches give the same `PATCHED_COMMIT`. When the release
already has its zip without history, the builds use that zip.

## Why the workflows do not push the patched commit

`GITHUB_TOKEN` may not push a commit that adds or changes a workflow file, and
the patches add the release workflows. So the release's tag points at the
wekan/LiberNT commit the workflow ran from, and `source.env` says which source
the release is. The maintainer keeps wekan/LiberNT's branch equal to upstream
with these patches by pushing it from a checkout:

```sh
./build.sh source              # LiberNT/ = upstream main-nt10 + the patches
git -C LiberNT push git@github.com:wekan/LiberNT.git libernt-patches:main-nt10 --force-with-lease
```

## Tests

| Test | What it checks |
|------|----------------|
| `tests/apply-patches.sh` | on a small fixture upstream, offline: both sections apply, in order; the version; the same commits on a second run; the zips with and without `.git`, the executable bit, the zip without history byte-identical; and refusals of a changed patch, a patch that does not apply, an existing destination, a bad tag |
| `tests/real-upstream.sh` | the real patches on real upstream (WeKan's `.tools/w/LiberNT` when present): they apply, keep their `[COMPONENT]` subjects, add the workflows and the Finnish files, every Finnish include points at a file, the same commit on a second run |
