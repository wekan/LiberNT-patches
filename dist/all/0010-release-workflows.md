# 0010 Release workflows

Adds `.github/workflows/release-all.yml`, `release-all-missing.yml` and
`release-build.yml` to LiberNT, the workflows of
[wekan/LiberNT](https://github.com/wekan/LiberNT) - a repository that is
upstream LiberNT with these patches applied, so its workflows come from here.

Release All clones upstream [LiberNT/LiberNT](https://github.com/LiberNT/LiberNT)
with its whole history, applies this repository with
[releases/apply-patches.sh](../../releases/apply-patches.sh), and puts on a
release of wekan/LiberNT:

- `LiberNT-<tag>-source-with-history.zip` and
  `LiberNT-<tag>-source-without-history.zip`
  ([releases/source-zips.py](../../releases/source-zips.py)),
- `LiberNT-<tag>-source.env`, the upstream and LiberNT-patches commits,
- the boot CD and disk images of i386, amd64, arm64-raspberry,
  riscv64-spacemit-k1 and ppc, built from the zip without history,

each with a `.sha256`. It also mirrors upstream's own releases (its builds
and its ICU, FFmpeg and Mesa payloads) to releases of the same tag. Release
All Missing completes a release with only what it lacks. See
[How the build works](../../docs/Design/How-the-build-works.md).

Not for upstream: it publishes to wekan/LiberNT.
