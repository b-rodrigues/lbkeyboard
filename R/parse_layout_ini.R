#' Parse a PKL layout.ini file
#'
#' Reads a Portable Keyboard Layout (PKL) configuration file and extracts
#' the keyboard layout for each layer (shift state).
#'
#' @param file_path Path to the layout.ini file.
#' @param layer Which layer to extract. Default is NULL which returns all layers.
#'   - NULL: Return all layers as a named list of data frames
#'   - 0: Base layer (no modifier)
#'   - 1: Shift layer
#'   - 2: Ctrl layer (usually not used for character input)
#'   - 3: AltGr layer (6 in PKL notation)
#'   - 4: AltGr+Shift layer (7 in PKL notation)
#' @param include_special Logical. Include non-letter keys (punctuation, etc.)? Default FALSE.
#'
#' @return If layer is NULL, a named list with elements: base, shift, ctrl, altgr, altgr_shift.
#'   Each element is a data frame with columns: key, key_label, row, number, x_mid, y_mid, scancode.
#'   Additionally, the list has a 'metadata' element with layout name, code, and version.
#'   If layer is specified (0-4), returns a single data frame for that layer.
#'
#' @details
#' PKL layout.ini files use scan codes (SC010, SC011, etc.) to define key positions.
#' The shift states are defined in the \code{[global]} section as \code{shiftstates = 0:1:2:6:7}.
#'
#' Standard scan code mapping:
#' - SC010-SC01b: Top row (Q to ])
#' - SC01e-SC02b: Home row (A to ')
#' - SC02c-SC035: Bottom row (Z to /)
#' - SC056: ISO key (left of Z on ISO keyboards)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Parse all layers
#' layout <- parse_layout_ini("layouts/qwertz-lux/layout.ini")
#' print(layout$base)      # Base layer
#' print(layout$altgr)     # AltGr layer
#' print(layout$metadata)  # Layout name, version, etc.
#'
#' # Parse a single layer (backward compatible)
#' base_only <- parse_layout_ini("layouts/qwertz-lux/layout.ini", layer = 0)
#' altgr_only <- parse_layout_ini("layouts/qwertz-lux/layout.ini", layer = 3)
#'
#' # Plot the layout
#' plot_layout_ini("layouts/qwertz-lux/layout.ini")
#' }
parse_layout_ini <- function(file_path, layer = NULL, include_special = FALSE) {
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  # Read file with proper encoding (UTF-8 with possible BOM)
  lines <- readLines(file_path, encoding = "UTF-8", warn = FALSE)
  
  # Remove any BOM and carriage returns
  lines <- gsub("^\ufeff", "", lines)
  lines <- gsub("\r", "", lines)
  
  # Parse metadata from [informations] section
  metadata <- list(
    layoutname = basename(dirname(file_path)),
    layoutcode = "",
    version = "",
    copyright = "",
    homepage = ""
  )
  info_section <- FALSE
  for (line in lines) {
    if (grepl("^\\[informations\\]", line, ignore.case = TRUE)) {
      info_section <- TRUE
      next
    }
    if (grepl("^\\[", line)) {
      info_section <- FALSE
      next
    }
    if (info_section) {
      for (field in c("layoutname", "layoutcode", "version", "copyright", "homepage")) {
        pattern <- paste0("^", field, "\\s*=\\s*")
        if (grepl(pattern, line, ignore.case = TRUE)) {
          metadata[[field]] <- trimws(sub(pattern, "", line, ignore.case = TRUE))
        }
      }
    }
  }
  
  # Parse shift states from [global] section
  # Default PKL shift states: 0:1:2:6:7
  shift_states <- c(0, 1, 2, 6, 7)
  global_section <- FALSE
  for (line in lines) {
    if (grepl("^\\[global\\]", line, ignore.case = TRUE)) {
      global_section <- TRUE
      next
    }
    if (grepl("^\\[", line)) {
      global_section <- FALSE
      next
    }
    if (global_section && grepl("^shiftstates\\s*=", line, ignore.case = TRUE)) {
      states_str <- sub("^shiftstates\\s*=\\s*", "", line, ignore.case = TRUE)
      shift_states <- as.integer(strsplit(states_str, ":")[[1]])
      break
    }
  }
  
  # Layer names mapping (PKL shift state to layer name)
  layer_names <- c("base", "shift", "ctrl", "altgr", "altgr_shift")
  pkl_shift_states <- c(0, 1, 2, 6, 7)
  
  # Define scan code to row/position mapping for ISO keyboard
  scancode_map <- list(
    # Top row (positions 0-11 for 12 keys in QWERTY positions)
    "SC010" = list(row = 1, number = 0),   # Q
    "SC011" = list(row = 1, number = 1),   # W
    "SC012" = list(row = 1, number = 2),   # E
    "SC013" = list(row = 1, number = 3),   # R
    "SC014" = list(row = 1, number = 4),   # T
    "SC015" = list(row = 1, number = 5),   # Y
    "SC016" = list(row = 1, number = 6),   # U
    "SC017" = list(row = 1, number = 7),   # I
    "SC018" = list(row = 1, number = 8),   # O
    "SC019" = list(row = 1, number = 9),   # P
    "SC01A" = list(row = 1, number = 10),  # [ or J position
    "SC01B" = list(row = 1, number = 11),  # ]
    
    # Home row (positions 0-11 for 12 keys)
    "SC01E" = list(row = 2, number = 0),   # A
    "SC01F" = list(row = 2, number = 1),   # S
    "SC020" = list(row = 2, number = 2),   # D
    "SC021" = list(row = 2, number = 3),   # F
    "SC022" = list(row = 2, number = 4),   # G
    "SC023" = list(row = 2, number = 5),   # H
    "SC024" = list(row = 2, number = 6),   # J
    "SC025" = list(row = 2, number = 7),   # K
    "SC026" = list(row = 2, number = 8),   # L
    "SC027" = list(row = 2, number = 9),   # ;
    "SC028" = list(row = 2, number = 10),  # '
    "SC029" = list(row = 2, number = -1),  # ` key (left of 1, not in letter area)
    "SC02B" = list(row = 2, number = 11),  # \ or # (ISO)
    
    # Bottom row (positions 0-9 for 10 keys plus ISO key)
    "SC056" = list(row = 3, number = -1),  # ISO key (before Z, not in letter area)
    "SC02C" = list(row = 3, number = 0),   # Z
    "SC02D" = list(row = 3, number = 1),   # X
    "SC02E" = list(row = 3, number = 2),   # C
    "SC02F" = list(row = 3, number = 3),   # V
    "SC030" = list(row = 3, number = 4),   # B
    "SC031" = list(row = 3, number = 5),   # N
    "SC032" = list(row = 3, number = 6),   # M
    "SC033" = list(row = 3, number = 7),   # ,
    "SC034" = list(row = 3, number = 8),   # .
    "SC035" = list(row = 3, number = 9)    # /
  )
  
  # Initialize list to hold parsed keys for each layer
  layer_keys <- lapply(1:5, function(x) list())
  names(layer_keys) <- layer_names
  
  # Parse [layout] section - extract all layers at once
  layout_section <- FALSE
  
  for (line in lines) {
    # Skip comments and empty lines
    if (grepl("^\\s*;", line) || grepl("^\\s*$", line)) next
    
    # Check for section headers
    if (grepl("^\\[layout\\]", line, ignore.case = TRUE)) {
      layout_section <- TRUE
      next
    }
    if (grepl("^\\[", line)) {
      layout_section <- FALSE
      next
    }
    
    if (!layout_section) next
    
    # Parse layout line: SC010 = Q  1  q  Q  --  œ  Œ  ; comment
    # Format: scancode = VK  CapStat  0Norm  1Sh  2Ctrl  6AGr  7AGrSh  ; comment
    
    # Remove inline comments
    line_clean <- sub("\\s*;.*$", "", line)
    
    # Split on = 
    parts <- strsplit(line_clean, "\\s*=\\s*")[[1]]
    if (length(parts) < 2) next
    
    scancode <- trimws(parts[1])
    scancode_upper <- toupper(scancode)
    
    # Check if this is a scan code we recognize
    if (!scancode_upper %in% names(scancode_map)) next
    
    # Get position info
    pos_info <- scancode_map[[scancode_upper]]
    
    # Parse the key definitions (tab-separated after VK and CapStat)
    value_part <- parts[2]
    
    # Split by tabs (PKL uses tabs as separators)
    values <- strsplit(value_part, "\t+")[[1]]
    values <- trimws(values)
    
    # PKL format: VK  CapStat  layer0  layer1  layer2  layer3  layer4 ...
    # We need to skip VK (index 1) and CapStat (index 2), then get each layer
    
    # Extract key for each layer
    for (layer_idx in seq_along(shift_states)) {
      target_shift_state <- shift_states[layer_idx]
      layer_name_idx <- which(pkl_shift_states == target_shift_state)
      if (length(layer_name_idx) == 0) next
      layer_name <- layer_names[layer_name_idx]
      
      key_value_idx <- 2 + layer_idx
      
      if (length(values) < key_value_idx) next
      
      key_value <- values[key_value_idx]
      
      # Skip dead keys (dk1, dk2, etc.) and -- entries
      if (grepl("^dk\\d*$", key_value) || key_value == "--" || key_value == "") next
      
      # Handle special escape sequences
      if (key_value == "={Space}") {
        key_value <- " "
      }
      
      # Store the parsed key for this layer
      layer_keys[[layer_name]][[length(layer_keys[[layer_name]]) + 1]] <- list(
        scancode = scancode_upper,
        key = key_value,
        row = pos_info$row,
        number = pos_info$number
      )
    }
  }
  
  # Convert to data frames
  x_offset <- c(0, 0.25, 0.5)  # row offsets for plotting
  
  result <- lapply(layer_keys, function(keys) {
    if (length(keys) == 0) {
      return(data.frame(
        key = character(0),
        key_label = character(0),
        row = integer(0),
        number = integer(0),
        scancode = character(0),
        x_mid = numeric(0),
        y_mid = numeric(0),
        stringsAsFactors = FALSE
      ))
    }
    
    df <- do.call(rbind, lapply(keys, function(k) {
      data.frame(
        key = k$key,
        key_label = toupper(k$key),
        row = k$row,
        number = k$number,
        scancode = k$scancode,
        stringsAsFactors = FALSE
      )
    }))
    
    # Filter to only include letter positions (number >= 0) unless include_special
    if (!include_special) {
      df <- df[df$number >= 0, ]
    }
    
    # Calculate x_mid and y_mid for plotting
    df$x_mid <- df$number + x_offset[df$row]
    df$y_mid <- df$row
    
    # Sort by row and number for consistent ordering
    df <- df[order(df$row, df$number), ]
    rownames(df) <- NULL
    
    df
  })
  
  # Add metadata to result
  result$metadata <- metadata
  
  # Set class for special handling
  class(result) <- c("pkl_layout", "list")
  
  # If a specific layer was requested, return just that layer (backward compatible)
  if (!is.null(layer)) {
    if (layer < 0 || layer > 4) {
      stop("layer must be between 0 and 4, or NULL for all layers")
    }
    return(result[[layer_names[layer + 1]]])
  }
  
  result
}


