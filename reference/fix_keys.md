# Fix keys in their initial positions

Creates a hard constraint that prevents specified keys from moving
during optimization. Useful for keeping shortcut keys (Z, X, C, V) in
familiar positions.

## Usage

``` r
fix_keys(keys)
```

## Arguments

- keys:

  Character vector of keys to fix in place.

## Value

A rule object of class "layout_rule".

## Examples

``` r
if (FALSE) { # \dontrun{
# Keep Ctrl shortcut keys in place
rule <- fix_keys(c("z", "x", "c", "v"))
} # }
```
