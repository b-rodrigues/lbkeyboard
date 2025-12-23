#' Rule Builder Functions for Keyboard Layout Optimization
#'
#' These functions create rule objects that can be passed to \code{\link{optimize_layout}}
#' to customize the optimization with constraints and preferences.
#'
#' @name layout_rules
#' @rdname layout_rules
NULL

#' Fix keys in their initial positions
#'
#' Creates a hard constraint that prevents specified keys from moving
#' during optimization. Useful for keeping shortcut keys (Z, X, C, V)
#' in familiar positions.
#'
#' @param keys Character vector of keys to fix in place.
#'
#' @return A rule object of class "layout_rule".
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Keep Ctrl shortcut keys in place
#' rule <- fix_keys(c("z", "x", "c", "v"))
#' }
fix_keys <- function(keys) {
  if (!is.character(keys) || length(keys) == 0) {
    stop("keys must be a non-empty character vector")
  }
  structure(list(
    type = "fix",
    keys = tolower(keys)
  ), class = "layout_rule")
}


#' Prefer keys on a specific hand
#'
#' Creates a soft preference for placing specified keys on the left or right hand.
#' A penalty is added to the effort score when keys are not on the preferred hand.
#'
#' @param keys Character vector of keys that should prefer this hand.
#' @param hand Which hand: "left" or "right".
#' @param weight Penalty weight. Higher values make this preference stronger. Default 1.0.
#'
#' @return A rule object of class "layout_rule".
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Prefer vowels on left hand
#' rule <- prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 2.0)
#' }
prefer_hand <- function(keys, hand = c("left", "right"), weight = 1.0) {
  hand <- match.arg(hand)
  if (!is.character(keys) || length(keys) == 0) {
    stop("keys must be a non-empty character vector")
  }
  if (!is.numeric(weight) || weight < 0) {
    stop("weight must be a non-negative number")
  }
  structure(list(
    type = "prefer_hand",
    keys = tolower(keys),
    hand = hand,
    weight = weight
  ), class = "layout_rule")
}


#' Prefer keys on a specific row
#'
#' Creates a soft preference for placing specified keys on a particular row.
#' Row 1 = top (QWERTY), Row 2 = home (ASDF), Row 3 = bottom (ZXCV).
#'
#' @param keys Character vector of keys that should prefer this row.
#' @param row Target row: 1 (top), 2 (home), or 3 (bottom).
#' @param weight Penalty weight. Higher values make this preference stronger. Default 1.0.
#'
#' @return A rule object of class "layout_rule".
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Prefer common letters on home row
#' rule <- prefer_row(c("e", "t", "a", "o", "n"), 2, weight = 1.5)
#' }
prefer_row <- function(keys, row, weight = 1.0) {
  if (!is.character(keys) || length(keys) == 0) {
    stop("keys must be a non-empty character vector")
  }
  if (!row %in% c(1, 2, 3)) {
    stop("row must be 1 (top), 2 (home), or 3 (bottom)")
  }
  if (!is.numeric(weight) || weight < 0) {
    stop("weight must be a non-negative number")
  }
  structure(list(
    type = "prefer_row",
    keys = tolower(keys),
    row = as.integer(row),
    weight = weight
  ), class = "layout_rule")
}


#' Prefer keys on specific fingers
#'
#' Creates a soft preference for placing specified keys on particular fingers.
#' Finger indices: 0=left pinky, 1=left ring, 2=left middle, 3=left index,
#' 6=right index, 7=right middle, 8=right ring, 9=right pinky.
#'
#' @param keys Character vector of keys.
#' @param fingers Integer vector of target finger indices.
#' @param weight Penalty weight. Default 1.0.
#'
#' @return A rule object of class "layout_rule".
#'
#' @export
prefer_finger <- function(keys, fingers, weight = 1.0) {
  if (!is.character(keys) || length(keys) == 0) {
    stop("keys must be a non-empty character vector")
  }
  if (!all(fingers %in% 0:9)) {
    stop("fingers must be integers 0-9")
  }
  structure(list(
    type = "prefer_finger",
    keys = tolower(keys),
    fingers = as.integer(fingers),
    weight = weight
  ), class = "layout_rule")
}


