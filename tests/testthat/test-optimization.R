# Tests for optimization functions

test_that("random_layout returns correct length", {
  keys <- letters[1:10]
  result <- random_layout(keys)

  expect_equal(length(result), 10)
})

test_that("random_layout preserves all keys", {
  keys <- letters[1:10]
  result <- random_layout(keys)

  expect_setequal(as.character(result), keys)
})

test_that("layout_effort returns numeric value", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  pos_x <- c(0:9, 0:8, 0:6)
  pos_y <- c(rep(0, 10), rep(1, 9), rep(2, 7))
  pos_row <- c(rep(1L, 10), rep(2L, 9), rep(3L, 7))
  pos_col <- c(0:9, 0:8, 0:6)

  effort <- layout_effort(
    layout = qwerty,
    pos_x = pos_x,
    pos_y = pos_y,
    pos_row = pos_row,
    pos_col = pos_col,
    text_samples = "hello world",
    char_freq = rep(1/26, 26),
    char_list = letters
  )

  expect_type(effort, "double")
  expect_true(effort > 0)
})

test_that("effort_breakdown returns all components", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  pos_x <- c(0:9, 0:8, 0:6)
  pos_y <- c(rep(0, 10), rep(1, 9), rep(2, 7))
  pos_row <- c(rep(1L, 10), rep(2L, 9), rep(3L, 7))
  pos_col <- c(0:9, 0:8, 0:6)

  result <- effort_breakdown(
    layout = qwerty,
    pos_x = pos_x,
    pos_y = pos_y,
    pos_row = pos_row,
    pos_col = pos_col,
    text_samples = "the quick brown fox",
    char_freq = rep(1/26, 26),
    char_list = letters
  )

  expect_type(result, "list")
  expect_true("base_effort" %in% names(result))
  expect_true("same_finger_effort" %in% names(result))
  expect_true("same_hand_effort" %in% names(result))
  expect_true("total_effort" %in% names(result))
  expect_true("same_finger_bigrams" %in% names(result))
})

test_that("print_layout works with character vector", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  # Should not error
  expect_invisible(print_layout(qwerty))
})

test_that("print_layout errors on wrong length", {
  expect_error(print_layout(letters[1:10]), "exactly 26 keys")
})
