#' Optimize keyboard layout using genetic algorithm
#'
#' Uses a genetic algorithm with a Carpalx-inspired effort model to find
#' an optimal keyboard layout for the given text samples. The algorithm
#' minimizes typing effort by considering finger travel distance, same-finger
#' bigrams, hand alternation, and row changes.
#'
#' @param text_samples Character vector of text samples to optimize for.
#'   The algorithm will use character frequencies and bigram patterns from
#'   these texts to evaluate layouts.
#' @param keyboard A keyboard data frame with columns `key`, `row`, `number`
#'   (column position), and optionally `x_mid`, `y_mid` for coordinates.
#'   If NULL, uses a default 30-key layout.
#' @param keys_to_optimize Character vector of keys to include in optimization.
#'   Default is lowercase letters a-z. Only these keys will be permuted.
#' @param fixed_keys Character vector of keys that should remain in their
#'   original positions. These keys will not be moved during optimization.
#'   Default is NULL (no fixed keys). For example, use `fixed_keys = c("a", "s", "d", "f")`
#'   to keep the left home row keys in place while optimizing all others.
#' @param population_size Number of individuals in the population. Default 100.
#' @param generations Number of generations to evolve. Default 500.
#' @param mutation_rate Probability of mutation per individual. Default 0.1.
#' @param crossover_rate Probability of crossover. Default 0.8.
#' @param tournament_size Size of tournament for selection. Default 5.
#' @param elite_count Number of best individuals to preserve each generation. Default 2.
#' @param effort_weights Named list of effort component weights:
#'   \itemize{
#'     \item \code{base}: Weight for base key effort (default 1.0)
#'     \item \code{same_finger}: Weight for same-finger bigram penalty (default 3.0)
#'     \item \code{same_hand}: Weight for same-hand bigram penalty (default 1.0)
#'     \item \code{row_change}: Weight for row change penalty (default 0.5)
#'   }
#' @param verbose Logical. Print progress every 50 generations? Default TRUE.
#'
#' @return A list with the following components:
#'   \describe{
#'     \item{layout}{Data frame with optimized layout including key positions and coordinates}
#'     \item{effort}{Final effort score of the optimized layout}
#'     \item{initial_effort}{Effort score of the starting layout}
#'     \item{improvement}{Percentage improvement over starting layout}
#'     \item{history}{Data frame with best and mean effort per generation}
#'     \item{parameters}{List of algorithm parameters used}
#'     \item{fixed_keys}{Character vector of keys that were held fixed}
#'     \item{n_fixed}{Number of fixed keys}
#'     \item{n_optimized}{Number of keys that were optimized}
#'   }
#'
#' @details
#' The effort model is inspired by Carpalx and considers:
#' \itemize{
#'   \item \strong{Base effort}: Each key has a base effort based on:
#'     \itemize{
#'       \item Row penalty (home row easiest, number row hardest)
#'       \item Finger strength (middle finger strongest, pinky weakest)
#'       \item Distance from home position
#'     }
#'   \item \strong{Same-finger bigrams}: Very high penalty when consecutive
#'     keys use the same finger (causes finger movement delays)
#'   \item \strong{Same-hand sequences}: Moderate penalty, with inward rolls
#'     (e.g., index to pinky) penalized less than outward rolls
#'   \item \strong{Row changes}: Penalty for reaching between rows on same hand
#' }
#'
#' The genetic algorithm uses:
#' \itemize{
#'   \item Order Crossover (OX) for recombination
#'   \item Swap, scramble, and inversion mutations
#'   \item Tournament selection
#'   \item Elitism to preserve best solutions
#' }
#'
#' When \code{fixed_keys} is specified, those keys remain in their original
#' positions and only the remaining keys are permuted during optimization.
#' This is useful for keeping commonly-used keys (like punctuation or
#' frequently-used letters) in familiar positions.
#'
#' @importFrom dplyr filter select mutate arrange
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Load sample texts
#' data(french)
#' data(luxembourguish)
#'
#' # Optimize for multiple languages
#' result <- optimize_layout(
#'   text_samples = c(french, luxembourguish),
#'   generations = 200,
#'   verbose = TRUE
#' )
#'
#' # View the optimized layout
#' print(result$layout)
#'
#' # Check improvement
#' cat("Improvement:", result$improvement, "%\n")
#'
#' # Optimize while keeping home row keys fixed
#' result_fixed <- optimize_layout(
#'   text_samples = french,
#'   fixed_keys = c("a", "s", "d", "f", "j", "k", "l"),
#'   generations = 200
#' )
#'
#' # Plot convergence
#' plot(result$history$generation, result$history$best,
#'      type = "l", xlab = "Generation", ylab = "Effort")
#' }
optimize_layout <- function(
    text_samples,
    keyboard = NULL,
    keys_to_optimize = letters,
    fixed_keys = NULL,
    population_size = 100,
    generations = 500,
    mutation_rate = 0.1,
    crossover_rate = 0.8,
    tournament_size = 5,
    elite_count = 2,
    effort_weights = list(
      base = 1.0,
      same_finger = 3.0,
      same_hand = 1.0,
      row_change = 0.5
    ),
    verbose = TRUE
) {
  # Validate inputs
  if (!is.character(text_samples) || length(text_samples) == 0) {
    stop("text_samples must be a non-empty character vector")
  }

  if (!is.character(keys_to_optimize) || length(keys_to_optimize) == 0) {
    stop("keys_to_optimize must be a non-empty character vector")
  }

  # Default keyboard layout (ISO layout letter keys)
  if (is.null(keyboard)) {
    keyboard <- create_default_keyboard()
  }

  # Filter keyboard to only keys we're optimizing
  keyboard_opt <- keyboard %>%
    dplyr::filter(tolower(key) %in% tolower(keys_to_optimize)) %>%
    dplyr::mutate(
      key = tolower(key),
      # Ensure we have x_mid and y_mid
      x_mid = if ("x_mid" %in% names(.)) x_mid else number,
      y_mid = if ("y_mid" %in% names(.)) y_mid else row
    )

  if (nrow(keyboard_opt) == 0) {
    stop("No matching keys found in keyboard layout")
  }

  # Calculate character frequencies from text samples
  combined_text <- paste(text_samples, collapse = " ")
  freq_df <- letter_freq(combined_text, only_alpha = TRUE)

  # Filter to keys we're optimizing
  freq_df <- freq_df %>%
    dplyr::filter(tolower(characters) %in% tolower(keys_to_optimize))

  # Prepare data for C++
  initial_layout <- keyboard_opt$key
  pos_x <- as.numeric(keyboard_opt$x_mid)
  pos_y <- as.numeric(keyboard_opt$y_mid)
  pos_row <- as.integer(keyboard_opt$row)
  pos_col <- as.integer(keyboard_opt$number)

  char_list <- as.character(freq_df$characters)
  char_freq <- as.numeric(freq_df$frequencies)

  # Calculate initial effort
  initial_effort <- layout_effort(
    layout = initial_layout,
    pos_x = pos_x,
    pos_y = pos_y,
    pos_row = pos_row,
    pos_col = pos_col,
    text_samples = text_samples,
    char_freq = char_freq,
    char_list = char_list,
    w_base = effort_weights$base,
    w_same_finger = effort_weights$same_finger,
    w_same_hand = effort_weights$same_hand,
    w_row_change = effort_weights$row_change
  )

  # Handle fixed keys
  fixed_positions <- rep(FALSE, length(initial_layout))
  if (!is.null(fixed_keys) && length(fixed_keys) > 0) {
    fixed_keys <- tolower(fixed_keys)
    fixed_positions <- tolower(initial_layout) %in% fixed_keys
  }

  n_fixed <- sum(fixed_positions)
  n_optimized <- length(initial_layout) - n_fixed

  if (verbose) {
    message("Starting optimization...")
    message("Initial effort: ", round(initial_effort, 2))
    message("Keys to optimize: ", n_optimized, " (", n_fixed, " fixed)")
    message("Text length: ", nchar(combined_text), " characters")
  }

  # Run genetic algorithm
  result <- optimize_keyboard_layout(
    initial_layout = as.character(initial_layout),
    pos_x = pos_x,
    pos_y = pos_y,
    pos_row = pos_row,
    pos_col = pos_col,
    text_samples = text_samples,
    char_freq = char_freq,
    char_list = char_list,
    population_size = as.integer(population_size),
    generations = as.integer(generations),
    mutation_rate = mutation_rate,
    crossover_rate = crossover_rate,
    tournament_size = as.integer(tournament_size),
    elite_count = as.integer(elite_count),
    w_base = effort_weights$base,
    w_same_finger = effort_weights$same_finger,
    w_same_hand = effort_weights$same_hand,
    w_row_change = effort_weights$row_change,
    verbose = verbose,
    fixed_positions = fixed_positions
  )

  # Create output layout data frame
  optimized_layout <- keyboard_opt
  optimized_layout$key <- as.character(result$layout)
  optimized_layout$key_label <- toupper(optimized_layout$key)

  # Calculate improvement
  improvement <- (initial_effort - result$effort) / initial_effort * 100

  if (verbose) {
    message("\nOptimization complete!")
    message("Final effort: ", round(result$effort, 2))
    message("Improvement: ", round(improvement, 2), "%")
  }

  # Create history data frame
  history <- data.frame(
    generation = seq_len(generations),
    best = result$history_best,
    mean = result$history_mean
  )

  list(
    layout = optimized_layout,
    effort = result$effort,
    initial_effort = initial_effort,
    improvement = improvement,
    history = history,
    parameters = list(
      population_size = population_size,
      generations = generations,
      mutation_rate = mutation_rate,
      crossover_rate = crossover_rate,
      tournament_size = tournament_size,
      elite_count = elite_count,
      effort_weights = effort_weights
    ),
    fixed_keys = if (!is.null(fixed_keys)) fixed_keys else character(0),
    n_fixed = n_fixed,
    n_optimized = n_optimized
  )
}


