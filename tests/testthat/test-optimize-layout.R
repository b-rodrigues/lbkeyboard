# Integration tests for optimize_layout with rules

test_that("optimize_layout works without rules", {
  result <- optimize_layout(
    text_samples = "hello world",
    generations = 5,
    population_size = 10,
    verbose = FALSE
  )

  expect_type(result, "list")
  expect_true("layout" %in% names(result))
  expect_true("effort" %in% names(result))
  expect_true("improvement" %in% names(result))
  expect_true("history" %in% names(result))
})

test_that("optimize_layout respects fix_keys rule", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  result <- optimize_layout(
    text_samples = "hello world",
    rules = list(fix_keys(c("z", "x", "c", "v"))),
    generations = 5,
    population_size = 10,
    verbose = FALSE
  )

  # Check that z, x, c, v are still in their original positions
  layout_keys <- tolower(result$layout$key)

  # Find positions in original QWERTY
  original_positions <- which(qwerty %in% c("z", "x", "c", "v"))
  result_keys_at_positions <- layout_keys[original_positions]

  expect_setequal(result_keys_at_positions, c("z", "x", "c", "v"))
})

test_that("optimize_layout accepts prefer_hand rule", {
  result <- optimize_layout(
    text_samples = "hello world",
    rules = list(prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 2.0)),
    generations = 5,
    population_size = 10,
    verbose = FALSE
  )

  expect_type(result, "list")
  expect_true("rules" %in% names(result))
  expect_equal(length(result$rules), 1)
})

test_that("optimize_layout accepts balance_hands rule", {
  result <- optimize_layout(
    text_samples = "hello world",
    rules = list(balance_hands(0.5, weight = 1.0)),
    generations = 5,
    population_size = 10,
    verbose = FALSE
  )

  expect_type(result, "list")
  expect_equal(result$rules[[1]]$type, "balance_hands")
})

test_that("optimize_layout accepts multiple rules", {
  result <- optimize_layout(
    text_samples = "the quick brown fox",
    rules = list(
      fix_keys(c("z", "x")),
      prefer_hand(c("a", "e"), "left", weight = 1.0),
      balance_hands(0.5, weight = 0.5)
    ),
    generations = 5,
    population_size = 10,
    verbose = FALSE
  )

  expect_type(result, "list")
  expect_equal(length(result$rules), 3)
  expect_true(result$n_fixed >= 2)  # At least z and x should be fixed
})

test_that("optimize_layout combines fixed_keys and fix_keys rule", {
  result <- optimize_layout(
    text_samples = "hello world",
    fixed_keys = c("a", "s"),
    rules = list(fix_keys(c("z", "x"))),
    generations = 5,
    population_size = 10,
    verbose = FALSE
  )

  # Should have at least 4 fixed keys (a, s, z, x)
  expect_true(result$n_fixed >= 4)
})

test_that("optimize_layout returns valid history", {
  result <- optimize_layout(
    text_samples = "hello",
    generations = 10,
    population_size = 10,
    verbose = FALSE
  )

  expect_equal(nrow(result$history), 10)
  expect_true(all(c("generation", "best", "mean") %in% names(result$history)))
  # Best fitness should generally decrease or stay the same
  # (lower is better)
})

test_that("optimize_layout returns correct n_optimized", {
  result <- optimize_layout(
    text_samples = "hello",
    fixed_keys = c("a", "b", "c", "d"),
    generations = 5,
    population_size = 10,
    verbose = FALSE
  )

  expect_equal(result$n_fixed, 4)
  expect_equal(result$n_optimized, 22)  # 26 - 4 = 22
})
