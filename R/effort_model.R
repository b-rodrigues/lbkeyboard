# effort_model.R
# Pure R implementation of the Carpalx-inspired effort model
# Replaces the C++ implementation in genetic_keyboard.cpp

# -----------------------------------------------------------------
# FINGER ASSIGNMENT AND HAND DETECTION
# -----------------------------------------------------------------

#' Get finger assignment based on x-position (layout-independent)
#'
#' @param x_mid X-coordinate of the key center
#' @param min_x Minimum x-coordinate on the keyboard
#' @param max_x Maximum x-coordinate on the keyboard
#' @return Finger index (0-9: left pinky to right pinky)
#' @noRd
get_finger_for_x_position <- function(x_mid, min_x, max_x) {
  center <- (min_x + max_x) / 2
  width <- max_x - min_x

  # Normalize position relative to center: -1 to +1
  rel_pos <- (x_mid - center) / (width / 2)

  # Vectorized finger assignment
  finger <- ifelse(rel_pos < 0,
    # Left hand (negative): -1.0 to 0.0
    ifelse(-rel_pos > 0.75, 0,  # far left = left pinky
    ifelse(-rel_pos > 0.50, 1,  # left ring
    ifelse(-rel_pos > 0.25, 2,  # left middle
    3))),                        # left index
    # Right hand (positive): 0.0 to 1.0
    ifelse(rel_pos < 0.25, 6,   # right index
    ifelse(rel_pos < 0.50, 7,   # right middle
    ifelse(rel_pos < 0.75, 8,   # right ring
    9)))                         # right pinky
  )

  as.integer(finger)
}

#' Get hand for a finger
#'
#' @param finger Finger index (0-9)
#' @return Hand (0 = left, 1 = right)
#' @noRd
get_hand_for_finger <- function(finger) {
  as.integer(finger > 4)
}

# -----------------------------------------------------------------
# CARPALX-INSPIRED PENALTY FUNCTIONS
# -----------------------------------------------------------------

#' Row penalty - difficulty of reaching each row
#'
#' @param row Row number (0=number, 1=top, 2=home, 3=bottom)
#' @return Penalty value
#' @noRd
row_penalty <- function(row) {
  # Vectorized lookup
  penalties <- c(
    `0` = 3.0,  # Number row - far reach (hardest)
    `1` = 1.2,  # Top row - easy reach upward
    `2` = 0.5,  # Home row - MUCH better (2.4x better than top)
    `3` = 2.0   # Bottom row - harder (curling fingers under)
  )

  result <- penalties[as.character(row)]
  result[is.na(result)] <- 2.5  # default
  as.numeric(result)
}

#' Finger strength/dexterity penalty
#'
#' @param finger Finger index (0-9)
#' @return Penalty value (weaker fingers = higher penalty)
#' @noRd
finger_penalty <- function(finger) {
  # Pinkies are weakest, index fingers strongest
  # Left: 0(P), 1(R), 2(M), 3(I), 4(I)
  # Right: 5(I), 6(I), 7(M), 8(R), 9(P)

  ifelse(finger == 0 | finger == 9, 2.2,   # Pinky (weakest)
  ifelse(finger == 1 | finger == 8, 1.4,   # Ring
  ifelse(finger == 2 | finger == 7, 1.0,   # Middle
  ifelse(finger >= 3 & finger <= 6, 0.85,  # Index (strongest)
  1.5))))  # Fallback
}

#' Distance from home position penalty (x-position based)
#'
#' @param x_mid X-coordinate of the key
#' @param finger Finger index
#' @param min_x Minimum x-coordinate
#' @param max_x Maximum x-coordinate
#' @return Penalty value
#' @noRd
home_distance_penalty_x <- function(x_mid, finger, min_x, max_x) {
  center <- (min_x + max_x) / 2
  width <- max_x - min_x
  rel_pos <- (x_mid - center) / (width / 2)  # -1 to +1

  # Define home position (resting position) for each finger
  home_positions <- c(
    `0` = -0.875,  # left pinky (far left)
    `1` = -0.625,  # left ring
    `2` = -0.375,  # left middle
    `3` = -0.125,  # left index
    `6` = 0.125,   # right index
    `7` = 0.375,   # right middle
    `8` = 0.625,   # right ring
    `9` = 0.875    # right pinky (far right)
  )

  home_pos <- home_positions[as.character(finger)]
  home_pos[is.na(home_pos)] <- rel_pos[is.na(home_pos)]

  # Distance from home position
  dist <- abs(rel_pos - home_pos)

  # Normalize: dist of 0.25 = 1 finger zone away
  normalized_dist <- dist / 0.25

  1.0 + 0.3 * normalized_dist  # 30% penalty per zone away from home
}