#' Calculate typing effort for a keyboard layout
#'
#' Computes the total typing effort for a given keyboard layout and text samples
#' using a Carpalx-inspired effort model.
#'
#' @param keyboard A keyboard data frame with columns `key`, `row`, `number`.
#' @param text_samples Character vector of text samples to evaluate.
#' @param keys_to_evaluate Character vector of keys to include. Default is lowercase letters.
#' @param effort_weights Named list of effort weights (see \code{\link{optimize_layout}}).
#' @param breakdown Logical. Return detailed breakdown of effort components? Default FALSE.
#'
#' @return If \code{breakdown = FALSE}, a single numeric value (total effort).
#'   If \code{breakdown = TRUE}, a list with effort components:
#'   \describe{
#'     \item{total_effort}{Total weighted effort}
#'     \item{base_effort}{Effort from individual key presses}
#'     \item{same_finger_effort}{Effort from same-finger bigrams}
#'     \item{same_hand_effort}{Effort from same-hand sequences}
#'     \item{row_change_effort}{Effort from row changes}
#'     \item{same_finger_bigrams}{Count of same-finger bigrams}
#'     \item{same_hand_bigrams}{Count of same-hand bigrams}
#'     \item{hand_alternations}{Count of hand alternations}
#'   }
#'
#' @importFrom dplyr filter mutate
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(afnor_bepo)
#' data(french)
#'
#' # Calculate effort for BEPO layout
#' effort <- calculate_layout_effort(afnor_bepo, french)
#' print(effort)
#'
#' # Get detailed breakdown
#' breakdown <- calculate_layout_effort(afnor_bepo, french, breakdown = TRUE)
#' print(breakdown)
#' }
calculate_layout_effort <- function(
    keyboard,
    text_samples,
    keys_to_evaluate = letters,
    effort_weights = list(
      base = 1.0,
      same_finger = 3.0,
      same_hand = 1.0,
      row_change = 0.5
    ),
    breakdown = FALSE
) {
  # Filter keyboard to keys we're evaluating
  keyboard_eval <- keyboard %>%
    dplyr::filter(tolower(key) %in% tolower(keys_to_evaluate)) %>%
    dplyr::mutate(
      key = tolower(key),
      x_mid = if ("x_mid" %in% names(.)) x_mid else number,
      y_mid = if ("y_mid" %in% names(.)) y_mid else row
    )

  if (nrow(keyboard_eval) == 0) {
    stop("No matching keys found in keyboard layout")
  }

  # Calculate frequencies
  combined_text <- paste(text_samples, collapse = " ")
  freq_df <- letter_freq(combined_text, only_alpha = TRUE) %>%
    dplyr::filter(tolower(characters) %in% tolower(keys_to_evaluate))

  # Prepare data
  layout <- keyboard_eval$key
  pos_x <- as.numeric(keyboard_eval$x_mid)
  pos_y <- as.numeric(keyboard_eval$y_mid)
  pos_row <- as.integer(keyboard_eval$row)
  pos_col <- as.integer(keyboard_eval$number)
  char_list <- as.character(freq_df$characters)
  char_freq <- as.numeric(freq_df$frequencies)

  if (breakdown) {
    effort_breakdown(
      layout = layout,
      pos_x = pos_x,
      pos_y = pos_y,
      pos_row = pos_row,
      pos_col = pos_col,
      text_samples = text_samples,
      char_freq = char_freq,
      char_list = char_list
    )
  } else {
    layout_effort(
      layout = layout,
      pos_x = pos_x,
      pos_y = pos_y,
      pos_row = pos_row,
      pos_col = pos_col,
      text_samples = text_samples,
      char_freq = char_freq,
      char_list = char_list,
      w_base = effort_weights$base,
      w_same_finger = effort_weights$same_finger,
      w_same_hand = effort_weights$same_hand,
      w_row_change = effort_weights$row_change
    )
  }
}


