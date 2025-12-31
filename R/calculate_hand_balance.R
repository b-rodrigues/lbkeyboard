#' Calculate hand balance for a keyboard layout
#'
#' Calculates the percentage of keystrokes performed by the left and right hands
#' based on a keyboard layout and letter frequencies.
#'
#' @param kb A keyboard layout data frame (must contain `key` and `number` columns).
#' @param freq_df A data frame with `characters` and `frequencies` columns.
#' @param threshold Integer. The column index where the split occurs. Keys with
#'   `number < threshold` are assigned to the left hand. If NULL (default),
#'   the threshold is adaptively determined based on the minimum column index
#'   (5 for 0-based indexing, 6 for 1-based indexing).
#'
#' @return A string formatted as "Left%/Right%".
#' @export
#'
#' @examples
#' data("ch_qwertz")
#' data("english")
#' freq <- letter_freq(english)
#' calculate_hand_balance(ch_qwertz, freq)
calculate_hand_balance <- function(kb, freq_df, threshold = NULL) {
  # Match keys to their frequencies
  kb_lower <- tolower(kb$key)
  fre_lower <- tolower(freq_df$characters)
  
  left_freq <- 0
  right_freq <- 0
  
  # Determine column start to adapt threshold if not provided
  # Left hand covers 5 letter keys (columns 2-6 in 1-based, or 1-5 in 0-based)
  # Right hand covers the rest (columns 7+ in 1-based, or 6+ in 0-based)
  if (is.null(threshold)) {
    if (nrow(kb) > 0) {
      min_col <- min(kb$number, na.rm = TRUE)
      # For 1-based indexing (min_col == 1): threshold = 7 (left = 2-6, right = 7+)
      # For 0-based indexing (min_col == 0): threshold = 6 (left = 1-5, right = 6+)
      threshold <- if (min_col == 0) 6 else 7
    } else {
      threshold <- 7
    }
  }
  
  for (i in seq_len(nrow(kb))) {
    key <- kb_lower[i]
    col <- kb$number[i]
    
    # Skip if column info is missing
    if (is.na(col)) next
    
    # Find frequency for this key
    freq_idx <- which(fre_lower == key)
    if (length(freq_idx) > 0) {
      key_freq <- freq_df$frequencies[freq_idx[1]]
      if (col < threshold) {
        left_freq <- left_freq + key_freq
      } else {
        right_freq <- right_freq + key_freq
      }
    }
  }
  
  total <- left_freq + right_freq
  if (total > 0) {
    left_pct <- round(left_freq / total * 100, 1)
    right_pct <- round(right_freq / total * 100, 1)
  } else {
    left_pct <- 50
    right_pct <- 50
  }
  
  paste0(left_pct, "/", right_pct)
}
