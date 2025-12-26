# Create an extended keyboard layout with accented characters

Creates a 30-key keyboard layout including the 26 standard letters plus
the 4 most common accented characters for French, German, and
Luxembourgish: é, è, ä, ü. This is inspired by BÉPO which places é and è
on the home row.

## Usage

``` r
create_extended_keyboard()
```

## Value

A data frame with 30 rows and columns: key, key_label, row, number,
x_mid, y_mid

## Details

The layout has:

- Row 1: 11 keys (10 letters + 1 accent)

- Row 2: 10 keys (9 letters + 1 accent) - home row

- Row 3: 9 keys (7 letters + 2 accents)

Accented character placements:

- é: Row 2 position 9 (right pinky, home row - most frequent accent)

- è: Row 1 position 10 (right pinky, top row)

- ä: Row 3 position 7 (right ring finger)

- ü: Row 3 position 8 (right pinky)

## Examples

``` r
kb <- create_extended_keyboard()
#> Warning: input string 'è' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'é' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'ä' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'ü' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'è' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'é' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'ä' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'ü' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
nrow(kb)  # 30
#> [1] 30
```