#' Base effort for a single key (x-position based)
#'
#' @param row Row number
#' @param x_mid X-coordinate
#' @param finger Finger index
#' @param min_x Minimum x-coordinate
#' @param max_x Maximum x-coordinate
#' @return Base effort value
#' @noRd
base_key_effort_x <- function(row, x_mid, finger, min_x, max_x) {
  row_penalty(row) * finger_penalty(finger) *
    home_distance_penalty_x(x_mid, finger, min_x, max_x)
}

# -----------------------------------------------------------------
# BIGRAM PENALTIES
# -----------------------------------------------------------------

#' Same-finger bigram penalty
#'
#' @param row1 Row of first key
#' @param row2 Row of second key
#' @param col1 Column of first key
#' @param col2 Column of second key
#' @return Penalty value
#' @noRd
same_finger_penalty <- function(row1, row2, col1, col2) {
  row_dist <- abs(row1 - row2)
  col_dist <- abs(col1 - col2)
  dist <- sqrt(row_dist^2 + col_dist^2)
  3.0 + 2.0 * dist  # Base penalty plus distance
}

#' Same-hand bigram penalty
#'
#' @param row1 Row of first key
#' @param row2 Row of second key
#' @param col1 Column of first key
#' @param col2 Column of second key
#' @param finger1 Finger for first key
#' @param finger2 Finger for second key
#' @return Penalty value
#' @noRd
same_hand_penalty <- function(row1, row2, col1, col2, finger1, finger2) {
  # If same finger, handled separately
  if (finger1 == finger2) return(0.0)

  # Same hand, different fingers
  # Inward rolls (index to pinky) are easier than outward rolls
  is_left <- finger1 <= 4
  dir <- finger2 - finger1

  # Inward roll on left hand = decreasing finger, on right = increasing
  is_inward <- (is_left && dir < 0) || (!is_left && dir > 0)

  if (is_inward) {
    0.5  # Small penalty for inward roll (comfortable)
  } else {
    1.2  # Larger penalty for outward roll
  }
}

#' Row change penalty
#'
#' @param row1 Row of first key
#' @param row2 Row of second key
#' @return Penalty value
#' @noRd
row_change_penalty <- function(row1, row2) {
  diff <- abs(row1 - row2)
  if (diff == 0) return(0.0)
  if (diff == 1) return(0.3)
  0.6 * diff  # Larger jumps are harder
}

# -----------------------------------------------------------------
# TRIGRAM PENALTIES
# -----------------------------------------------------------------

#' Same-hand trigram penalty
#'
#' @param finger1 First finger
#' @param finger2 Second finger
#' @param finger3 Third finger
#' @param is_left TRUE if left hand
#' @return Penalty value
#' @noRd
same_hand_trigram_penalty <- function(finger1, finger2, finger3, is_left) {
  dir1 <- finger2 - finger1
  dir2 <- finger3 - finger2

  # Monotonic sequences (all inward or all outward) are acceptable
  # Mixed direction sequences are awkward
  if ((dir1 > 0 && dir2 > 0) || (dir1 < 0 && dir2 < 0)) {
    0.5  # Monotonic - relatively comfortable
  } else {
    2.0  # Direction change - awkward
  }
}

# -----------------------------------------------------------------
# MAIN EFFORT CALCULATION
# -----------------------------------------------------------------

