devtools::load_all(".")
data("afnor_bepo")
data("ch_qwertz")
data("french")
data("german")
data("english")
data("luxembourguish")

corpus <- list(
  French = rep(french, 3),
  English = rep(english, 3),
  German = rep(german, 2),
  Luxembourgish = rep(luxembourguish, 2)
)
all_texts <- unlist(corpus)
freq_all <- letter_freq(paste(all_texts, collapse = " "))

calculate_hand_balance <- function(kb, freq_df) {
  kb_lower <- tolower(kb$key)
  freq_lower <- tolower(freq_df$characters)
  
  left_freq <- 0
  right_freq <- 0
  
  # Determine column start to adapt threshold
  min_col <- min(kb$number)
  threshold <- if (min_col == 0) 5 else 6
  
  for (i in seq_len(nrow(kb))) {
    key <- kb_lower[i]
    col <- kb$number[i]
    
    freq_idx <- which(freq_lower == key)
    if (length(freq_idx) > 0) {
      key_freq <- freq_df$frequencies[freq_idx[1]]
      if (col < threshold) {
        left_freq <- left_freq + key_freq
      } else {
        right_freq <- right_freq + key_freq
      }
    }
  }
  
  total <- left_freq + right_freq
  
  if (total > 0) {
    left_pct <- round(left_freq / total * 100, 1)
    right_pct <- round(right_freq / total * 100, 1)
  } else {
    left_pct <- 50
    right_pct <- 50
  }
  
  return(paste0(left_pct, "/", right_pct))
}

cat("--- QWERTZ ---\n")
print(calculate_hand_balance(ch_qwertz, freq_all))

cat("\n--- BÉPO ---\n")
print(calculate_hand_balance(afnor_bepo, freq_all))
print(head(afnor_bepo))
cat("BÉPO Columns:", unique(afnor_bepo$number), "\n")

qwertz_lux <- create_qwertz_lux_keyboard()
cat("\n--- BÉPO High Freq Key Positions ---\n")
chars <- c("e", "a", "i", "s", "t", "n", "r", "u", "l", "o")
bepo_lower <- afnor_bepo
bepo_lower$key <- tolower(bepo_lower$key)
print(bepo_lower[bepo_lower$key %in% chars, c("key", "row", "number")])

cat("\n--- QWERTZ High Freq Key Positions ---\n")
qwertz_lower <- ch_qwertz
qwertz_lower$key <- tolower(qwertz_lower$key)
print(qwertz_lower[qwertz_lower$key %in% chars, c("key", "row", "number")])
