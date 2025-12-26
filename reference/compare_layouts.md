# Compare effort across multiple keyboard layouts

Calculate and compare typing effort for multiple keyboard layouts.

## Usage

``` r
compare_layouts(
  keyboards,
  text_samples,
  keys_to_evaluate = letters,
  effort_weights = list(base = 1, same_finger = 3, same_hand = 1, row_change = 0.5,
    trigram = 0.3)
)
```

## Arguments

- keyboards:

  Named list of keyboard data frames to compare.

- text_samples:

  Character vector of text samples.

- keys_to_evaluate:

  Character vector of keys to include. Default is lowercase letters.

- effort_weights:

  Named list of effort weights.

## Value

A data frame with layout names and their effort scores, sorted by
effort.

## Examples

``` r
if (FALSE) { # \dontrun{
data(afnor_bepo)
data(afnor_azerty)
data(ch_qwertz)
data(french)

comparison <- compare_layouts(
  keyboards = list(
    BEPO = afnor_bepo,
    AZERTY = afnor_azerty,
    QWERTZ = ch_qwertz
  ),
  text_samples = french
)
print(comparison)
} # }
```
