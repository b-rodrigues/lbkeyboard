# Interactive testing of lbkeyboard package
devtools::load_all()

# =============================================================================
# BASIC FUNCTIONS TEST
# =============================================================================

qwerty <- c(
  "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
  "a", "s", "d", "f", "g", "h", "j", "k", "l",
  "z", "x", "c", "v", "b", "n", "m"
)

cat("=== QWERTY Layout ===\n")
print_layout(qwerty)

cat("\n=== Random Layout ===\n")
print_layout(random_layout(qwerty))

# =============================================================================
# RULE BUILDERS TEST
# =============================================================================

cat("\n=== Testing Rule Builders ===\n")

# Fix keys in place (hard constraint)
r1 <- fix_keys(c("z", "x", "c", "v"))
print(r1)

# Prefer vowels on left hand (soft preference)
r2 <- prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 2.0)
print(r2)

# Balance hand usage (soft preference)
r3 <- balance_hands(0.5, weight = 1.0)
print(r3)

# Prefer common letters on home row
r4 <- prefer_row(c("e", "t", "a", "o", "n"), 2, weight = 1.5)
print(r4)

# =============================================================================
# OPTIMIZATION WITH RULES
# =============================================================================

cat("\n=== Optimization with Rules ===\n")

result <- optimize_layout(
  text_samples = "the quick brown fox jumps over the lazy dog",
  rules = list(
    fix_keys(c("z", "x", "c", "v")),          # Keep shortcuts in place
    prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 2.0),  # Vowels left
    balance_hands(0.5, weight = 1.0)          # Even hand balance
  ),
  generations = 50,
  verbose = TRUE
)

cat("\n=== Optimized Layout ===\n")
print_layout(result$layout)

cat("\nInitial effort:", result$initial_effort, "\n")
cat("Final effort:", result$effort, "\n")
cat("Improvement:", round(result$improvement, 2), "%\n")

# =============================================================================
# COMPARE: WITH VS WITHOUT RULES
# =============================================================================

cat("\n=== Comparison: With vs Without Rules ===\n")

# Without rules
result_no_rules <- optimize_layout(
  text_samples = "the quick brown fox jumps over the lazy dog",
  generations = 50,
  verbose = FALSE
)

cat("Without rules:\n")
print_layout(result_no_rules$layout)

cat("\nWith rules (vowels left, z/x/c/v fixed):\n")
print_layout(result$layout)
