# Parse a PKL layout.ini file

Reads a Portable Keyboard Layout (PKL) configuration file and extracts
the keyboard layout for each layer (shift state).

## Usage

``` r
parse_layout_ini(file_path, layer = NULL, include_special = FALSE)
```

## Arguments

- file_path:

  Path to the layout.ini file.

- layer:

  Which layer to extract. Default is NULL which returns all layers.

  - NULL: Return all layers as a named list of data frames

  - 0: Base layer (no modifier)

  - 1: Shift layer

  - 2: Ctrl layer (usually not used for character input)

  - 3: AltGr layer (6 in PKL notation)

  - 4: AltGr+Shift layer (7 in PKL notation)

- include_special:

  Logical. Include non-letter keys (punctuation, etc.)? Default FALSE.

## Value

If layer is NULL, a named list with elements: base, shift, ctrl, altgr,
altgr_shift. Each element is a data frame with columns: key, key_label,
row, number, x_mid, y_mid, scancode. Additionally, the list has a
'metadata' element with layout name, code, and version. If layer is
specified (0-4), returns a single data frame for that layer.

## Details

PKL layout.ini files use scan codes (SC010, SC011, etc.) to define key
positions. The shift states are defined in the `[global]` section as
`shiftstates = 0:1:2:6:7`.

Standard scan code mapping:

- SC010-SC01b: Top row (Q to \])

- SC01e-SC02b: Home row (A to ')

- SC02c-SC035: Bottom row (Z to /)

- SC056: ISO key (left of Z on ISO keyboards)

## Examples

``` r
if (FALSE) { # \dontrun{
# Parse all layers
layout <- parse_layout_ini("layouts/qwertz-lux/layout.ini")
print(layout$base)      # Base layer
print(layout$altgr)     # AltGr layer
print(layout$metadata)  # Layout name, version, etc.

# Parse a single layer (backward compatible)
base_only <- parse_layout_ini("layouts/qwertz-lux/layout.ini", layer = 0)
altgr_only <- parse_layout_ini("layouts/qwertz-lux/layout.ini", layer = 3)

# Plot the layout
plot_layout_ini("layouts/qwertz-lux/layout.ini")
} # }
```
