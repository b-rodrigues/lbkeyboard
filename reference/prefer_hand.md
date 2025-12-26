# Prefer keys on a specific hand

Creates a soft preference for placing specified keys on the left or
right hand. A penalty is added to the effort score when keys are not on
the preferred hand.

## Usage

``` r
prefer_hand(keys, hand = c("left", "right"), weight = 1)
```

## Arguments

- keys:

  Character vector of keys that should prefer this hand.

- hand:

  Which hand: "left" or "right".

- weight:

  Penalty weight. Higher values make this preference stronger. Default
  1.0.

## Value

A rule object of class "layout_rule".

## Examples

``` r
if (FALSE) { # \dontrun{
# Prefer vowels on left hand
rule <- prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 2.0)
} # }
```
