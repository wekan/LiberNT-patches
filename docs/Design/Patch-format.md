# Patch format

`dist/` has two sections, applied in this order as git commits on the
`libernt-patches` branch by [releases/apply-patches.sh](../../releases/apply-patches.sh):

| Section | For |
|---------|-----|
| `dist/all/` | changes to LiberNT's code, build and workflows - anything but translations |
| `dist/translations/` | translations of LiberNT's resources (`lang/*.rc`) |

Both are applied the same way, with `git am --3way --keep-non-patch`, in name
order. A section of its own for translations keeps them apart from code in the
listing, the review and the release notes; LiberNT's translations are `.rc`
files, so they need no merge of their own the way gitea-patches' JSON locales
do.

## Three files per patch

```
dist/translations/
  fi-FI.patch       git format-patch output: one or more commits
  fi-FI.sha256sum   sha256 of the .patch, verified before applying
  fi-FI.md          what the patch does and why, and what it leaves out
```

`dist/all/` names its patches by the logical change in kebab-case, prefixed
`0010-`, `0020-` so the order is clear; a translation is named by its language
tag, as LiberNT names its resource files.

## Making a patch

From a LiberNT checkout whose commits are on top of upstream:

```sh
git -C LiberNT format-patch --stdout <upstream commit>..<your commit> > dist/translations/fi-FI.patch
cd dist/translations && sha256sum fi-FI.patch > fi-FI.sha256sum
```

`git format-patch` output keeps each commit's author, date and message, so the
commit in the released source is the commit you made - with its
`[COMPONENT]` subject, which `--keep-non-patch` keeps (plain `git am` would
strip it). Write the message as LiberNT's AGENTS.md asks: a `[COMPONENT]`
subject and a `Problem:`/`Why:`/`How:` body.

The easiest way to update a patch is to apply them all, change the result, and
make the patch again:

```sh
./build.sh source                       # LiberNT/ = upstream + these patches
# ... edit, then amend the commit the change belongs to ...
git -C LiberNT format-patch --stdout <upstream commit>..HEAD~1 > dist/all/0010-release-workflows.patch
git -C LiberNT format-patch --stdout HEAD~1..HEAD > dist/translations/fi-FI.patch
```

## When a patch no longer applies

The release stops with an error naming the patch and the upstream commit.
Re-port it: apply the others, apply this one with `git am --3way`, resolve the
conflict, commit, and regenerate the `.patch` and `.sha256sum`. Then run
`tests/real-upstream.sh`, which applies every patch to upstream and checks
the result.
