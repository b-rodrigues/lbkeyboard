#' Create QWERTZ-LUX keyboard layout
#'
#' Creates the QWERTZ-LUX keyboard layout optimized for Luxembourg's multilingual
#' environment. This layout includes direct access to the most frequent accented
#' characters (é, ä, ë, ç) on the three letter rows.
#'
#' @return A list with class "qwertz_lux_layout" containing:
#'   \itemize{
#'     \item base: Data frame of base layer keys (compatible with heatmapize/ggkeyboard)
#'     \item altgr: Data frame of AltGr layer keys
#'     \item metadata: List with layout name and info
#'   }
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
#' # Use base layer for heatmap
#' # heatmap <- heatmapize(kb$base, letter_freq_df)
#' # ggkeyboard(heatmap)
create_qwertz_lux_keyboard <- function() {
  # Load ch_qwertz as template for keyboard structure (has all the positioning info)
  data("ch_qwertz", package = "lbkeyboard", envir = environment())
  
  # Find the INI file path
  ini_path <- system.file("layouts", "qwertz-lux", "layout.ini", package = "lbkeyboard")
  if (ini_path == "") {
    ini_path <- "layouts/qwertz-lux/layout.ini"
    if (!file.exists(ini_path)) {
      ini_path <- "../layouts/qwertz-lux/layout.ini"
    }
  }
  
  if (!file.exists(ini_path)) {
    stop("Could not find layouts/qwertz-lux/layout.ini")
  }
  
  # Read and parse the INI file manually
  lines <- readLines(ini_path, encoding = "UTF-8", warn = FALSE)
  lines <- gsub("\r", "", lines)
  
  # Define scancode to ch_qwertz position mapping
  # Format: scancode -> list(row in ch_qwertz, number in ch_qwertz)
  scancode_to_pos <- list(
    # Number row (row 5 in ch_qwertz)
    "SC002" = list(row = 5, number = 2),   # 1
    "SC003" = list(row = 5, number = 3),   # 2
    "SC004" = list(row = 5, number = 4),   # 3
    "SC005" = list(row = 5, number = 5),   # 4
    "SC006" = list(row = 5, number = 6),   # 5
    "SC007" = list(row = 5, number = 7),   # 6
    "SC008" = list(row = 5, number = 8),   # 7
    "SC009" = list(row = 5, number = 9),   # 8
    "SC00A" = list(row = 5, number = 10),  # 9
    "SC00B" = list(row = 5, number = 11),  # 0
    "SC00C" = list(row = 5, number = 12),  # -
    "SC00D" = list(row = 5, number = 13),  # =
    # Top letter row (row 4 in ch_qwertz)
    "SC010" = list(row = 4, number = 2),   # Q
    "SC011" = list(row = 4, number = 3),   # W
    "SC012" = list(row = 4, number = 4),   # E
    "SC013" = list(row = 4, number = 5),   # R
    "SC014" = list(row = 4, number = 6),   # T
    "SC015" = list(row = 4, number = 7),   # Z
    "SC016" = list(row = 4, number = 8),   # U
    "SC017" = list(row = 4, number = 9),   # I
    "SC018" = list(row = 4, number = 10),  # O
    "SC019" = list(row = 4, number = 11),  # P
    "SC01A" = list(row = 4, number = 12),  # [
    "SC01B" = list(row = 4, number = 13),  # ]
    # Home row (row 3 in ch_qwertz)
    "SC01E" = list(row = 3, number = 2),   # A
    "SC01F" = list(row = 3, number = 3),   # S
    "SC020" = list(row = 3, number = 4),   # D
    "SC021" = list(row = 3, number = 5),   # F
    "SC022" = list(row = 3, number = 6),   # G
    "SC023" = list(row = 3, number = 7),   # H
    "SC024" = list(row = 3, number = 8),   # J
    "SC025" = list(row = 3, number = 9),   # K
    "SC026" = list(row = 3, number = 10),  # L
    "SC027" = list(row = 3, number = 11),  # ;
    "SC028" = list(row = 3, number = 12),  # '
    "SC02B" = list(row = 3, number = 13),  # \ (ISO)
    # Bottom row (row 2 in ch_qwertz)
    "SC02C" = list(row = 2, number = 2),   # Z
    "SC02D" = list(row = 2, number = 3),   # X
    "SC02E" = list(row = 2, number = 4),   # C
    "SC02F" = list(row = 2, number = 5),   # V
    "SC030" = list(row = 2, number = 6),   # B
    "SC031" = list(row = 2, number = 7),   # N
    "SC032" = list(row = 2, number = 8),   # M
    "SC033" = list(row = 2, number = 9),   # ,
    "SC034" = list(row = 2, number = 10),  # .
    "SC035" = list(row = 2, number = 11)   # /
  )
  
  # Start with a copy of ch_qwertz
  base_layer <- ch_qwertz
  
  # Parse the [layout] section and update ch_qwertz
  in_layout <- FALSE
  for (line in lines) {
    if (grepl("^\\s*;", line) || grepl("^\\s*$", line)) next
    
    if (grepl("^\\[layout\\]", line, ignore.case = TRUE)) {
      in_layout <- TRUE
      next
    }
    if (grepl("^\\[", line)) {
      in_layout <- FALSE
      next
    }
    
    if (!in_layout) next
    
    # Parse line like: SC010 = Q	1	q	Q	--	œ	Œ	; comment
    parts <- strsplit(sub("\\s*;.*$", "", line), "\\s*=\\s*")[[1]]
    if (length(parts) < 2) next
    
    scancode <- toupper(trimws(parts[1]))
    if (!scancode %in% names(scancode_to_pos)) next
    
    # Split the value by tabs
    values <- strsplit(parts[2], "\t")[[1]]
    values <- trimws(values)
    
    # Values structure: VK, CapStat, 0Norm, 1Sh, 2Ctrl, 6AGr, 7AGrSh
    if (length(values) < 4) next
    
    base_char <- values[3]   # 0Norm - base layer
    shift_char <- values[4]  # 1Sh - shift layer
    
    # Skip empty entries
    if (base_char == "--" || base_char == "") next
    
    # Handle dead keys - convert to their symbol
    dead_key_map <- c(
      "dk1" = "^",   # circumflex
      "dk2" = "`",   # grave
      "dk3" = "´",   # acute
      "dk4" = "~",   # tilde
      "dk5" = "¨"    # diaeresis
    )
    if (grepl("^dk", base_char)) {
      base_char <- if (base_char %in% names(dead_key_map)) dead_key_map[[base_char]] else "◌"
    }
    if (grepl("^dk", shift_char)) {
      shift_char <- if (shift_char %in% names(dead_key_map)) dead_key_map[[shift_char]] else "◌"
    }
    
    if (base_char == "={Space}") base_char <- " "
    if (shift_char == "={Space}") shift_char <- " "
    
    # Find matching position in ch_qwertz
    pos <- scancode_to_pos[[scancode]]
    match_idx <- which(
      base_layer$layout == "60%" &
      base_layer$row == pos$row &
      base_layer$number == pos$number
    )
    
    if (length(match_idx) == 1) {
      base_layer$key[match_idx] <- base_char
      # Create key_label in format "Upper\nLower"
      if (shift_char != "--" && shift_char != "") {
        base_layer$key_label[match_idx] <- paste0(shift_char, "\n", base_char)
      } else {
        base_layer$key_label[match_idx] <- toupper(base_char)
      }
    }
  }
  
  # Create result list (for now, just base layer - altgr can be added similarly)
  result <- list(
    base = base_layer,
    altgr = base_layer,  # Placeholder - would need separate parsing for AltGr
    metadata = list(
      layoutname = "QWERTZ-LUX",
      layoutcode = "qwertz-lux-1.0",
      version = "1.0",
      description = "Optimized for French, German, Luxembourgish, English"
    )
  )
  
  class(result) <- c("qwertz_lux_layout", "list")
  result
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