#' Print method for pkl_layout objects
#'
#' @param x A pkl_layout object from parse_layout_ini()
#' @param ... Additional arguments (ignored)
#'
#' @export
print.pkl_layout <- function(x, ...) {
  cat("PKL Layout:", x$metadata$layoutname, "\n")
  cat("Version:", x$metadata$version, "\n")
  cat("Code:", x$metadata$layoutcode, "\n\n")
  
  for (layer_name in c("base", "shift", "ctrl", "altgr", "altgr_shift")) {
    df <- x[[layer_name]]
    cat(sprintf("  %-12s: %d keys\n", layer_name, nrow(df)))
  }
  
  invisible(x)
}


#' Plot a PKL layout
#'
#' Plots a Portable Keyboard Layout from a file path or parsed pkl_layout object.
#'
#' @param x Either a file path to a layout.ini file, a pkl_layout object from
#'   \code{\link{parse_layout_ini}}, or a single layer data frame.
#' @param layer Which layer to plot. Default is "base".
#'   Can be: "base", "shift", "ctrl", "altgr", "altgr_shift" or 0-4.
#' @param palette Color palette to use. Default is keyboard_palette("pastel").
#' @param ... Additional arguments passed to \code{\link{ggkeyboard}}.
#'
#' @return A ggplot2 object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Plot from file path
#' plot_layout_ini("layouts/qwertz-lux/layout.ini")
#'
#' # Plot AltGr layer
#' plot_layout_ini("layouts/qwertz-lux/layout.ini", layer = "altgr")
#'
#' # Parse first, then plot
#' layout <- parse_layout_ini("layouts/qwertz-lux/layout.ini")
#' plot_layout_ini(layout, layer = "base")
#' plot_layout_ini(layout, layer = "altgr", palette = keyboard_palette("cyberpunk"))
#' }
plot_layout_ini <- function(x, layer = "base", palette = keyboard_palette("pastel"), ...) {
  
  # Handle different input types
  if (is.character(x) && length(x) == 1 && file.exists(x)) {
    # File path provided
    layout_obj <- parse_layout_ini(x)
    file_path <- x
  } else if (inherits(x, "pkl_layout")) {
    # pkl_layout object provided
    layout_obj <- x
    file_path <- NULL
  } else if (is.data.frame(x)) {
    # Single layer data frame provided - wrap it
    layout_obj <- NULL
    layout_df <- x
  } else {
    stop("x must be a file path, pkl_layout object, or a layer data frame")
  }
  
  # Convert numeric layer to name
  layer_names <- c("base", "shift", "ctrl", "altgr", "altgr_shift")
  if (is.numeric(layer)) {
    if (layer < 0 || layer > 4) {
      stop("Numeric layer must be 0-4")
    }
    layer <- layer_names[layer + 1]
  }
  layer <- match.arg(layer, layer_names)
  
  # Get the layer data frame
  if (!is.null(layout_obj)) {
    layout_df <- layout_obj[[layer]]
    layout_name <- layout_obj$metadata$layoutname
  } else {
    layout_name <- "Layout"
  }
  
  # Generate plot title
  layer_display <- c(base = "Base", shift = "Shift", ctrl = "Ctrl", 
                     altgr = "AltGr", altgr_shift = "AltGr+Shift")
  plot_title <- paste0(layout_name, " (", layer_display[layer], " layer)")
  
  # Build keyboard data frame for ggkeyboard
  keyboard <- layout_df
  keyboard$key_type <- "alphanumeric"
  keyboard$layout <- "60%"
  keyboard$width <- 1
  keyboard$height <- 1
  
  # Use the internal ggkeyboard plotting functions
  keyboard <- construct_keyboard(
    keyboard = keyboard,
    palette = palette,
    keyboard_layout = "60%"
  )
  
  keyboard_full <- construct_keyboard_outline(keyboard, keyboard_colour = palette[["keyboard"]])
  
  construct_plot(
    keyboard = keyboard,
    keyboard_full = keyboard_full,
    palette = palette,
    keyboard_layout = "60%",
    ...
  ) + 
  ggplot2::ggtitle(plot_title) +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))
}


