# Tests for rule builder functions

test_that("fix_keys creates valid rule object", {
  rule <- fix_keys(c("z", "x", "c", "v"))

  expect_s3_class(rule, "layout_rule")
  expect_equal(rule$type, "fix")
  expect_equal(rule$keys, c("z", "x", "c", "v"))
})

test_that("fix_keys converts to lowercase", {
  rule <- fix_keys(c("Z", "X", "C", "V"))
  expect_equal(rule$keys, c("z", "x", "c", "v"))
})

test_that("fix_keys errors on empty input", {
  expect_error(fix_keys(character(0)), "non-empty")
  expect_error(fix_keys(NULL), "non-empty")
})

test_that("prefer_hand creates valid rule object", {
  rule <- prefer_hand(c("a", "e", "i"), "left", weight = 2.0)

  expect_s3_class(rule, "layout_rule")
  expect_equal(rule$type, "prefer_hand")
  expect_equal(rule$keys, c("a", "e", "i"))
  expect_equal(rule$hand, "left")
  expect_equal(rule$weight, 2.0)
})

test_that("prefer_hand validates hand argument", {
  expect_error(prefer_hand(c("a"), "middle"), "should be one of")
})

test_that("prefer_hand validates weight", {
 expect_error(prefer_hand(c("a"), "left", weight = -1), "non-negative")
})

test_that("prefer_row creates valid rule object", {
  rule <- prefer_row(c("e", "t", "a"), 2, weight = 1.5)

  expect_s3_class(rule, "layout_rule")
  expect_equal(rule$type, "prefer_row")
  expect_equal(rule$keys, c("e", "t", "a"))
  expect_equal(rule$row, 2L)
  expect_equal(rule$weight, 1.5)
})

test_that("prefer_row validates row argument", {
  expect_error(prefer_row(c("a"), 0), "row must be 1")
  expect_error(prefer_row(c("a"), 4), "row must be 1")
})

test_that("prefer_finger creates valid rule object", {
  rule <- prefer_finger(c("a", "b"), c(2, 3), weight = 1.0)

  expect_s3_class(rule, "layout_rule")
  expect_equal(rule$type, "prefer_finger")
  expect_equal(rule$keys, c("a", "b"))
  expect_equal(rule$fingers, c(2L, 3L))
})

test_that("balance_hands creates valid rule object", {
  rule <- balance_hands(0.5, weight = 2.0)

  expect_s3_class(rule, "layout_rule")
  expect_equal(rule$type, "balance_hands")
  expect_equal(rule$target, 0.5)
  expect_equal(rule$weight, 2.0)
})

test_that("balance_hands validates target range", {
  expect_error(balance_hands(-0.1), "between 0 and 1")
  expect_error(balance_hands(1.1), "between 0 and 1")
})

test_that("keep_like creates valid rule object with named layout", {
  rule <- keep_like("qwerty", c("a", "s", "d", "f"), weight = 3.0)

  expect_s3_class(rule, "layout_rule")
  expect_equal(rule$type, "keep_like")
  expect_equal(length(rule$reference), 26)
  expect_equal(rule$keys, c("a", "s", "d", "f"))
  expect_equal(rule$weight, 3.0)
})

test_that("keep_like errors on unknown layout name", {
  expect_error(keep_like("dvorak"), "Unknown layout")
})
