# Prefer keys on specific fingers

Creates a soft preference for placing specified keys on particular
fingers. Finger indices: 0=left pinky, 1=left ring, 2=left middle,
3=left index, 6=right index, 7=right middle, 8=right ring, 9=right
pinky.

## Usage

``` r
prefer_finger(keys, fingers, weight = 1)
```

## Arguments

- keys:

  Character vector of keys.

- fingers:

  Integer vector of target finger indices.

- weight:

  Penalty weight. Default 1.0.

## Value

A rule object of class "layout_rule".