#' Calculate typing effort for a layout
#'
#' Pure R implementation of the Carpalx-inspired effort model.
#'
#' @param layout Character vector of keys at each position
#' @param pos_x Numeric vector of x-coordinates
#' @param pos_y Numeric vector of y-coordinates
#' @param pos_row Integer vector of row numbers
#' @param pos_col Integer vector of column numbers
#' @param text_samples Character vector of text samples
#' @param char_freq Numeric vector of character frequencies
#' @param char_list Character vector of characters corresponding to char_freq
#' @param w_base Weight for base key effort (default 1.0)
#' @param w_same_finger Weight for same-finger bigram penalty (default 3.0)
#' @param w_same_hand Weight for same-hand bigram penalty (default 1.0)
#' @param w_row_change Weight for row change penalty (default 0.5)
#' @param w_trigram Weight for same-hand trigram penalty (default 0.3)
#'
#' @return Total typing effort score
#' @export
layout_effort <- function(
    layout,
    pos_x,
    pos_y,
    pos_row,
    pos_col,
    text_samples,
    char_freq,
    char_list,
    w_base = 1.0,
    w_same_finger = 3.0,
    w_same_hand = 1.0,
    w_row_change = 0.5,
    w_trigram = 0.3
) {
  n <- length(layout)

  # Build character -> position mapping
  layout_lower <- tolower(layout)
  char_to_pos <- setNames(seq_len(n), layout_lower)

  # Also add uppercase mappings
  layout_upper <- toupper(layout)
  uppercase_mask <- layout_lower != layout_upper
  char_to_pos_upper <- setNames(seq_len(n)[uppercase_mask], layout_upper[uppercase_mask])
  char_to_pos <- c(char_to_pos, char_to_pos_upper)

  # Calculate finger assignments based on x position
  min_x <- min(pos_x)
  max_x <- max(pos_x)

  fingers <- get_finger_for_x_position(pos_x, min_x, max_x)
  hands <- get_hand_for_finger(fingers)

  # Combine text samples
  combined_text <- paste(text_samples, collapse = " ")
  text_len <- nchar(combined_text)

  total_effort <- 0.0

  # Base effort (weighted by character frequency)
  for (i in seq_along(char_list)) {
    c <- tolower(char_list[i])
    pos <- char_to_pos[c]
    if (!is.na(pos)) {
      base <- base_key_effort_x(pos_row[pos], pos_x[pos], fingers[pos], min_x, max_x)
      total_effort <- total_effort + w_base * base * char_freq[i] * text_len
    }
  }

  # Process text for bigram and trigram penalties
  # Convert to lowercase and filter to known characters
  text_chars <- strsplit(tolower(combined_text), "")[[1]]

  prev_prev_pos <- NA
  prev_pos <- NA

  for (char in text_chars) {
    curr_pos <- char_to_pos[char]
    if (is.na(curr_pos)) next

    # Bigram processing
    if (!is.na(prev_pos)) {
      finger1 <- fingers[prev_pos]
      finger2 <- fingers[curr_pos]
      hand1 <- hands[prev_pos]
      hand2 <- hands[curr_pos]

      # Same finger penalty
      if (finger1 == finger2 && prev_pos != curr_pos) {
        total_effort <- total_effort + w_same_finger * same_finger_penalty(
          pos_row[prev_pos], pos_row[curr_pos],
          pos_col[prev_pos], pos_col[curr_pos]
        )
      } else if (hand1 == hand2) {
        # Same hand penalty
        total_effort <- total_effort + w_same_hand * same_hand_penalty(
          pos_row[prev_pos], pos_row[curr_pos],
          pos_col[prev_pos], pos_col[curr_pos],
          finger1, finger2
        )
        total_effort <- total_effort + w_row_change * row_change_penalty(
          pos_row[prev_pos], pos_row[curr_pos]
        )
      }
      # Hand alternation (preferred - no penalty)
    }

    # Trigram processing
    if (!is.na(prev_prev_pos) && !is.na(prev_pos)) {
      hand0 <- hands[prev_prev_pos]
      hand1 <- hands[prev_pos]
      hand2 <- hands[curr_pos]

      # Only penalize if all three keys are on the same hand
      if (hand0 == hand1 && hand1 == hand2) {
        is_left <- hand0 == 0
        total_effort <- total_effort + w_trigram * same_hand_trigram_penalty(
          fingers[prev_prev_pos], fingers[prev_pos], fingers[curr_pos], is_left
        )
      }
    }

    prev_prev_pos <- prev_pos
    prev_pos <- curr_pos
  }

  total_effort
}


