# Prefer keys on a specific row

Creates a soft preference for placing specified keys on a particular
row. Row 1 = top (QWERTY), Row 2 = home (ASDF), Row 3 = bottom (ZXCV).

## Usage

``` r
prefer_row(keys, row, weight = 1)
```

## Arguments

- keys:

  Character vector of keys that should prefer this row.

- row:

  Target row: 1 (top), 2 (home), or 3 (bottom).

- weight:

  Penalty weight. Higher values make this preference stronger. Default
  1.0.

## Value

A rule object of class "layout_rule".

## Examples

``` r
if (FALSE) { # \dontrun{
# Prefer common letters on home row
rule <- prefer_row(c("e", "t", "a", "o", "n"), 2, weight = 1.5)
} # }
```
