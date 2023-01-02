## code to prepare `distances.R` dataset goes here

data("afnor_bepo")

bepo_distances <- afnor_bepo %>%
  filter(row %in% seq(2,4)) %>%
  select(key, key_label, row, number) %>%
  filter(!is.na(key) | !is.na(key_label))

usethis::use_data(distances.R, overwrite = TRUE)
