# List available layouts in a directory

Finds all layout.ini files in a given directory and its subdirectories.

## Usage

``` r
list_layouts(path = NULL)
```

## Arguments

- path:

  Directory to search for layout.ini files. Default is "layouts"
  subdirectory of the current package.

## Value

A character vector of paths to layout.ini files.

## Examples

``` r
if (FALSE) { # \dontrun{
# List layouts in the package
layouts <- list_layouts()
print(layouts)
} # }
```
