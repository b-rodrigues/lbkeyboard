#' Colours the keys of the keyboard according the relative frequency of characters appearing in a text.
#'
#' @param keyboard A dataframe holding a keyboard specification
#' @param letter_freq_df A dataframe with relative frequencies of characters. Output of \code{letter_freq()}
#' @param low A colour specification for low frequencies. Can be a hex colour code or one of the inbuilt colours. Defaults to "light green".
#' @param high A colour specification for high frequencies. Can be a hex colour code or one of the inbuilt colours. Defaults to "red".
#' @return The original keyboard dataframe but with an adjusted \code{fill} column, which colours each character according to its relative frequency.
#'
#' @importFrom scales colour_ramp
#' @importFrom dplyr full_join mutate coalesce 
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create some random string
#' text <- sample(replicate(10, letters), replace = TRUE)
#' letter_freq_df <- letter_freq(text)
#' heatmap_azerty <- heatmapize(afnor_azerty, letter_freq_df)
#' }
heatmapize <- function(keyboard, letter_freq_df, low = "light green", high = "red"){

  ramp <- scales::colour_ramp(c(low, high))

  letter_freq_df$fill <- ramp(letter_freq_df$scaled)

  keyboard %>%
    dplyr::full_join(letter_freq_df, by = c("key" = "letter")) %>%
    dplyr::mutate(fill = dplyr::coalesce(fill.y, fill.x))
}
