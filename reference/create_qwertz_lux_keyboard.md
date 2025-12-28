# Create QWERTZ-LUX keyboard layout

Creates the QWERTZ-LUX keyboard layout optimized for Luxembourg's
multilingual environment. This layout includes direct access to the most
frequent accented characters (é, ä, ë, ç) on the three letter rows.

## Usage

``` r
create_qwertz_lux_keyboard()
```

## Value

A data frame with 34 keys (26 letters + 4 accents + comma + period +
apostrophe + É) and columns: key, key_label, row, number, x_mid, y_mid

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
nrow(kb)  # 33
#> Error: object 'kb' not found
```
