# Compile rules for optimizer

Internal function that compiles a list of rule objects into the format
expected by the C++ optimizer.

## Usage

``` r
compile_rules(rules, layout, keyboard)
```

## Arguments

- rules:

  List of rule objects created by rule builder functions.

- layout:

  Character vector of initial layout (26 keys).

- keyboard:

  Keyboard data frame with position info.

## Value

A list with compiled rule data for C++.
