# Tests for compile_rules function

test_that("compile_rules returns correct structure with no rules", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  result <- compile_rules(NULL, qwerty, NULL)

  expect_type(result, "list")
  expect_equal(length(result$fixed_positions), 26)
  expect_true(all(!result$fixed_positions))
  expect_equal(result$hand_pref_weight, 0.0)
  expect_equal(result$row_pref_weight, 0.0)
  expect_equal(result$balance_weight, 0.0)
})

test_that("compile_rules handles fix_keys correctly", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  rules <- list(fix_keys(c("z", "x", "c", "v")))
  result <- compile_rules(rules, qwerty, NULL)

  # z, x, c, v are at positions 20, 21, 22, 23 (1-indexed)
  expect_true(result$fixed_positions[20])  # z
  expect_true(result$fixed_positions[21])  # x
  expect_true(result$fixed_positions[22])  # c
  expect_true(result$fixed_positions[23])  # v
  expect_false(result$fixed_positions[1])  # q should not be fixed
})

test_that("compile_rules handles prefer_hand correctly", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  rules <- list(prefer_hand(c("a", "e"), "left", weight = 2.0))
  result <- compile_rules(rules, qwerty, NULL)

  expect_equal(result$hand_pref_weight, 2.0)
  expect_equal(length(result$hand_pref_keys), 2)
  expect_true(all(c("a", "e") %in% result$hand_pref_keys))
  # All targets should be 0 (left hand)
  expect_true(all(result$hand_pref_targets == 0))
})

test_that("compile_rules handles balance_hands correctly", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  rules <- list(balance_hands(0.45, weight = 1.5))
  result <- compile_rules(rules, qwerty, NULL)

  expect_equal(result$balance_target, 0.45)
  expect_equal(result$balance_weight, 1.5)
})

test_that("compile_rules handles multiple rules", {
  qwerty <- c("q","w","e","r","t","y","u","i","o","p",
              "a","s","d","f","g","h","j","k","l",
              "z","x","c","v","b","n","m")

  rules <- list(
    fix_keys(c("z", "x")),
    prefer_hand(c("a", "e"), "right", weight = 1.0),
    balance_hands(0.5, weight = 2.0)
  )
  result <- compile_rules(rules, qwerty, NULL)

  expect_true(result$fixed_positions[20])  # z
  expect_true(result$fixed_positions[21])  # x
  expect_equal(result$hand_pref_weight, 1.0)
  expect_true(all(c("a", "e") %in% result$hand_pref_keys))
  expect_true(all(result$hand_pref_targets == 1))  # right hand
  expect_equal(result$balance_weight, 2.0)
})

test_that("compile_rules rejects non-rule objects", {
  qwerty <- letters

  expect_error(
    compile_rules(list(list(type = "fake")), qwerty, NULL),
    "must be created by rule builder"
  )
})
