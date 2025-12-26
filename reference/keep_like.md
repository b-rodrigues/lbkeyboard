# Keep keys like a reference layout

Creates a soft preference for keeping specified keys in the same
position as a reference layout. Useful for keeping familiar key
positions.

## Usage

``` r
keep_like(reference, keys = NULL, weight = 1)
```

## Arguments

- reference:

  Character vector of 26 keys representing the reference layout, or a
  named layout like "qwerty".

- keys:

  Character vector of keys to match (default: all keys in reference).

- weight:

  Penalty weight per mismatched key. Default 1.0.

## Value

A rule object of class "layout_rule".

## Examples

``` r
if (FALSE) { # \dontrun{
# Keep number row like QWERTY
rule <- keep_like("qwerty", c("z", "x", "c", "v"), weight = 5.0)
} # }
```
