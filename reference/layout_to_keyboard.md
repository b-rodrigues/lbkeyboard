# Convert optimized layout to full keyboard format

Takes an optimized layout and merges it back into a full keyboard data
frame, suitable for visualization with
[`ggkeyboard`](https://b-rodrigues.github.io/lbkeyboard/reference/ggkeyboard.md).

## Usage

``` r
layout_to_keyboard(optimized_layout, base_keyboard)
```

## Arguments

- optimized_layout:

  The layout data frame from
  [`optimize_layout`](https://b-rodrigues.github.io/lbkeyboard/reference/optimize_layout.md).

- base_keyboard:

  Full keyboard data frame to merge into.

## Value

A complete keyboard data frame with optimized letter positions.