#' Balance hand usage
#'
#' Creates a soft preference for balanced typing load between hands.
#' Adds a penalty when the hand distribution deviates from the target.
#'
#' @param target Target proportion for left hand (0 to 1). Default 0.5 for equal balance.
#' @param weight Penalty weight. Higher values enforce stricter balance. Default 1.0.
#'
#' @return A rule object of class "layout_rule".
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Aim for 50/50 hand balance
#' rule <- balance_hands(0.5, weight = 2.0)
#'
#' # Slight preference for right hand (40% left, 60% right)
#' rule <- balance_hands(0.4, weight = 1.0)
#' }
balance_hands <- function(target = 0.5, weight = 1.0) {
  if (!is.numeric(target) || target < 0 || target > 1) {
    stop("target must be a number between 0 and 1")
  }
  if (!is.numeric(weight) || weight < 0) {
    stop("weight must be a non-negative number")
  }
  structure(list(
    type = "balance_hands",
    target = target,
    weight = weight
  ), class = "layout_rule")
}


#' Keep keys like a reference layout
#'
#' Creates a soft preference for keeping specified keys in the same position
#' as a reference layout. Useful for keeping familiar key positions.
#'
#' @param reference Character vector of 26 keys representing the reference layout,
#'   or a named layout like "qwerty".
#' @param keys Character vector of keys to match (default: all keys in reference).
#' @param weight Penalty weight per mismatched key. Default 1.0.
#'
#' @return A rule object of class "layout_rule".
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Keep number row like QWERTY
#' rule <- keep_like("qwerty", c("z", "x", "c", "v"), weight = 5.0)
#' }
keep_like <- function(reference, keys = NULL, weight = 1.0) {
  # Handle named layouts
  if (is.character(reference) && length(reference) == 1) {
    reference <- switch(tolower(reference),
      "qwerty" = c("q","w","e","r","t","y","u","i","o","p",
                   "a","s","d","f","g","h","j","k","l",
                   "z","x","c","v","b","n","m"),
      stop("Unknown layout name: ", reference)
    )
  }

  if (length(reference) != 26) {
    stop("reference must be a 26-character layout or a layout name")
  }

  if (is.null(keys)) {
    keys <- reference
  }

  structure(list(
    type = "keep_like",
    reference = tolower(reference),
    keys = tolower(keys),
    weight = weight
  ), class = "layout_rule")
}


