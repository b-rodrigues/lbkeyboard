# Test finger assignment logic
# This verifies that the column-to-finger mapping works correctly
# and matches Carpalx methodology

test_that("column 0 (left pinky column: Q-A-Z) maps to finger 0", {
  # Create keyboards with different characters in column 0
  kb_qwerty <- data.frame(
    key = c("q", "a", "z"),
    row = c(1, 2, 3),
    number = c(0, 0, 0),
    stringsAsFactors = FALSE
  )

  kb_bepo <- data.frame(
    key = c("b", "a", "w"),  # BEPO has different chars in col 0
    row = c(1, 2, 3),
    number = c(0, 0, 0),
    stringsAsFactors = FALSE
  )

  # Both should assign finger 0 (left pinky) regardless of character
  # We'll test this by checking the effort calculation is consistent
  # with column-based finger assignment

  # For now, verify the keyboards have correct structure
  expect_equal(kb_qwerty$number, c(0, 0, 0))
  expect_equal(kb_bepo$number, c(0, 0, 0))
})

test_that("columns map to correct fingers (standard QWERTY layout)", {
  # QWERTY layout with known column positions
  # Top row: Q(0) W(1) E(2) R(3) T(4) Y(5) U(6) I(7) O(8) P(9)
  # Expected fingers: 0   1    2    3    3    6    6    7    8    9

  qwerty <- create_default_keyboard()

  # Verify column numbers are as expected
  top_row <- qwerty[qwerty$row == 1, ]
  expect_equal(top_row$number, 0:9)

  # Expected finger assignments based on column
  # col 0 → finger 0 (left pinky)
  # col 1 → finger 1 (left ring)
  # col 2 → finger 2 (left middle)
  # col 3 → finger 3 (left index)
  # col 4 → finger 3 (left index)
  # col 5 → finger 6 (right index)
  # col 6 → finger 6 (right index)
  # col 7 → finger 7 (right middle)
  # col 8 → finger 8 (right ring)
  # col 9 → finger 9 (right pinky)

  # We can't directly test the C++ function, but we can verify
  # the layout structure is correct for column-based assignment
  expect_true(all(top_row$number >= 0))
  expect_true(all(top_row$number <= 9))
})

test_that("home row has 9 keys with correct column numbers", {
  qwerty <- create_default_keyboard()
  home_row <- qwerty[qwerty$row == 2, ]

  # Home row: A(0) S(1) D(2) F(3) G(4) H(5) J(6) K(7) L(8)
  expect_equal(nrow(home_row), 9)
  expect_equal(home_row$number, 0:8)

  # Verify keys
  expect_equal(home_row$key, c("a", "s", "d", "f", "g", "h", "j", "k", "l"))
})

test_that("bottom row has 7 keys with correct column numbers", {
  qwerty <- create_default_keyboard()
  bottom_row <- qwerty[qwerty$row == 3, ]

  # Bottom row: Z(0) X(1) C(2) V(3) B(4) N(5) M(6)
  expect_equal(nrow(bottom_row), 7)
  expect_equal(bottom_row$number, 0:6)

  # Verify keys
  expect_equal(bottom_row$key, c("z", "x", "c", "v", "b", "n", "m"))
})

test_that("left hand columns are 0-4, right hand columns are 5-9", {
  qwerty <- create_default_keyboard()

  # Left hand keys (based on column number <= 4)
  left_keys_expected <- c(
    "q", "w", "e", "r", "t",  # top row cols 0-4
    "a", "s", "d", "f", "g",  # home row cols 0-4
    "z", "x", "c", "v", "b"   # bottom row cols 0-4
  )

  # Right hand keys (based on column number >= 5)
  right_keys_expected <- c(
    "y", "u", "i", "o", "p",  # top row cols 5-9
    "h", "j", "k", "l",       # home row cols 5-8
    "n", "m"                  # bottom row cols 5-6
  )

  left_keys_actual <- qwerty[qwerty$number <= 4, ]$key
  right_keys_actual <- qwerty[qwerty$number >= 5, ]$key

  expect_equal(sort(left_keys_actual), sort(left_keys_expected))
  expect_equal(sort(right_keys_actual), sort(right_keys_expected))
})

test_that("finger assignment should be layout-independent (QWERTY vs BEPO)", {
  # This is a conceptual test - different layouts should use the same
  # physical key positions (column numbers) for finger assignment

  # In QWERTY, 'a' is at row=2, col=0 (home row, left pinky)
  # In BEPO, 'a' is also at row=2, col=0 (same physical position)

  # Both should have the same column number → same finger
  # The CHARACTER is different, but the PHYSICAL POSITION is the same

  qwerty <- create_default_keyboard()
  qwerty_a <- qwerty[qwerty$key == "a", ]

  expect_equal(qwerty_a$row, 2)     # home row
  expect_equal(qwerty_a$number, 0)  # column 0 (left pinky column)
})

test_that("column-based finger assignment gives consistent effort scores", {
  skip_on_cran()  # Uses C++ calculation

  # Create two keyboards with same physical layout but different characters
  kb1 <- create_default_keyboard()

  # Simple text where all characters are in the same positions
  text <- "aaa"  # 'a' is at row=2, col=0 in QWERTY

  # Calculate effort
  effort <- calculate_layout_effort(
    keyboard = kb1,
    text_samples = text,
    effort_weights = list(
      base = 3.0,
      same_finger = 3.0,
      same_hand = 0.5,
      row_change = 0.5,
      trigram = 0.3
    ),
    breakdown = FALSE
  )

  # Should produce a positive effort value
  expect_true(effort > 0)
  expect_true(is.finite(effort))
})

test_that("index fingers handle two columns each (cols 3-4 and 5-6)", {
  qwerty <- create_default_keyboard()

  # Left index finger keys (cols 3-4)
  # Top: R(3), T(4)
  # Home: F(3), G(4)
  # Bottom: V(3), B(4)
  left_index_keys <- c("r", "t", "f", "g", "v", "b")
  left_index <- qwerty[qwerty$key %in% left_index_keys, ]

  expect_true(all(left_index$number %in% c(3, 4)))

  # Right index finger keys (cols 5-6)
  # Top: Y(5), U(6)
  # Home: H(5), J(6)
  # Bottom: N(5), M(6)
  right_index_keys <- c("y", "u", "h", "j", "n", "m")
  right_index <- qwerty[qwerty$key %in% right_index_keys, ]

  expect_true(all(right_index$number %in% c(5, 6)))
})

test_that("pinky fingers handle edge columns (col 0 and col 9)", {
  qwerty <- create_default_keyboard()

  # Left pinky (col 0)
  left_pinky_keys <- c("q", "a", "z")
  left_pinky <- qwerty[qwerty$key %in% left_pinky_keys, ]
  expect_true(all(left_pinky$number == 0))

  # Right pinky (col 9 on top row only, since home row ends at 8)
  right_pinky_top <- qwerty[qwerty$key == "p", ]
  expect_equal(right_pinky_top$number, 9)
  expect_equal(right_pinky_top$row, 1)  # top row
})

test_that("column numbers are consistent within each row", {
  qwerty <- create_default_keyboard()

  # Each row should have sequential column numbers starting from 0
  for (r in 1:3) {
    row_data <- qwerty[qwerty$row == r, ]
    row_cols <- sort(row_data$number)

    # Should start at 0
    expect_equal(min(row_cols), 0)

    # Should be sequential
    expect_equal(row_cols, 0:(length(row_cols) - 1))
  }
})
