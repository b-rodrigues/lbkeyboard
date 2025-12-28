# Standard QWERTZ accent layer map

A named numeric vector defining which layer each accented character is
on for a standard QWERTZ keyboard. All accents require AltGr (layer 2)
or dead key combinations (layer 3).

## Usage

``` r
qwertz_accent_layers
```

## Format

A named numeric vector where names are accented characters and values
are layer numbers (2 = AltGr, 3 = dead key).

## Details

Layer meanings:

- 0 = Direct access (no modifier)

- 1 = Shift layer

- 2 = AltGr layer (20% effort penalty)

- 3 = Dead key (40% effort penalty)

## Examples

``` r
# Use with calculate_layout_effort()
data(ch_qwertz)
data(french)
effort <- calculate_layout_effort(
  ch_qwertz, french,
  keys_to_evaluate = letters,
  layer_map = qwertz_accent_layers
)
#> Error in calculate_layout_effort(ch_qwertz, french, keys_to_evaluate = letters,     layer_map = qwertz_accent_layers): unused argument (layer_map = qwertz_accent_layers)
```
