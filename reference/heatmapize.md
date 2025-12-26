# Colours the keys of the keyboard according the relative frequency of characters appearing in a text.

Colours the keys of the keyboard according the relative frequency of
characters appearing in a text.

## Usage

``` r
heatmapize(keyboard, letter_freq_df, low = "light green", high = "red")
```

## Arguments

- keyboard:

  A dataframe holding a keyboard specification

- letter_freq_df:

  A dataframe with relative frequencies of characters. Output of
  [`letter_freq()`](https://b-rodrigues.github.io/lbkeyboard/reference/letter_freq.md)

- low:

  A colour specification for low frequencies. Can be a hex colour code
  or one of the inbuilt colours. Defaults to "light green".

- high:

  A colour specification for high frequencies. Can be a hex colour code
  or one of the inbuilt colours. Defaults to "red".

## Value

The original keyboard dataframe but with an adjusted `fill` column,
which colours each character according to its relative frequency.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create some random string
data("french")
letter_freq_df <- letter_freq(french)
heatmap_azerty <- heatmapize(afnor_azerty, letter_freq_df)
} # }
```
