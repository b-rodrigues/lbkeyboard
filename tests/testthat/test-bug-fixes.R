
test_that("bug fix: 'e' should be placed on home row (row 2) in unconstrained optimization", {
  skip_on_cran() # Optimization takes time

  # A dummy language where 'e' is extremely frequent (90%)
  # This makes the optimal position clearer/more deterministic
  text <- paste0(rep("e", 900), rep("t", 50), rep("a", 50), collapse = "")
  
  set.seed(42)  # For reproducibility
  result <- optimize_layout(
    text_samples = text,
    generations = 100,    # More generations for consistency
    population_size = 50,
    verbose = FALSE
  )
  
  # Find position of 'e'
  e_pos <- result$layout[result$layout$key == "e", ]
  
  # Expect 'e' to be on row 2 (home row)
  expect_equal(e_pos$row, 2, info = "Most frequent letter 'e' should be on home row (row 2)")
})

test_that("bug fix: prefer_hand rule should be strictly respected with high weight", {
  skip_on_cran()

  # Rule: vowels MUST be on LEFT hand
  # Weight = 100.0 is effectively a constraint
  vowels <- c("a", "e", "i", "o", "u")
  
  result <- optimize_layout(
    text_samples = "the quick brown fox jumps over the lazy dog",
    rules = list(
      prefer_hand(vowels, "left", weight = 100.0)
    ),
    generations = 50,
    population_size = 50,
    verbose = FALSE
  )
  
  # Check positions of all vowels
  for (v in vowels) {
    pos <- result$layout[result$layout$key == v, ]
    
    # Left hand columns are 0-4
    is_left <- pos$number <= 4
    
    expect_true(is_left, 
      info = paste("Vowel", v, "should be on left hand (cols 0-4) but was at col", pos$number)
    )
  }
})
