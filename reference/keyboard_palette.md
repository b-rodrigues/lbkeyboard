# Keyboard palettes

Built-in palettes for keyboards.

## Usage

``` r
keyboard_palette(
  palette = c("pastel", "serika", "wahtsy", "cyberpunk", "magic", "varmilo", "t0mb3ry")
)
```

## Arguments

- palette:

  Name of palette.

## Details

There are four palettes available:

- "pastel" is just cute.

- "serika" is based off the [Drop + Zambumon MT3 Serika Custom Keycap
  Set](https://drop.com/buy/drop-zambumon-mt3-serika-custom-keycap-set).

- "wahtsy" is based off the [Melgeek MG Wahtsy ABS Doubleshot Keycap
  Set](https://drop.com/buy/melgeek-mg-wahtsy-abs-doubleshot-keycap-set).

- "cyberpunk" is based off the [Domikey ABS Doubleshot SA Cyberpunk
  Pumper Keycap
  Set](https://drop.com/buy/domikey-abs-doubleshot-sa-cyberpunk-pumper-keycap-set).

- "magic" is based off the [Apple magic
  keyboard](https://www.apple.com/shop/product/MLA22LL/A/magic-keyboard-us-english).

- "varmilo" is based off the [Varmilo VA108 Fullsize
  Keyboard](https://drop.com/buy/varmilo-108-keyboard).

- "t0mb3ry" is based off the [Drop + T0mb3ry SA Yuri Custom Keycap
  Set](https://drop.com/buy/drop-t0mb3ry-sa-yuri-custom-keycap-set)

The palettes have the following fields:

- background: Colour of background.

- keyboard: Colour of keyboard.

- alphanumeric: Colour of alpha-numeric keys and other common text keys
  (e.g. \<, :, etc).

- accent: Colour of accent keys (F1-4, F9-12, and the spacebar).

- modifier: Colour of modifier keys (e.g. Shift, Print, Insert, etc).

- numpad: Colour of numpad (non-modifier) keys (1-9).

- arrow: Colour of arrow-pad keys.

- light: Colour of lights on the keyboards.

- text: Text colour.

## Examples

``` r
if (FALSE) { # \dontrun{
library(scales)
show_col(keyboard_palette("pastel"))

ggkeyboard(palette = keyboard_palette("cyberpunk"))
} # }
```