#' Plot multiple layers of a PKL layout
#'
#' Creates a grid of keyboard plots showing multiple layers of a PKL layout.
#'
#' @param x Either a file path to a layout.ini file or a pkl_layout object.
#' @param layers Which layers to plot. Default is c("base", "altgr").
#'   Options: "base", "shift", "ctrl", "altgr", "altgr_shift", or "all".
#' @param ncol Number of columns in the plot grid. Default is 2.
#' @param palette Color palette to use. Default is keyboard_palette("pastel").
#' @param ... Additional arguments passed to \code{\link{ggkeyboard}}.
#'
#' @return A combined ggplot2 object using patchwork.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Plot base and AltGr layers side by side
#' ggkeyboard_layers("layouts/qwertz-lux/layout.ini")
#'
#' # Plot all layers
#' ggkeyboard_layers("layouts/qwertz-lux/layout.ini", layers = "all", ncol = 3)
#'
#' # Parse first, then plot selected layers
#' layout <- parse_layout_ini("layouts/qwertz-lux/layout.ini")
#' ggkeyboard_layers(layout, layers = c("base", "shift", "altgr"))
#' }
ggkeyboard_layers <- function(x, layers = c("base", "altgr"), ncol = 2, 
                               palette = keyboard_palette("pastel"), ...) {
  
  # Handle different input types
  if (is.character(x) && length(x) == 1 && file.exists(x)) {
    layout_obj <- parse_layout_ini(x)
  } else if (inherits(x, "pkl_layout")) {
    layout_obj <- x
  } else {
    stop("x must be a file path or pkl_layout object")
  }
  
  # Handle "all" layers
  all_layers <- c("base", "shift", "ctrl", "altgr", "altgr_shift")
  if ("all" %in% layers) {
    layers <- all_layers
  } else {
    layers <- match.arg(layers, all_layers, several.ok = TRUE)
  }
  
  # Filter to layers that have keys
  layers <- layers[sapply(layers, function(l) nrow(layout_obj[[l]]) > 0)]
  
  if (length(layers) == 0) {
    stop("No layers with keys found")
  }
  
  # Create individual plots
  plots <- lapply(layers, function(layer) {
    plot_layout_ini(layout_obj, layer = layer, palette = palette, ...)
  })
  
  # Combine with patchwork if available
  if (requireNamespace("patchwork", quietly = TRUE)) {
    combined <- patchwork::wrap_plots(plots, ncol = ncol)
  } else {
    # Fallback: return list of plots
    warning("patchwork package not available. Returning list of plots instead.")
    combined <- plots
    names(combined) <- layers
  }
  
  combined
}



#' List available layouts in a directory
#'
#' Finds all layout.ini files in a given directory and its subdirectories.
#'
#' @param path Directory to search for layout.ini files.
#'   Default is "layouts" subdirectory of the current package.
#'
#' @return A character vector of paths to layout.ini files.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # List layouts in the package
#' layouts <- list_layouts()
#' print(layouts)
#' }
list_layouts <- function(path = NULL) {
  if (is.null(path)) {
    # Try to find the package's layouts directory
    pkg_path <- system.file("layouts", package = "lbkeyboard")
    if (pkg_path == "") {
      # Not installed, try relative path
      if (dir.exists("layouts")) {
        path <- "layouts"
      } else if (dir.exists("../layouts")) {
        path <- "../layouts"
      } else {
        stop("Could not find layouts directory")
      }
    } else {
      path <- pkg_path
    }
  }
  
  if (!dir.exists(path)) {
    stop("Directory not found: ", path)
  }
  
  # Find all layout.ini files
  layout_files <- list.files(
    path,
    pattern = "^layout\\.ini$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  layout_files
}
