# Plot a PKL layout

Plots a Portable Keyboard Layout from a file path or parsed pkl_layout
object.

## Usage

``` r
plot_layout_ini(x, layer = "base", palette = keyboard_palette("pastel"), ...)
```

## Arguments

- x:

  Either a file path to a layout.ini file, a pkl_layout object from
  [`parse_layout_ini`](https://b-rodrigues.github.io/lbkeyboard/reference/parse_layout_ini.md),
  or a single layer data frame.

- layer:

  Which layer to plot. Default is "base". Can be: "base", "shift",
  "ctrl", "altgr", "altgr_shift" or 0-4.

- palette:

  Color palette to use. Default is keyboard_palette("pastel").

- ...:

  Additional arguments passed to
  [`ggkeyboard`](https://b-rodrigues.github.io/lbkeyboard/reference/ggkeyboard.md).

## Value

A ggplot2 object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Plot from file path
plot_layout_ini("layouts/qwertz-lux/layout.ini")

# Plot AltGr layer
plot_layout_ini("layouts/qwertz-lux/layout.ini", layer = "altgr")

# Parse first, then plot
layout <- parse_layout_ini("layouts/qwertz-lux/layout.ini")
plot_layout_ini(layout, layer = "base")
plot_layout_ini(layout, layer = "altgr", palette = keyboard_palette("cyberpunk"))
} # }
```
