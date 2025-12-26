# Plot keyboard layout using ggkeyboard

Visualizes a keyboard layout using the ggkeyboard plotting function.

## Usage

``` r
plot_layout(layout, base_keyboard = sixty_percent, ...)
```

## Arguments

- layout:

  A character vector of 26 letters in layout order, or a data frame from
  [`optimize_layout`](https://b-rodrigues.github.io/lbkeyboard/reference/optimize_layout.md)
  with a `key` column.

- base_keyboard:

  Base keyboard to use for visualization. Default is `sixty_percent`.

- ...:

  Additional arguments passed to
  [`ggkeyboard`](https://b-rodrigues.github.io/lbkeyboard/reference/ggkeyboard.md).

## Value

A ggplot2 object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Plot QWERTY layout
plot_layout(letters)

# Plot optimized layout with custom palette
result <- optimize_layout(text_samples = french, generations = 100)
plot_layout(result$layout, palette = keyboard_palette("cyberpunk"))
} # }
```