#' Compile rules for optimizer
#'
#' Internal function that compiles a list of rule objects into the format
#' expected by the C++ optimizer.
#'
#' @param rules List of rule objects created by rule builder functions.
#' @param layout Character vector of initial layout (26 keys).
#' @param keyboard Keyboard data frame with position info.
#'
#' @return A list with compiled rule data for C++.
#'
#' @keywords internal
compile_rules <- function(rules, layout, keyboard) {
  if (is.null(rules) || length(rules) == 0) {
    return(list(
      fixed_positions = rep(FALSE, length(layout)),
      hand_pref_indices = integer(0),
      hand_pref_targets = integer(0),
      hand_pref_weight = 0.0,
      row_pref_indices = integer(0),
      row_pref_targets = integer(0),
      row_pref_weight = 0.0,
      balance_target = 0.5,
      balance_weight = 0.0,
      keep_like_ref = character(0),
      keep_like_indices = integer(0),
      keep_like_weight = 0.0
    ))
  }

  # Validate all rules
  for (rule in rules) {
    if (!inherits(rule, "layout_rule")) {
      stop("All rules must be created by rule builder functions (fix_keys, prefer_hand, etc.)")
    }
  }

  # Initialize outputs
  n_keys <- length(layout)
  fixed_positions <- rep(FALSE, n_keys)
  layout_lower <- tolower(layout)

  # Hand preference data
  hand_pref_indices <- integer(0)
  hand_pref_targets <- integer(0)
  hand_pref_weight <- 0.0

  # Row preference data
  row_pref_indices <- integer(0)
  row_pref_targets <- integer(0)
  row_pref_weight <- 0.0

  # Balance data
  balance_target <- 0.5
  balance_weight <- 0.0

  # Keep-like data
  keep_like_ref <- character(0)
  keep_like_indices <- integer(0)
  keep_like_weight <- 0.0

  # Process each rule
  for (rule in rules) {
    switch(rule$type,
      "fix" = {
        # Mark keys as fixed
        for (key in rule$keys) {
          idx <- which(layout_lower == key)
          if (length(idx) > 0) {
            fixed_positions[idx] <- TRUE
          }
        }
      },

      "prefer_hand" = {
        hand_target <- if (rule$hand == "left") 0L else 1L
        for (key in rule$keys) {
          idx <- which(layout_lower == key)
          if (length(idx) > 0) {
            hand_pref_indices <- c(hand_pref_indices, idx - 1L)  # 0-indexed
            hand_pref_targets <- c(hand_pref_targets, hand_target)
          }
        }
        hand_pref_weight <- max(hand_pref_weight, rule$weight)
      },

      "prefer_row" = {
        for (key in rule$keys) {
          idx <- which(layout_lower == key)
          if (length(idx) > 0) {
            row_pref_indices <- c(row_pref_indices, idx - 1L)  # 0-indexed
            row_pref_targets <- c(row_pref_targets, rule$row)
          }
        }
        row_pref_weight <- max(row_pref_weight, rule$weight)
      },

      "balance_hands" = {
        balance_target <- rule$target
        balance_weight <- rule$weight
      },

      "keep_like" = {
        keep_like_ref <- rule$reference
        for (key in rule$keys) {
          idx <- which(layout_lower == key)
          if (length(idx) > 0) {
            keep_like_indices <- c(keep_like_indices, idx - 1L)  # 0-indexed
          }
        }
        keep_like_weight <- rule$weight
      }
    )
  }

  list(
    fixed_positions = fixed_positions,
    hand_pref_indices = as.integer(hand_pref_indices),
    hand_pref_targets = as.integer(hand_pref_targets),
    hand_pref_weight = as.numeric(hand_pref_weight),
    row_pref_indices = as.integer(row_pref_indices),
    row_pref_targets = as.integer(row_pref_targets),
    row_pref_weight = as.numeric(row_pref_weight),
    balance_target = as.numeric(balance_target),
    balance_weight = as.numeric(balance_weight),
    keep_like_ref = as.character(keep_like_ref),
    keep_like_indices = as.integer(keep_like_indices),
    keep_like_weight = as.numeric(keep_like_weight)
  )
}


#' Print method for layout rules
#'
#' @param x A layout_rule object
#' @param ... Ignored
#'
#' @export
print.layout_rule <- function(x, ...) {
  cat("Layout Rule:", x$type, "\n")
  switch(x$type,
    "fix" = cat("  Fixed keys:", paste(x$keys, collapse = ", "), "\n"),
    "prefer_hand" = cat("  Keys:", paste(x$keys, collapse = ", "),
                        "-> ", x$hand, "hand (weight:", x$weight, ")\n"),
    "prefer_row" = cat("  Keys:", paste(x$keys, collapse = ", "),
                       "-> row", x$row, "(weight:", x$weight, ")\n"),
    "prefer_finger" = cat("  Keys:", paste(x$keys, collapse = ", "),
                          "-> fingers", paste(x$fingers, collapse = ","),
                          "(weight:", x$weight, ")\n"),
    "balance_hands" = cat("  Target:", x$target * 100, "% left hand",
                          "(weight:", x$weight, ")\n"),
    "keep_like" = cat("  Match reference for:", paste(x$keys, collapse = ", "),
                      "(weight:", x$weight, ")\n")
  )
  invisible(x)
}