#' Compare effort across multiple keyboard layouts
#'
#' Calculate and compare typing effort for multiple keyboard layouts.
#'
#' @param keyboards Named list of keyboard data frames to compare.
#' @param text_samples Character vector of text samples.
#' @param keys_to_evaluate Character vector of keys to include. Default is lowercase letters.
#' @param effort_weights Named list of effort weights.
#'
#' @return A data frame with layout names and their effort scores, sorted by effort.
#'
#' @importFrom dplyr arrange
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(afnor_bepo)
#' data(afnor_azerty)
#' data(ch_qwertz)
#' data(french)
#'
#' comparison <- compare_layouts(
#'   keyboards = list(
#'     BEPO = afnor_bepo,
#'     AZERTY = afnor_azerty,
#'     QWERTZ = ch_qwertz
#'   ),
#'   text_samples = french
#' )
#' print(comparison)
#' }
compare_layouts <- function(
    keyboards,
    text_samples,
    keys_to_evaluate = letters,
    effort_weights = list(
      base = 1.0,
      same_finger = 3.0,
      same_hand = 1.0,
      row_change = 0.5
    )
) {
  if (!is.list(keyboards) || is.null(names(keyboards))) {
    stop("keyboards must be a named list of keyboard data frames")
  }

  results <- lapply(names(keyboards), function(name) {
    effort <- calculate_layout_effort(
      keyboard = keyboards[[name]],
      text_samples = text_samples,
      keys_to_evaluate = keys_to_evaluate,
      effort_weights = effort_weights,
      breakdown = FALSE
    )
    data.frame(
      layout = name,
      effort = effort,
      stringsAsFactors = FALSE
    )
  })

  result_df <- do.call(rbind, results)
  result_df$rank <- rank(result_df$effort)
  result_df$relative <- result_df$effort / min(result_df$effort) * 100

  dplyr::arrange(result_df, effort)
}


