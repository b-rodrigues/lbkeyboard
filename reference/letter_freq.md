# Counts the frequency of each letter in a string of text

Counts the frequency of each letter in a string of text

## Usage

``` r
letter_freq(text, only_alpha = TRUE)
```

## Arguments

- text:

  A string

- only_alpha:

  TRUE (default) or FALSE. Should only letters be considered? If FALSE,
  every character is taken into account.

## Value

A dataframe with 4 columns. `characters` contains the characters;
`total` the total number of times the characters appears in the text,
`scaled` is the min-max transform of `total` and `frequencies` are the
relative frequencies of appearance of each letter.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create some random string
data("french")
letter_freq(french)
} # }
```
