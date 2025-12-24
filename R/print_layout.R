#' Print keyboard layout in ASCII format
#'
#' Displays a keyboard layout as an ASCII art representation in the console.
#' Shows the standard 3-row letter keyboard layout.
#'
#' @param layout A character vector of 26 letters in layout order
#'   (top row 10 keys, home row 9 keys, bottom row 7 keys),
#'   or a data frame from \code{\link{optimize_layout}} with a `key` column.
#' @param uppercase Logical. Display keys in uppercase? Default TRUE.
#'
#' @return Invisibly returns the layout keys.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Print QWERTY layout
#' qwerty <- c("q","w","e","r","t","y","u","i","o","p",
#'             "a","s","d","f","g","h","j","k","l",
#'             "z","x","c","v","b","n","m")
#' print_layout(qwerty)
#'
#' # Print optimized layout
#' result <- optimize_layout(text_samples = french, generations = 100)
#' print_layout(result$layout)
#' }
print_layout <- function(layout, uppercase = TRUE) {
  # Extract keys from various input types
  if (is.data.frame(layout)) {
    if ("key" %in% names(layout)) {
      keys <- as.character(layout$key)
    } else {
      stop("Data frame must have a 'key' column")
    }
  } else if (is.list(layout) && "layout" %in% names(layout)) {
    # Handle optimize_layout() result directly
    if (is.data.frame(layout$layout)) {
      keys <- as.character(layout$layout$key)
    } else {
      keys <- as.character(layout$layout)
    }
  } else {
    keys <- as.character(layout)
  }

  # Support both 26-key (standard) and 30-key (extended with accents) layouts
  if (length(keys) == 26) {
    # Standard layout: 10 + 9 + 7
    top_count <- 10
    home_count <- 9
    bottom_count <- 7
  } else if (length(keys) == 30) {
    # Extended layout with accents: 11 + 10 + 9
    top_count <- 11
    home_count <- 10
    bottom_count <- 9
  } else {
    stop("Layout must have 26 keys (standard) or 30 keys (extended with accents)")
  }

  if (uppercase) {
    keys <- toupper(keys)
  }

  # Split into rows
  top_row <- keys[1:top_count]
  home_row <- keys[(top_count + 1):(top_count + home_count)]
  bottom_row <- keys[(top_count + home_count + 1):length(keys)]

  # Build ASCII keyboard
  # Top row
  cat("\u250c", paste(rep("\u2500\u2500\u2500\u252c", top_count - 1), collapse = ""), "\u2500\u2500\u2500\u2510\n", sep = "")
  cat("\u2502", paste(" ", top_row, " \u2502", sep = "", collapse = ""), "\n", sep = "")

  # Home row - offset slightly
  cat("\u251c", paste(rep("\u2500\u2500\u2500\u253c", home_count - 1), collapse = ""), "\u2500\u2500\u2500\u2518\n", sep = "")
  cat("\u2502", paste(" ", home_row, " \u2502", sep = "", collapse = ""), "\n", sep = "")

  # Bottom row - offset more
  cat("\u251c", paste(rep("\u2500\u2500\u2500\u253c", bottom_count - 1), collapse = ""), "\u2500\u2500\u2500\u2518\n", sep = "")
  cat("\u2502", paste(" ", bottom_row, " \u2502", sep = "", collapse = ""), "\n", sep = "")
  cat("\u2514", paste(rep("\u2500\u2500\u2500\u2534", bottom_count - 1), collapse = ""), "\u2500\u2500\u2500\u2518\n", sep = "")

  invisible(keys)
}


#' Plot keyboard layout using ggkeyboard
#'
#' Visualizes a keyboard layout using the ggkeyboard plotting function.
#'
#' @param layout A character vector of 26 letters in layout order,
#'   or a data frame from \code{\link{optimize_layout}} with a `key` column.
#' @param base_keyboard Base keyboard to use for visualization.
#'   Default is \code{sixty_percent}.
#' @param ... Additional arguments passed to \code{\link{ggkeyboard}}.
#'
#' @return A ggplot2 object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Plot QWERTY layout
#' plot_layout(letters)
#'
#' # Plot optimized layout with custom palette
#' result <- optimize_layout(text_samples = french, generations = 100)
#' plot_layout(result$layout, palette = keyboard_palette("cyberpunk"))
#' }
plot_layout <- function(layout, base_keyboard = sixty_percent, ...) {
  # Extract keys from various input types
  if (is.data.frame(layout)) {
    if ("key" %in% names(layout)) {
      layout_df <- layout
    } else {
      stop("Data frame must have a 'key' column")
    }
  } else if (is.list(layout) && "layout" %in% names(layout)) {
    # Handle optimize_layout() result directly
    if (is.data.frame(layout$layout)) {
      layout_df <- layout$layout
    } else {
      # Character vector result - need to create data frame
      keys <- as.character(layout$layout)
      if (length(keys) == 30) {
        layout_df <- create_extended_keyboard()
      } else {
        layout_df <- create_default_keyboard()
      }
      layout_df$key <- keys
      layout_df$key_label <- toupper(keys)
    }
  } else {
    # Character vector input
    keys <- as.character(layout)
    if (length(keys) == 30) {
      layout_df <- create_extended_keyboard()
    } else if (length(keys) == 26) {
      layout_df <- create_default_keyboard()
    } else {
      stop("Layout must have 26 keys (standard) or 30 keys (extended)")
    }
    layout_df$key <- keys
    layout_df$key_label <- toupper(keys)
  }

  # Merge with base keyboard
  keyboard <- layout_to_keyboard(layout_df, base_keyboard)

  # Plot
  ggkeyboard(keyboard, ...)
}
