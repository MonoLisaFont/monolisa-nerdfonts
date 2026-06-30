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
It wraps FontForge and the current Nerd Fonts glyph sources.

```sh
./scripts/patch.sh
```

Generated fonts are written to `output/`, which is also ignored by git.
The wrapper keeps successful builds quiet and writes the full upstream patcher
log to `output/patch.log`.

To pass extra options to the Nerd Fonts patcher, append them:

```sh
./scripts/patch.sh --adjust-line-height
```

The default options are:

- `--complete`: include the full Nerd Fonts glyph set.
- `--careful`: avoid overwriting existing glyphs in the source font.
- `--quiet`: suppress routine glyph-copy logging.
- `--no-progressbars`: keep build logs readable.

Set `PATCH_VERBOSE=1` when you want to see the raw FontForge and patcher output:

```sh
PATCH_VERBOSE=1 ./scripts/patch.sh
```

The script patches temporary copies of the input fonts. This keeps the
commercial source files in `input/` untouched while still allowing FontForge to
perform its metadata checks and fixes.

## Manual Docker Command

If you want to run Docker manually, copy the input fonts to a temporary working
directory first and mount that directory as `/in`:

```sh
work_dir="$(mktemp -d)"
cp input/*.ttf "$work_dir"/
mkdir -p output
docker run --rm \
  -v "$work_dir:/in" \
  -v "$PWD/output:/out" \
  nerdfonts/patcher \
  --complete \
  --careful \
  --quiet \
  --no-progressbars
rm -rf "$work_dir"
```

Pull a fresh patcher image when you want to update to the latest Nerd Fonts
patcher:

```sh
docker pull nerdfonts/patcher
```

## References

- [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts)
- [MonoLisa feedback issue #333](https://github.com/MonoLisaFont/feedback/issues/333)
