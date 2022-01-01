#' Plot a keyboard using ggplot2. Originally from {ggkeyboard}
#'
#' @param keyboard Keyboard data. A data frame with the key name, what row of the keyboard it is in, and key width. Defaults to \code{\link{tkl}} (a tenkeyless layout). Other available keyboards are a full keyboard (\code{\link{full}}), 60% keyboard (\code{\link{sixty_percent}}), and a basic mac keyboard (\code{\link{mac}}).
#' @param palette Colour palette. Defaults to \code{keyboard_palette("pastel")}. To use a custom palette, create a vector with the names described in \code{\link{keyboard_palette}}.
#' @param layout Keyboard layout - one of "ansi" or "iso". Defaults to "ansi".
#' @param font_family Font used. Defaults to "Arial Unicode MS". See the \code{extrafont} package for using fonts in ggplot2.
#' @param font_size Base font size. Defaults to 3.
#' @param adjust_text_colour Whether to lighten the text colour on dark keys. Defaults to TRUE.
#' @param measurements Measurements of various aspects of the keyboard key height and width, gaps between keys and rows, etc. See \code{\link{keyboard_measurements}}.
#'
#' @import ggplot2
#' @importFrom dplyr case_when group_by ungroup left_join rowwise
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ggkeyboard()
#'
#' ggkeyboard(sixty_percent, palette = keyboard_palette("cyberpunk"))
#' }
ggkeyboard <- function(keyboard = tkl,
                        palette = keyboard_palette("pastel"),
                        layout = c("ansi", "iso"),
                        font_family = "Arial Unicode MS",
                        font_size = 2,
                        adjust_text_colour = TRUE,
                        measurements = keyboard_measurements("default")) {
  layout <- match.arg(layout)

  keyboard_layout <- dplyr::case_when(
    any(keyboard[["layout"]] == "full") ~ "full",
    any(keyboard[["layout"]] == "tkl") ~ "tkl",
    any(keyboard[["layout"]] == "mac") ~ "mac",
    any(keyboard[["layout"]] == "steno") ~ "steno",
    any(keyboard[["layout"]] == "tkl_dvorak") ~ "tkl_dvorak",
    all(keyboard[["layout"]] == "60%") ~ "60%"
  )

  keyboard_full <- construct_keyboard_outline(keyboard, keyboard_colour = palette[["keyboard"]])

  construct_plot(keyboard, keyboard_full, palette = palette, layout = layout, font_family = font_family, font_size = font_size, adjust_text_colour = adjust_text_colour, measurements = measurements, keyboard_layout = keyboard_layout)
}



construct_keyboard <- function(keyboard = tkl, palette = keyboard_palette("pastel"), layout = c("ansi", "iso"), font_size = 3, adjust_text_colour = TRUE, measurements = keyboard_measurements("default"), keyboard_layout = "tkl") {
  layout <- match.arg(layout)

  palette_df <- tibble::enframe(palette, name = "key_type", value = "fill")

  keyboard <- keyboard %>%
    dplyr::mutate(
      width = measurements[["key_width"]] * width,
      width = width + measurements[["width_gap"]] * (width - measurements[["key_width"]]),
      height = measurements[["key_height"]] * height,
      height = height + measurements[["height_gap"]] * (height - measurements[["key_height"]])
    ) %>%
    dplyr::group_by(row) %>%
    dplyr::mutate(
      gap = ifelse(number == 1, 0, measurements[["width_gap"]]),
      x_start = cumsum(width) - width + cumsum(gap),
      x_mid = x_start + width / 2,
      x_end = x_start + width
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      y_start = (measurements[["height_gap"]] * ifelse(row == 6 & keyboard_layout != "mac", 2, 1) + measurements[["key_height"]]) * (row - 1),
      y_mid = y_start + height / 2,
      y_end = y_start + height,
      size = font_size * dplyr::case_when(
        key %in% LETTERS ~ 1.75,
        TRUE ~ 1
      )
    ) %>%
    dplyr::left_join(palette_df, by = "key_type") %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      text_colour = text_colour_adjust(fill, palette[["text"]], adjust_text_colour)
    ) %>%
    dplyr::ungroup()

  keyboard[["colour"]] <- unclass(prismatic::clr_darken(keyboard[["fill"]], 0.1))

  keyboard %>%
    dplyr::mutate(colour = ifelse(is.na(key), NA_character_, colour))
}

