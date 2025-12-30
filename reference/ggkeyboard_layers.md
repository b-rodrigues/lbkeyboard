# Plot multiple layers of a PKL layout

Creates a grid of keyboard plots showing multiple layers of a PKL
layout.

## Usage

``` r
ggkeyboard_layers(
  x,
  layers = c("base", "altgr"),
  ncol = 2,
  palette = keyboard_palette("pastel"),
  ...
)
```

## Arguments

- x:

  Either a file path to a layout.ini file or a pkl_layout object.

- layers:

  Which layers to plot. Default is c("base", "altgr"). Options: "base",
  "shift", "ctrl", "altgr", "altgr_shift", or "all".

- ncol:

  Number of columns in the plot grid. Default is 2.

- palette:

  Color palette to use. Default is keyboard_palette("pastel").

- ...:

  Additional arguments passed to
  [`ggkeyboard`](https://b-rodrigues.github.io/lbkeyboard/reference/ggkeyboard.md).

## Value

A combined ggplot2 object using patchwork.

## Examples

``` r
if (FALSE) { # \dontrun{
# Plot base and AltGr layers side by side
ggkeyboard_layers("layouts/qwertz-lux/layout.ini")

# Plot all layers
ggkeyboard_layers("layouts/qwertz-lux/layout.ini", layers = "all", ncol = 3)

# Parse first, then plot selected layers
layout <- parse_layout_ini("layouts/qwertz-lux/layout.ini")
ggkeyboard_layers(layout, layers = c("base", "shift", "altgr"))
} # }
```
