# Print keyboard layout in ASCII format

Displays a keyboard layout as an ASCII art representation in the
console. Shows the standard 3-row letter keyboard layout.

## Usage

``` r
print_layout(layout, uppercase = TRUE)
```

## Arguments

- layout:

  A character vector of 26 letters in layout order (top row 10 keys,
  home row 9 keys, bottom row 7 keys), or a data frame from
  [`optimize_layout`](https://b-rodrigues.github.io/lbkeyboard/reference/optimize_layout.md)
  with a `key` column.

- uppercase:

  Logical. Display keys in uppercase? Default TRUE.

## Value

Invisibly returns the layout keys.

## Examples

``` r
if (FALSE) { # \dontrun{
# Print QWERTY layout
qwerty <- c("q","w","e","r","t","y","u","i","o","p",
            "a","s","d","f","g","h","j","k","l",
            "z","x","c","v","b","n","m")
print_layout(qwerty)

# Print optimized layout
result <- optimize_layout(text_samples = french, generations = 100)
print_layout(result$layout)
} # }
```
