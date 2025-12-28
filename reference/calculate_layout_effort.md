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
  breakdown = FALSE,
  layer_map = NULL,
  altgr_penalty = 1.2,
  shift_penalty = 1.05,
  deadkey_penalty = 1.4
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

- layer_map:

  Named numeric vector mapping characters to their layer. Layer 0 =
  direct access (no penalty), Layer 1 = Shift, Layer 2 = AltGr, Layer 3
  = Dead key (2 keystrokes, e.g., dead trema + o = ö). Characters not in
  layer_map are assumed to be on layer 0. Example: `c("è" = 2, "ï" = 3)`
  means è is on AltGr, ï via dead key.

- altgr_penalty:

  Numeric. Effort multiplier for characters on AltGr layer (layer 2).
  Default 1.2 (20% extra effort).

- shift_penalty:

  Numeric. Effort multiplier for characters on Shift layer (layer 1).
  Default 1.05 (5% extra effort).

- deadkey_penalty:

  Numeric. Effort multiplier for dead key combinations (layer 3).
  Default 1.4 (40% extra effort for 2 keystrokes).

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

- layer_effort:

  Additional effort from layer penalties (if layer_map provided)

## Examples

``` r
if (FALSE) { # \dontrun{
data(afnor_bepo)
data(french)

# Calculate effort for BEPO layout
effort <- calculate_layout_effort(afnor_bepo, french)
print(effort)

# Calculate with layer penalties for accents on different layers
layer_map <- c("è" = 2, "ü" = 2, "ö" = 2, "à" = 2, "ï" = 3)  # ï via dead key
effort <- calculate_layout_effort(afnor_bepo, french, layer_map = layer_map)

# Get detailed breakdown
breakdown <- calculate_layout_effort(afnor_bepo, french, breakdown = TRUE)
print(breakdown)
} # }
```
