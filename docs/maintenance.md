# Maintenance

## Troubleshooting

Run the local doctor first when setup is unclear:

```sh
./scripts/doctor.sh
```

It checks Docker, input fonts, output/log paths, and whether the pinned patcher
image is already available locally. It does not run the patcher, pull images, or
write generated fonts.

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

The wrapper is the preferred build path. If you need to run Docker manually,
copy the input fonts to a temporary working directory first and mount that
directory as `/in`:

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

## Patcher Image Updates

Normal builds use a pinned image digest from `scripts/patch.sh`. This keeps
builds reproducible and avoids an implicit network dependency.

Check whether the pinned patcher image differs from the latest upstream image:

```sh
./scripts/check-patcher-update.sh
```

The check pulls `nerdfonts/patcher:latest`, compares its digest with the pinned
digest in `scripts/patch.sh`, and prints a test command if a newer image is
available.

You can also pull a fresh patcher image manually:

```sh
docker pull nerdfonts/patcher:latest
```

After testing a newer image, update `NERD_FONTS_PATCHER_IMAGE` or the pinned
digest in `scripts/patch.sh` if you want the repository default to change.
