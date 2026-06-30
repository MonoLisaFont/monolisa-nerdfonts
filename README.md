# MonoLisa Nerd Fonts

This repository documents how to build a Nerd Fonts-patched version of
MonoLisa Code from locally supplied MonoLisa font files.

MonoLisa is a commercial font. Keep the original files in `input/` and do not
redistribute generated fonts unless your MonoLisa license allows it.

## Inputs

Place the MonoLisa Code `.ttf` files in `input/`.

`input/` is intentionally ignored by git.

## Build

The easiest reproducible route is the official Nerd Fonts patcher Docker image.
It wraps FontForge and the Nerd Fonts glyph sources. The wrapper pins the
default image by digest so repeated builds use the same patcher unless you
override it.

```sh
./scripts/patch.sh
```

Generated fonts are written to `output/`, which is also ignored by git.
The wrapper keeps successful builds quiet and writes the full upstream patcher
log to `output/patch.log`.

Set `PATCH_CLEAN=1` to remove old generated `.ttf` and `.otf` files from
`output/` before rebuilding:

```sh
PATCH_CLEAN=1 ./scripts/patch.sh
```

To pass extra options to the Nerd Fonts patcher, append them:

```sh
./scripts/patch.sh --debug
```

The default options are:

- `--complete`: include the full Nerd Fonts glyph set.
- `--careful`: avoid overwriting existing glyphs in the source font.
- `--quiet`: suppress routine glyph-copy logging.
- `--no-progressbars`: keep build logs readable.

Common upstream patcher options:

- `--debug`: print more detail when diagnosing naming or patching issues.
- `--dry`: check patcher naming without writing generated fonts.
- `--adjust-line-height`: adjust line heights to center Powerline separators.
- `--mono`: create monospaced output and single-width added glyphs.
- `--single-width-glyphs`: keep the source font metrics but make added glyphs
  single-width.
- `--variable-width-glyphs`: avoid adjusting glyph advance widths.
- `--extension ttf|otf`: choose the generated font file type.

See the upstream
[`font-patcher`](https://github.com/ryanoasis/nerd-fonts/blob/master/font-patcher)
source for the complete flag list.

Set `PATCH_VERBOSE=1` when you want to see the raw FontForge and patcher output:

```sh
PATCH_VERBOSE=1 ./scripts/patch.sh
```

Set `NERD_FONTS_PATCHER_IMAGE` to use a different patcher image:

```sh
NERD_FONTS_PATCHER_IMAGE=nerdfonts/patcher:latest ./scripts/patch.sh
```

The script patches temporary copies of the input fonts. This keeps the
commercial source files in `input/` untouched while still allowing FontForge to
perform its metadata checks and fixes.

## Troubleshooting

Successful builds can still produce a noisy `output/patch.log`. FontForge often
reports ignored source tables and Nerd Fonts icon glyph names that do not match
their private-use Unicode codepoints. These warnings are expected for this
patching workflow.

If generated fonts are missing or look wrong, rerun with `PATCH_VERBOSE=1` or
pass `--debug` to the patcher:

```sh
PATCH_VERBOSE=1 ./scripts/patch.sh --debug
```

## Manual Docker Command

If you want to run Docker manually, copy the input fonts to a temporary working
directory first and mount that directory as `/in`:

```sh
image="nerdfonts/patcher@sha256:5d7ffcb702a7c14eeda9b107f9dadd6d250dedf9d1f0993d966b4fd8337c47a6"
work_dir="$(mktemp -d)"
cp input/*.ttf "$work_dir"/
mkdir -p output
docker run --rm \
  -v "$work_dir:/in" \
  -v "$PWD/output:/out" \
  "$image" \
  --complete \
  --careful \
  --quiet \
  --no-progressbars
rm -rf "$work_dir"
```

Check whether the pinned patcher image differs from the latest upstream image:

```sh
./scripts/check-patcher-update.sh
```

The check pulls `nerdfonts/patcher:latest`, compares its digest with the pinned
digest in `scripts/patch.sh`, and prints a test command if a newer image is
available. Normal builds do not check this automatically so they remain
reproducible and do not require network access.

You can also pull a fresh patcher image manually:

```sh
docker pull nerdfonts/patcher:latest
```

After testing a newer image, update `NERD_FONTS_PATCHER_IMAGE` or the pinned
digest in `scripts/patch.sh` if you want the repository default to change.

## References

- [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts)
- [MonoLisa feedback issue #333](https://github.com/MonoLisaFont/feedback/issues/333)
