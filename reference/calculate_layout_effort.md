# Calculate typing effort for a keyboard layout

Computes the total typing effort for a given keyboard layout and text
samples using a Carpalx-inspired effort model.

## Usage

``` r
calculate_layout_effort(
  keyboard,
  text_samples,
  keys_to_evaluate = letters,
  effort_weights = list(base = 3, same_finger = 3, same_hand = 0.5, row_change = 0.5,
    trigram = 0.3),
  breakdown = FALSE
)
```

## Arguments

- keyboard:

  A keyboard data frame with columns `key`, `row`, `number`.

- text_samples:

  Character vector of text samples to evaluate.

- keys_to_evaluate:

  Character vector of keys to include. Default is lowercase letters.

- effort_weights:

  Named list of effort weights (see
  [`optimize_layout`](https://b-rodrigues.github.io/lbkeyboard/reference/optimize_layout.md)).

- breakdown:

  Logical. Return detailed breakdown of effort components? Default
  FALSE.

## Value

If `breakdown = FALSE`, a single numeric value (total effort). If
`breakdown = TRUE`, a list with effort components:

- total_effort:

  Total weighted effort

- base_effort:

  Effort from individual key presses

- same_finger_effort:

  Effort from same-finger bigrams

- same_hand_effort:

  Effort from same-hand sequences

- row_change_effort:

  Effort from row changes

- same_finger_bigrams:

  Count of same-finger bigrams

- same_hand_bigrams:

  Count of same-hand bigrams

- hand_alternations:

  Count of hand alternations

## Examples

``` r
if (FALSE) { # \dontrun{
data(afnor_bepo)
data(french)

# Calculate effort for BEPO layout
effort <- calculate_layout_effort(afnor_bepo, french)
print(effort)

# Get detailed breakdown
breakdown <- calculate_layout_effort(afnor_bepo, french, breakdown = TRUE)
print(breakdown)
} # }
```
