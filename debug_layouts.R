#!/usr/bin/env Rscript
# Debug keyboard layouts to understand why they score poorly

library(lbkeyboard)

# Load layouts
data(afnor_bepo)
data(afnor_azerty)
data(ch_qwertz)

qwerty <- create_default_keyboard()

cat("=== QWERTY Layout ===\n")
print(qwerty)

cat("\n=== BEPO Layout ===\n")
print(head(afnor_bepo, 30))

cat("\n=== AZERTY Layout ===\n")
print(head(afnor_azerty, 30))

cat("\n=== QWERTZ Layout ===\n")
print(head(ch_qwertz, 30))

# Check which letters are in each layout
cat("\n=== Letter Coverage ===\n")
qwerty_letters <- sort(tolower(qwerty$key[qwerty$key %in% c(letters, LETTERS)]))
bepo_letters <- sort(tolower(afnor_bepo$key[afnor_bepo$key %in% c(letters, LETTERS)]))
azerty_letters <- sort(tolower(afnor_azerty$key[afnor_azerty$key %in% c(letters, LETTERS)]))
qwertz_letters <- sort(tolower(ch_qwertz$key[ch_qwertz$key %in% c(letters, LETTERS)]))

cat("QWERTY letters (", length(qwerty_letters), "):", paste(qwerty_letters, collapse=" "), "\n")
cat("BEPO letters (", length(bepo_letters), "):", paste(bepo_letters, collapse=" "), "\n")
cat("AZERTY letters (", length(azerty_letters), "):", paste(azerty_letters, collapse=" "), "\n")
cat("QWERTZ letters (", length(qwertz_letters), "):", paste(qwertz_letters, collapse=" "), "\n")

# Check rows
cat("\n=== Row Distribution ===\n")
cat("QWERTY:\n")
print(table(qwerty$row))
cat("\nBEPO:\n")
print(table(afnor_bepo$row))
cat("\nAZERTY:\n")
print(table(afnor_azerty$row))
cat("\nQWERTZ:\n")
print(table(ch_qwertz$row))
