# Create QWERTZ-LUX keyboard layout

Creates the QWERTZ-LUX keyboard layout optimized for Luxembourg's
multilingual environment. This layout includes direct access to the most
frequent accented characters (é, ä, ë, ç) on the three letter rows.

## Usage

``` r
create_qwertz_lux_keyboard()
```

## Value

A list with class "qwertz_lux_layout" containing:

- base: Data frame of base layer keys (compatible with
  heatmapize/ggkeyboard)

- altgr: Data frame of AltGr layer keys

- metadata: List with layout name and info

## Details

Layout structure:

- TOP ROW (11 keys): Q W F O G Z U K L P J

- HOME ROW (12 keys): A S D E , H N T R I M É

- BOTTOM ROW (10 keys): Y X C V B . Ä ' Ë Ç

Direct accent access:

- é (home row): Most frequent accent (French)

- ä (bottom row): German/Luxembourgish

- ë (bottom row): Luxembourgish

- ç (bottom row): French

Additional accents via AltGr or dead keys (use layer_map):

- è, à, ü, ö: AltGr layer (layer 2)

- ê, â, ô, î, û, ï: Dead key combinations (layer 3)

## Examples

``` r
kb <- create_qwertz_lux_keyboard()
#> Error in create_qwertz_lux_keyboard(): could not find function "create_qwertz_lux_keyboard"
# Use base layer for heatmap
# heatmap <- heatmapize(kb$base, letter_freq_df)
# ggkeyboard(heatmap)
```
