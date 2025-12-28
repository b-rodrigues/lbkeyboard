#' Create QWERTZ-LUX keyboard layout
#'
#' Creates the QWERTZ-LUX keyboard layout optimized for Luxembourg's multilingual
#' environment. This layout includes direct access to the most frequent accented
#' characters (é, ä, ë, ç) on the three letter rows.
#'
#' @return A data frame with 34 keys (26 letters + 4 accents + comma + period + apostrophe + É)
#'   and columns: key, key_label, row, number, x_mid, y_mid
#'
#' @details
#' Layout structure:
#' \itemize{
#'   \item TOP ROW (11 keys): Q W F O G Z U K L P J
#'   \item HOME ROW (12 keys): A S D E , H N T R I M É
#'   \item BOTTOM ROW (10 keys): Y X C V B . Ä ' Ë Ç
#' }
#'
#' Direct accent access:
#' \itemize{
#'   \item é (home row): Most frequent accent (French)
#'   \item ä (bottom row): German/Luxembourgish
#'   \item ë (bottom row): Luxembourgish
#'   \item ç (bottom row): French
#' }
#'
#' Additional accents via AltGr or dead keys (use layer_map):
#' \itemize{
#'   \item è, à, ü, ö: AltGr layer (layer 2)
#'   \item ê, â, ô, î, û, ï: Dead key combinations (layer 3)
#' }
#'
#' @export
#'
#' @examples
#' kb <- create_qwertz_lux_keyboard()
#' nrow(kb)  # 33
create_qwertz_lux_keyboard <- function() {
  # QWERTZ-LUX layout with direct accent access
  # Based on frequency analysis of Luxembourg multilingual corpus
  
  keys <- c(
    # Row 1: 11 keys (top row)
    "q", "w", "f", "o", "g", "z", "u", "k", "l", "p", "j",
    # Row 2: 12 keys (home row) - é on right side for easy access
    "a", "s", "d", "e", ",", "h", "n", "t", "r", "i", "m", "é",
    # Row 3: 10 keys (bottom row) - ä, ë, ç for German/Luxembourgish
    "y", "x", "c", "v", "b", ".", "ä", "'", "ë", "ç"
  )

  rows <- c(
    rep(1, 11),  # top row
    rep(2, 12),  # home row
    rep(3, 10)   # bottom row
  )

  numbers <- c(
    0:10,        # top row positions (0-indexed)
    0:11,        # home row positions
    0:9          # bottom row positions
  )

  # Calculate x_mid and y_mid based on ISO layout
  # Home row offset from top row, bottom row further offset
  x_offset <- c(0, 0.25, 0.5)  # row offsets

  x_mid <- numbers + x_offset[rows]
  y_mid <- rows
  
  # Create key labels (uppercase for letters, as-is for accents and punctuation)
  key_labels <- sapply(keys, function(k) {
    if (k %in% letters) {
      toupper(k)
    } else if (k %in% c("é", "ä", "ë", "ç")) {
      toupper(k)  # É, Ä, Ë, Ç
    } else {
      k  # punctuation stays as-is
    }
  })

  data.frame(
    key = keys,
    key_label = key_labels,
    row = rows,
    number = numbers,
    x_mid = x_mid,
    y_mid = y_mid,
    stringsAsFactors = FALSE
  )
}


#' Standard QWERTZ accent layer map
#'
#' A named numeric vector defining which layer each accented character is on
#' for a standard QWERTZ keyboard. All accents require AltGr (layer 2) or
#' dead key combinations (layer 3).
#'
#' @format A named numeric vector where names are accented characters and
#'   values are layer numbers (2 = AltGr, 3 = dead key).
#'
#' @details
#' Layer meanings:
#' \itemize{
#'   \item 0 = Direct access (no modifier)
#'   \item 1 = Shift layer
#'   \item 2 = AltGr layer (20% effort penalty)
#'   \item 3 = Dead key (40% effort penalty)
#' }
#'
#' @export
#'
#' @examples
#' # Use with calculate_layout_effort()
#' data(ch_qwertz)
#' data(french)
#' effort <- calculate_layout_effort(
#'   ch_qwertz, french,
#'   keys_to_evaluate = letters,
#'   layer_map = qwertz_accent_layers
#' )
qwertz_accent_layers <- c(
  # French accents
  "é" = 2, "è" = 2, "ê" = 3, "ë" = 2,
  "à" = 2, "â" = 3,
  "ù" = 2, "û" = 3,
  "î" = 3, "ï" = 3,
  "ô" = 3,
  "ç" = 2,
  # German umlauts

  "ä" = 2, "ö" = 2, "ü" = 2
)


#' QWERTZ-LUX accent layer map
#'
#' A named numeric vector defining which layer each accented character is on
#' for the QWERTZ-LUX keyboard layout. The most frequent accents (é, ä, ë, ç)
#' are NOT in this map because they have direct access (layer 0).
#'
#' @format A named numeric vector where names are accented characters and
#'   values are layer numbers (2 = AltGr, 3 = dead key).
#'
#' @details
#' Characters with direct access (not in this map):
#' \itemize{
#'   \item é: Home row (most frequent accent)
#'   \item ä: Bottom row (German/Luxembourgish)
#'   \item ë: Bottom row (Luxembourgish)
#'   \item ç: Bottom row (French)
#' }
#'
#' Characters on AltGr layer (20% penalty):
#' \itemize{
#'   \item è, à, ü, ö
#' }
#'
#' Characters via dead keys (40% penalty):
#' \itemize{
#'   \item ê, â, ô, î, û, ï
#' }
#'
#' @export
#'
#' @examples
#' # Use with calculate_layout_effort()
#' kb <- create_qwertz_lux_keyboard()
#' data(french)
#' effort <- calculate_layout_effort(
#'   kb, french,
#'   keys_to_evaluate = c(letters, "é", "ä", "ë", "ç"),
#'   layer_map = qwertz_lux_accent_layers
#' )
qwertz_lux_accent_layers <- c(
  # AltGr layer (20% penalty)
  "è" = 2, "à" = 2, "ü" = 2, "ö" = 2,
  "ù" = 2,
  # Dead key layer (40% penalty)
  "ê" = 3, "â" = 3, "ô" = 3, "î" = 3, "û" = 3, "ï" = 3
  # Note: é, ä, ë, ç NOT listed = layer 0 = direct access
)
