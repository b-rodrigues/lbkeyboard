# Plot a keyboard using ggplot2. Originally from ggkeyboard

Plot a keyboard using ggplot2. Originally from ggkeyboard

## Usage

``` r
ggkeyboard(
  keyboard = tkl,
  palette = keyboard_palette("pastel"),
  layout = c("ansi", "iso"),
  font_family = "Arial Unicode MS",
  font_size = 2,
  adjust_text_colour = TRUE,
  measurements = keyboard_measurements("default")
)
```

## Arguments

- keyboard:

  Keyboard data. A data frame with the key name, what row of the
  keyboard it is in, and key width. Defaults to `tkl` (a tenkeyless
  layout). Other available keyboards are a full keyboard (`full`), 60%
  keyboard (`sixty_percent`), and a basic mac keyboard (`mac`).

- palette:

  Colour palette. Defaults to `keyboard_palette("pastel")`. To use a
  custom palette, create a vector with the names described in
  [`keyboard_palette`](https://b-rodrigues.github.io/lbkeyboard/reference/keyboard_palette.md).

- layout:

  Keyboard layout - one of "ansi" or "iso". Defaults to "ansi".

- font_family:

  Font used. Defaults to "Arial Unicode MS". See the `extrafont` package
  for using fonts in ggplot2.

- font_size:

  Base font size. Defaults to 3.

- adjust_text_colour:

  Whether to lighten the text colour on dark keys. Defaults to TRUE.

- measurements:

  Measurements of various aspects of the keyboard key height and width,
  gaps between keys and rows, etc. See
  [`keyboard_measurements`](https://b-rodrigues.github.io/lbkeyboard/reference/keyboard_measurements.md).

## Examples

``` r
if (FALSE) { # \dontrun{
ggkeyboard()

ggkeyboard(sixty_percent, palette = keyboard_palette("cyberpunk"))
} # }
```
