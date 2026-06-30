# Patcher Options

`scripts/patch.sh` forwards any extra arguments to the upstream Nerd Fonts
`font-patcher`.

For example:

```sh
./scripts/patch.sh --debug
```

## Wrapper Defaults

The wrapper always passes these options:

- `--complete`: include the full Nerd Fonts glyph set.
- `--careful`: avoid overwriting existing glyphs in the source font.
- `--quiet`: suppress routine glyph-copy logging.
- `--no-progressbars`: keep build logs readable.

## Common Upstream Options

These upstream options are useful with this project:

- `--debug`: print more detail when diagnosing naming or patching issues.
- `--dry`: check patcher naming without writing generated fonts.
- `--adjust-line-height`: adjust line heights to center Powerline separators.
- `--mono`: create monospaced output and single-width added glyphs.
- `--single-width-glyphs`: keep the source font metrics but make added glyphs
  single-width.
- `--variable-width-glyphs`: avoid adjusting glyph advance widths.
- `--extension ttf|otf`: choose the generated font file type.

Avoid exposing every upstream option in normal use. Some patcher options are for
unusual font metadata, custom glyph sources, or debugging specific failures.

See the upstream
[`font-patcher`](https://github.com/ryanoasis/nerd-fonts/blob/master/font-patcher)
source for the complete flag list.
