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

  if (length(keys) != 26) {
    stop("Layout must have exactly 26 keys (letters a-z)")
  }

  if (uppercase) {
    keys <- toupper(keys)
  }

  # Split into rows
  top_row <- keys[1:10]
  home_row <- keys[11:19]
  bottom_row <- keys[20:26]

  # Build ASCII keyboard
  # Top row (10 keys)
  cat("\u250c", paste(rep("\u2500\u2500\u2500\u252c", 9), collapse = ""), "\u2500\u2500\u2500\u2510\n", sep = "")
  cat("\u2502", paste(" ", top_row, " \u2502", sep = "", collapse = ""), "\n", sep = "")

  # Home row (9 keys) - offset slightly
  cat("\u251c", paste(rep("\u2500\u2500\u2500\u253c", 8), collapse = ""), "\u2500\u2500\u2500\u2518\n", sep = "")
  cat("\u2502", paste(" ", home_row, " \u2502", sep = "", collapse = ""), "\n", sep = "")

  # Bottom row (7 keys) - offset more
  cat("\u251c", paste(rep("\u2500\u2500\u2500\u253c", 6), collapse = ""), "\u2500\u2500\u2500\u2518\n", sep = "")
  cat("\u2502", paste(" ", bottom_row, " \u2502", sep = "", collapse = ""), "\n", sep = "")
  cat("\u2514", paste(rep("\u2500\u2500\u2500\u2534", 6), collapse = ""), "\u2500\u2500\u2500\u2518\n", sep = "")

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
      layout_df <- create_default_keyboard()
      layout_df$key <- as.character(layout$layout)
      layout_df$key_label <- toupper(layout_df$key)
    }
  } else {
    # Character vector input
    keys <- as.character(layout)
    if (length(keys) != 26) {
      stop("Layout must have exactly 26 keys (letters a-z)")
    }
    layout_df <- create_default_keyboard()
    layout_df$key <- keys
    layout_df$key_label <- toupper(keys)
  }

  # Merge with base keyboard
  keyboard <- layout_to_keyboard(layout_df, base_keyboard)

  # Plot
  ggkeyboard(keyboard, ...)
}
