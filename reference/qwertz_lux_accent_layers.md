# QWERTZ-LUX accent layer map

A named numeric vector defining which layer each accented character is
on for the QWERTZ-LUX keyboard layout. The most frequent accents (é, ä,
ë, ç) are NOT in this map because they have direct access (layer 0).

## Usage

``` r
qwertz_lux_accent_layers
```

## Format

A named numeric vector where names are accented characters and values
are layer numbers (2 = AltGr, 3 = dead key).

## Details

Characters with direct access (not in this map):

- é: Home row (most frequent accent)

- ä: Bottom row (German/Luxembourgish)

- ë: Bottom row (Luxembourgish)

- ç: Bottom row (French)

Characters on AltGr layer (20% penalty):

- è, à, ü, ö

Characters via dead keys (40% penalty):

- ê, â, ô, î, û, ï

## Examples

``` r
# Use with calculate_layout_effort()
kb <- create_qwertz_lux_keyboard()
#> Error in create_qwertz_lux_keyboard(): could not find function "create_qwertz_lux_keyboard"
data(french)
effort <- calculate_layout_effort(
  kb, french,
  keys_to_evaluate = c(letters, "é", "ä", "ë", "ç"),
  layer_map = qwertz_lux_accent_layers
)
#> Error in calculate_layout_effort(kb, french, keys_to_evaluate = c(letters,     "é", "ä", "ë", "ç"), layer_map = qwertz_lux_accent_layers): unused argument (layer_map = qwertz_lux_accent_layers)
```
