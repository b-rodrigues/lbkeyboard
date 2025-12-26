# Balance hand usage

Creates a soft preference for balanced typing load between hands. Adds a
penalty when the hand distribution deviates from the target.

## Usage

``` r
balance_hands(target = 0.5, weight = 1)
```

## Arguments

- target:

  Target proportion for left hand (0 to 1). Default 0.5 for equal
  balance.

- weight:

  Penalty weight. Higher values enforce stricter balance. Default 1.0.

## Value

A rule object of class "layout_rule".

## Examples

``` r
if (FALSE) { # \dontrun{
# Aim for 50/50 hand balance
rule <- balance_hands(0.5, weight = 2.0)

# Slight preference for right hand (40% left, 60% right)
rule <- balance_hands(0.4, weight = 1.0)
} # }
```