#' Create a default keyboard layout for optimization
#'
#' Creates a standard ISO keyboard layout data frame with 30 letter key positions.
#'
#' @return A data frame with columns: key, row, number, x_mid, y_mid
#'
#' @export
create_default_keyboard <- function() {
  # Standard QWERTY layout positions for ISO keyboard
  # Row 1: top letter row (QWERTYUIOP)
  # Row 2: home row (ASDFGHJKL;)
  # Row 3: bottom letter row (ZXCVBNM,.)

  # QWERTY layout as default starting point
  qwerty <- c(
    "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
    "a", "s", "d", "f", "g", "h", "j", "k", "l",
    "z", "x", "c", "v", "b", "n", "m"
  )

  rows <- c(
    rep(1, 10),  # top row
    rep(2, 9),   # home row
    rep(3, 7)    # bottom row
  )

  numbers <- c(
    1:10,        # top row positions
    1:9,         # home row positions
    1:7          # bottom row positions
  )

  # Calculate approximate x_mid and y_mid based on ISO layout
  # Home row is offset slightly from top row
  # Bottom row is offset slightly from home row
  x_offset <- c(0, 0.25, 0.5)  # row offsets

  x_mid <- numbers + x_offset[rows]
  y_mid <- rows

  data.frame(
    key = qwerty,
    key_label = toupper(qwerty),
    row = rows,
    number = numbers,
    x_mid = x_mid,
    y_mid = y_mid,
    stringsAsFactors = FALSE
  )
}


#' Convert optimized layout to full keyboard format
#'
#' Takes an optimized layout and merges it back into a full keyboard data frame,
#' suitable for visualization with \code{\link{ggkeyboard}}.
#'
#' @param optimized_layout The layout data frame from \code{\link{optimize_layout}}.
#' @param base_keyboard Full keyboard data frame to merge into.
#'
#' @return A complete keyboard data frame with optimized letter positions.
#'
#' @importFrom dplyr left_join select mutate coalesce
#'
#' @export
layout_to_keyboard <- function(optimized_layout, base_keyboard) {
  # Create mapping from position to new key
  position_map <- optimized_layout %>%
    dplyr::select(row, number, new_key = key, new_label = key_label)

  # Update base keyboard
  base_keyboard %>%
    dplyr::left_join(position_map, by = c("row", "number")) %>%
    dplyr::mutate(
      key = dplyr::coalesce(new_key, key),
      key_label = dplyr::coalesce(new_label, key_label)
    ) %>%
    dplyr::select(-new_key, -new_label)
}