construct_keyboard_outline <- function(keyboard, keyboard_colour = keyboard_palette("pastel")[["keyboard"]]) {
  dplyr::tibble(
    x_start = min(keyboard[["x_start"]]),
    x_end = max(keyboard[["x_end"]]),
    y_start = min(keyboard[["y_start"]]),
    y_end = max(keyboard[["y_end"]])
  ) %>%
    dplyr::mutate(
      x_mid = (x_end - x_start) / 2,
      y_mid = (y_end - y_start) / 2,
      fill = keyboard_colour
    )
}

construct_plot <- function(keyboard, keyboard_full, palette, layout = c("ansi", "iso"), font_family, font_size, adjust_text_colour, measurements, keyboard_layout) {

  layout <- match.arg(layout)

  p <- ggplot2::ggplot() +
    ggforce::geom_ellipse(data = keyboard_full, ggplot2::aes(x0 = x_mid, y0 = y_mid, a = x_mid * 1.05, b = y_mid * 1.1, angle = 0, m1 = 100, fill = fill, colour = prismatic::clr_darken(fill, 0.10)), size = 1) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_identity() +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = palette[["background"]], colour = palette[["background"]]),
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )

  # Add keys ----
  p <- p +
      ggforce::geom_ellipse(data = keyboard, ggplot2::aes(x0 = x_mid, y0 = y_mid, a = width / 2, b = height / 2, angle = 0, m1 = 10, fill = fill, colour = colour), size = 1) +
      ggplot2::geom_text(data = keyboard %>%
        dplyr::filter(!is.na(key_label)), ggplot2::aes(x = x_start + width / 2, y = (y_start + y_end) / 2, label = key_label, size = size, colour = text_colour), family = font_family, lineheight = 0.9)

  # Add arrows if present in layout, and power button for mac
  if (keyboard_layout %in% c("tkl", "full", "mac")) {
    arrows <- keyboard %>%
      dplyr::filter(key %in% c("Up", "Down", "Left", "Right", "UpDown"))

    arrow_colour <- text_colour_adjust(arrows[["fill"]], palette[["text"]], adjust_text_colour)

    arrows <- arrows %>%
      split(.$key)

    if (keyboard_layout == "mac") {

      p <- p +
        ggplot2::geom_segment(data = arrows[["Left"]], ggplot2::aes(x = x_end, xend = x_start + 0.375*width, y = y_mid, yend = y_mid, colour = NA_character_), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc"), type = "closed"), size = measurements[["segment_size"]], arrow.fill = arrow_colour, alpha = 0.80) +
        ggplot2::geom_segment(data = arrows[["Right"]], ggplot2::aes(xend = x_end - 0.375*width, x = x_start, y = y_mid, yend = y_mid, colour = NA_character_), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc"), type = "closed"), size = measurements[["segment_size"]], arrow.fill = arrow_colour, alpha = 0.80) +
        ggplot2::geom_segment(data = arrows[["UpDown"]], ggplot2::aes(x = x_start, xend = x_end, y = y_mid, yend = y_mid, colour = colour), size = 1) +
        ggplot2::geom_segment(data = arrows[["UpDown"]], ggplot2::aes(x = x_mid, xend = x_mid, yend = y_start + (0.375/3)*height, y = y_mid, colour = NA_character_), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc"), type = "closed"), size = measurements[["segment_size"]], arrow.fill = arrow_colour, alpha = 0.80) +
        ggplot2::geom_segment(data = arrows[["UpDown"]], ggplot2::aes(x = x_mid, xend = x_mid, yend = y_end - (0.375/3)*height, y = y_mid, colour = NA_character_), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc"), type = "closed"), size = measurements[["segment_size"]], arrow.fill = arrow_colour, alpha = 0.80)

      power <- keyboard %>%
        dplyr::filter(key == "Power")

      power_colour <- text_colour_adjust(power[["fill"]], palette[["text"]], adjust_text_colour)

      p <- p +
        ggplot2::geom_segment(data = power,  ggplot2::aes(x = x_mid, xend = x_mid, yend = y_end - (0.375)*height, y = y_mid, colour = NA_character_), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc"), type = "closed", angle = 50), size = measurements[["segment_size"]], arrow.fill = arrow_colour, alpha = 0.80) +
        ggplot2::geom_segment(data = power,  ggplot2::aes(x = x_mid - 0.175*width, xend = x_mid + 0.175*width, yend = y_mid - (0.375/4)*height, y = y_mid - (0.375/4)*height, colour = arrow_colour), size = measurements[["segment_size"]]*2, alpha = 0.80)

    } else {

    p <- p +
      ggplot2::geom_segment(data = arrows[["Down"]], ggplot2::aes(x = x_mid, xend = x_mid, y = (y_end + y_mid) / 2, yend = (y_start + y_mid) / 2, colour = arrow_colour), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc")), size = measurements[["segment_size"]]) +
      ggplot2::geom_segment(data = arrows[["Up"]], ggplot2::aes(x = x_mid, xend = x_mid, yend = (y_end + y_mid) / 2, y = (y_start + y_mid) / 2, colour = arrow_colour), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc")), size = measurements[["segment_size"]]) +
      ggplot2::geom_segment(data = arrows[["Left"]], ggplot2::aes(x = (x_end + x_mid) / 2, xend = (x_start + x_mid) / 2, y = y_mid, yend = y_mid, colour = arrow_colour), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc")), size = measurements[["segment_size"]]) +
      ggplot2::geom_segment(data = arrows[["Right"]], ggplot2::aes(xend = (x_end + x_mid) / 2, x = (x_start + x_mid) / 2, y = y_mid, yend = y_mid, colour = arrow_colour), arrow = ggplot2::arrow(length = ggplot2::unit(measurements[["arrow_size"]], "npc")), size = measurements[["segment_size"]])
    }
  }

  # Draw on backspace/shift buttons
  backspace <- keyboard %>%
    dplyr::filter(key == "Backspace")

  backspace_colour <- text_colour_adjust(unique(backspace[["fill"]]), palette[["text"]], adjust_text_colour)

  shift <- keyboard %>%
    dplyr::filter(stringr::str_detect(key, "Shift"))

  if(nrow(shift) > 0){

  shift_colour <- text_colour_adjust(unique(shift[["fill"]]), palette[["text"]], adjust_text_colour)

  p <- p +
    # Backspace
    ggplot2::geom_segment(data = backspace, ggplot2::aes(x = (x_end + x_mid) / 2, xend = (x_start + x_mid) / 2, y = y_mid, yend = y_mid, colour = backspace_colour), arrow = ggplot2::arrow(length = ggplot2::unit(0.02, "npc")), size = measurements[["segment_size"]]) +
    # Shift arrows
    ggplot2::geom_segment(data = shift, ggplot2::aes(x = x_mid - measurements[["key_width"]] * 0.1, xend = x_mid - measurements[["key_width"]] * 0.1, y = (y_start + y_mid) / 2, yend = y_mid, colour = shift_colour), size = measurements[["segment_size"]]) +
    ggplot2::geom_segment(data = shift, ggplot2::aes(x = x_mid + measurements[["key_width"]] * 0.1, xend = x_mid + measurements[["key_width"]] * 0.1, y = (y_start + y_mid) / 2, yend = y_mid, colour = shift_colour), size = measurements[["segment_size"]]) +
    ggplot2::geom_segment(data = shift, ggplot2::aes(x = x_mid - measurements[["key_width"]] * 0.25, xend = x_mid, y = y_mid, yend = (y_end + y_mid) / 2, colour = shift_colour), size = measurements[["segment_size"]]) +
    ggplot2::geom_segment(data = shift, ggplot2::aes(x = x_mid, xend = x_mid + measurements[["key_width"]] * 0.25, yend = y_mid, y = (y_end + y_mid) / 2, colour = shift_colour), size = measurements[["segment_size"]]) +
    ggplot2::geom_segment(data = shift, ggplot2::aes(x = x_mid + measurements[["key_width"]] * 0.1, xend = x_mid + measurements[["key_width"]] * 0.25, yend = y_mid, y = y_mid, colour = shift_colour), size = measurements[["segment_size"]]) +
    ggplot2::geom_segment(data = shift, ggplot2::aes(x = x_mid - measurements[["key_width"]] * 0.25, xend = x_mid - measurements[["key_width"]] * 0.1, yend = y_mid, y = y_mid, colour = shift_colour), size = measurements[["segment_size"]])
  }

    # Draw on lights - above Ins, Home, PgUp if tkl, and above numpad if full
    if (keyboard_layout == "tkl") {

      lights <- keyboard %>%
        dplyr::filter(key %in% c("Ins", "Home", "PgUp"))

      p <- p +
        ggplot2::geom_point(data = lights, ggplot2::aes(x = x_mid, y = y_end + measurements[["height_gap"]] * 3), size = 2.5, colour = palette[["light"]], alpha = 0.75)
    } else if (keyboard_layout == "full") {

      numpad_x <- keyboard %>%
        dplyr::filter(layout == "full", !is.na(key)) %>%
        dplyr::distinct(x_start, x_end)

      lights_x <- seq(from = min(numpad_x[["x_start"]]), to = max(numpad_x[["x_end"]]), length.out = 5)
      lights_x <- lights_x[c(2:4)]

      lights_y <- keyboard %>%
        dplyr::filter(row == 6) %>%
        dplyr::pull(y_mid) %>%
        unique()

      lights <- dplyr::tibble(x = lights_x,
                       y = lights_y)
      p <- p +
        ggplot2::geom_point(data = lights, ggplot2::aes(x = x, y = y), size = 2.5, colour = palette[["light"]], alpha = 0.75)
    }

  # Add symbols in Win key
  windows <- keyboard %>%
    dplyr::filter(key %in% c("Win Left", "Win Right"))

  p <- p +
    ggplot2::geom_text(data = windows, ggplot2::aes(x = x_mid, y = y_mid, colour = text_colour), label = "\u{263A}", size = font_size * 2)

  # Final layout aspects
  p <- p +
    ggplot2::coord_equal() +
    ggplot2::scale_size_identity()

  if (layout == "iso") {
    enter <- keyboard %>%
      dplyr::filter(key == "Enter" & layout == "60%")

    enter <- dplyr::tibble(
      xmin = enter[1, ][["x_start"]],
      xmax = enter[1, ][["x_end"]],
      xmid_top = enter[2, ][["x_mid"]],
      ymin = enter[1, ][["y_end"]],
      ymax = enter[2, ][["y_start"]],
      ymid_top = enter[2, ][["y_mid"]],
      colour = unique(enter[["colour"]]),
      fill = unique(enter[["fill"]]),
      text_colour = unique(enter[["text_colour"]])
    )

    p <- p +
      ggplot2::geom_rect(data = enter, ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin * 0.95, ymax = ymax * 1.05, colour = fill, fill = fill), size = 1) +
      ggplot2::geom_segment(data = enter, ggplot2::aes(x = xmin, xend = xmin, y = ymin * 0.90, yend = ymax * 1.01, colour = colour), size = 1) +
      ggplot2::geom_segment(data = enter, ggplot2::aes(x = xmax, xend = xmax, y = ymin * 0.90, yend = ymax * 1.1, colour = colour), size = 1) +
      ggplot2::annotate("text", x = ifelse(keyboard_layout == "mac", enter[["xmid_top"]], (enter[["xmin"]] + enter[["xmax"]]) / 2), y = ifelse(keyboard_layout == "mac", enter[["ymid_top"]], (enter[["ymin"]] + enter[["ymax"]]) / 2), label = "Enter", family = font_family, colour = enter[["text_colour"]])
  }

  p
}

is_dark <- function(colour) {
  (sum(grDevices::col2rgb(colour) * c(299, 587, 114)) / 1000 < 123)
}

text_colour_adjust <- function(fill, text_colour, adjust_text_colour) {

  fill_dark <- is_dark(fill)
  text_colour_dark <- is_dark(text_colour)

  dplyr::case_when(fill_dark & adjust_text_colour & text_colour_dark ~ prismatic::clr_lighten(text_colour),
                   !fill_dark & adjust_text_colour & !text_colour_dark ~ prismatic::clr_darken(text_colour),
                   TRUE ~ text_colour)
}


#' Keyboard palettes
#'
#' Built-in palettes for keyboards.
#'
#' There are four palettes available:
#' * "pastel" is just cute.
#' * "serika" is based off the [Drop + Zambumon MT3 Serika Custom Keycap Set](https://drop.com/buy/drop-zambumon-mt3-serika-custom-keycap-set).
#' * "wahtsy" is based off the [Melgeek MG Wahtsy ABS Doubleshot Keycap Set](https://drop.com/buy/melgeek-mg-wahtsy-abs-doubleshot-keycap-set).
#' * "cyberpunk" is based off the [Domikey ABS Doubleshot SA Cyberpunk Pumper Keycap Set](https://drop.com/buy/domikey-abs-doubleshot-sa-cyberpunk-pumper-keycap-set).
#' * "magic" is based off the [Apple magic keyboard](https://www.apple.com/shop/product/MLA22LL/A/magic-keyboard-us-english).
#' * "varmilo" is based off the [Varmilo VA108 Fullsize Keyboard](https://drop.com/buy/varmilo-108-keyboard).
#' * "t0mb3ry" is based off the [Drop + T0mb3ry SA Yuri Custom Keycap Set](https://drop.com/buy/drop-t0mb3ry-sa-yuri-custom-keycap-set)
#'
#' The palettes have the following fields:
#' * background: Colour of background.
#' * keyboard: Colour of keyboard.
#' * alphanumeric: Colour of alpha-numeric keys and other common text keys (e.g. <, :, etc).
#' * accent: Colour of accent keys (F1-4, F9-12, and the spacebar).
#' * modifier: Colour of modifier keys (e.g. Shift, Print, Insert, etc).
#' * numpad: Colour of numpad (non-modifier) keys (1-9).
#' * arrow: Colour of arrow-pad keys.
#' * light: Colour of lights on the keyboards.
#' * text: Text colour.
#'
#' @param palette Name of palette.
#' @export
#' @examples
#' \dontrun{
#' library(scales)
#' show_col(keyboard_palette("pastel"))
#'
#' ggkeyboard(palette = keyboard_palette("cyberpunk"))
#' }
keyboard_palette <- function(palette = c("pastel", "serika", "wahtsy", "cyberpunk", "magic", "varmilo", "t0mb3ry")) {

  palette <- match.arg(palette)

  switch(palette,
    pastel = c(
      background = "#fce9d0",
      keyboard = "#fbbcb8",
      alphanumeric = "#bfdff6",
      accent = "#a3e3c4",
      modifier = "#78baeb",
      numpad = "#bfdff6",
      arrow = "#c1b3ef",
      light = "#F9958F",
      text = "#5F5F5F"
    ),
    serika = c(
      background = "lightgrey",
      keyboard = "#51504A",
      alphanumeric = "#EDEDD8",
      accent = "#454A49",
      modifier = "#ffce00",
      numpad = "#EDEDD8",
      arrow = "#454A49",
      light = "#8aff2b",
      text = "#5F5F5F"
    ),
    wahtsy = c(
      background = "#F0F0F0",
      keyboard = "#E5E7EB",
      alphanumeric = "#DFDED9",
      accent = "#F9B668",
      modifier = "#155E90",
      numpad = "#DFDED9",
      arrow = "#155E90",
      light = "#CBCFD7",
      text = "#f97600"
    ),
    cyberpunk = c(
      background = "#F0F0F0",
      keyboard = "#313131",
      alphanumeric = "#6F4CA4",
      accent = "#00A8E8",
      modifier = "#FF4893",
      numpad = "#6F4CA4",
      arrow = "#00A8E8",
      light = "#2C2C2C",
      text = "white"
    ),
    magic = c(
      background = "white",
      keyboard = "#c8cad0",
      alphanumeric = "white",
      accent = "white",
      modifier = "white",
      numpad = "white",
      arrow = "white",
      light = "white",
      text = "darkgrey"
    ),
    varmilo = c(
      background = "#707173",
      keyboard = "#DDE3E7",
      alphanumeric = "#ffdde2",
      accent = "#ffdde2",
      modifier = "#a0d8f3",
      numpad = "#ffdde2",
      arrow = "#a0d8f3",
      light = "#9FD2FF",
      text = "#456DC1"
    ),
    t0mb3ry = c(
      background = "white",
      keyboard = "#423F40",
      alphanumeric = "#B2D2F2",
      accent = "#ff4619",
      modifier = "#29384E",
      numpad = "#B2D2F2",
      arrow = "#29384E",
      light = "#ff4619",
      text = "#ff5b33"
    )
  )
}

#' Keyboard Measurements
#'
#' Measurement options for \code{\link{ggkeyboard}}.
#'
#' There are the following options:
#' * key_height: Height of keys.
#' * key_width: Base width of keys.
#' * height_gap: Height gap between rows of keys.
#' * width_gap: Width gap between keys in the same row.
#' * segment_size: Size of segments used to draw arrows.
#' * arrow_size; Size of arrow head.
#'
#' @param name Measurement options name.
#'
#' @export
keyboard_measurements <- function(name = "default") {
  name <- match.arg(name)

  switch(name,
         default = c(
           key_height = 15 / 15.5,
           key_width = 1,
           height_gap = 2 / 15.5,
           width_gap = 2 / 15.5,
           segment_size = 0.25,
           arrow_size = 0.03
         )
         )
}