#' Get detailed effort breakdown for a layout
#'
#' @inheritParams layout_effort
#'
#' @return A list with effort components:
#' \describe{
#'   \item{base_effort}{Effort from individual key presses}
#'   \item{same_finger_effort}{Effort from same-finger bigrams}
#'   \item{same_hand_effort}{Effort from same-hand sequences}
#'   \item{row_change_effort}{Effort from row changes}
#'   \item{trigram_effort}{Effort from same-hand trigrams}
#'   \item{total_effort}{Total weighted effort}
#'   \item{same_finger_bigrams}{Count of same-finger bigrams}
#'   \item{same_hand_bigrams}{Count of same-hand bigrams}
#'   \item{hand_alternations}{Count of hand alternations}
#'   \item{same_hand_trigrams}{Count of same-hand trigrams}
#' }
#' @export
effort_breakdown <- function(
    layout,
    pos_x,
    pos_y,
    pos_row,
    pos_col,
    text_samples,
    char_freq,
    char_list
) {
  n <- length(layout)

  # Build character -> position mapping
  layout_lower <- tolower(layout)
  char_to_pos <- setNames(seq_len(n), layout_lower)

  # Also add uppercase mappings
  layout_upper <- toupper(layout)
  uppercase_mask <- layout_lower != layout_upper
  char_to_pos_upper <- setNames(seq_len(n)[uppercase_mask], layout_upper[uppercase_mask])
  char_to_pos <- c(char_to_pos, char_to_pos_upper)

  # Calculate finger assignments
  min_x <- min(pos_x)
  max_x <- max(pos_x)

  fingers <- get_finger_for_x_position(pos_x, min_x, max_x)
  hands <- get_hand_for_finger(fingers)

  # Combine text samples
  combined_text <- paste(text_samples, collapse = " ")
  text_len <- nchar(combined_text)

  # Initialize effort components
  base_effort <- 0.0
  same_finger_effort <- 0.0
  same_hand_effort <- 0.0
  row_change_effort <- 0.0
  trigram_effort <- 0.0
  same_finger_count <- 0L
  same_hand_count <- 0L
  hand_alternation_count <- 0L
  trigram_count <- 0L

  # Base effort calculation
  for (i in seq_along(char_list)) {
    c <- tolower(char_list[i])
    pos <- char_to_pos[c]
    if (!is.na(pos)) {
      base_effort <- base_effort +
        base_key_effort_x(pos_row[pos], pos_x[pos], fingers[pos], min_x, max_x) *
        char_freq[i] * text_len
    }
  }

  # Process text for bigram and trigram analysis
  text_chars <- strsplit(tolower(combined_text), "")[[1]]

  prev_prev_pos <- NA
  prev_pos <- NA

  for (char in text_chars) {
    curr_pos <- char_to_pos[char]
    if (is.na(curr_pos)) next

    # Bigram analysis
    if (!is.na(prev_pos)) {
      finger1 <- fingers[prev_pos]
      finger2 <- fingers[curr_pos]
      hand1 <- hands[prev_pos]
      hand2 <- hands[curr_pos]

      if (finger1 == finger2 && prev_pos != curr_pos) {
        same_finger_count <- same_finger_count + 1L
        same_finger_effort <- same_finger_effort + same_finger_penalty(
          pos_row[prev_pos], pos_row[curr_pos],
          pos_col[prev_pos], pos_col[curr_pos]
        )
      } else if (hand1 == hand2) {
        same_hand_count <- same_hand_count + 1L
        same_hand_effort <- same_hand_effort + same_hand_penalty(
          pos_row[prev_pos], pos_row[curr_pos],
          pos_col[prev_pos], pos_col[curr_pos],
          finger1, finger2
        )
        row_change_effort <- row_change_effort + row_change_penalty(
          pos_row[prev_pos], pos_row[curr_pos]
        )
      } else {
        hand_alternation_count <- hand_alternation_count + 1L
      }
    }

    # Trigram analysis
    if (!is.na(prev_prev_pos) && !is.na(prev_pos)) {
      hand0 <- hands[prev_prev_pos]
      hand1 <- hands[prev_pos]
      hand2 <- hands[curr_pos]

      if (hand0 == hand1 && hand1 == hand2) {
        trigram_count <- trigram_count + 1L
        is_left <- hand0 == 0
        trigram_effort <- trigram_effort + same_hand_trigram_penalty(
          fingers[prev_prev_pos], fingers[prev_pos], fingers[curr_pos], is_left
        )
      }
    }

    prev_prev_pos <- prev_pos
    prev_pos <- curr_pos
  }

  # Total with default weights matching C++ implementation
  total_effort <- base_effort +
    3.0 * same_finger_effort +
    same_hand_effort +
    0.5 * row_change_effort +
    0.3 * trigram_effort

  list(
    base_effort = base_effort,
    same_finger_effort = same_finger_effort,
    same_hand_effort = same_hand_effort,
    row_change_effort = row_change_effort,
    trigram_effort = trigram_effort,
    total_effort = total_effort,
    same_finger_bigrams = same_finger_count,
    same_hand_bigrams = same_hand_count,
    hand_alternations = hand_alternation_count,
    same_hand_trigrams = trigram_count
  )
}


#' Generate a random layout permutation
#'
#' @param keys Character vector of keys to permute
#' @return Character vector with randomized order
#' @export
random_layout <- function(keys) {
  sample(keys)
}
