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

To see the wrapper inputs, outputs, environment variables, and docs:

```sh
./scripts/patch.sh --help
```

To check local prerequisites without running the patcher:

```sh
./scripts/doctor.sh
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

## More Documentation

- [Patcher options](docs/patcher-options.md): default flags, common upstream
  flags, and pass-through examples.
- [Maintenance](docs/maintenance.md): troubleshooting, manual Docker usage, and
  patcher image update checks.
- [Vercel web UI plan](docs/vercel-web-ui-plan.md): hosted UI architecture and
  rollout plan.

## References

- [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts)
- [MonoLisa feedback issue #333](https://github.com/MonoLisaFont/feedback/issues/333)
