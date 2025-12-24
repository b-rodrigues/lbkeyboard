#' lbkeyboard: Keyboard Layout Analysis and Optimization
#'
#' Tools for analyzing and optimizing keyboard layouts for Luxembourg
#' and multilingual typing. Includes layout visualization, genetic algorithm
#' optimization with a Carpalx-inspired effort model, and a composable
#' rules system for customizing optimization constraints.
#'
#' @section Layout Visualization:
#' - \code{\link{ggkeyboard}}: Plot keyboard layouts
#' - \code{\link{heatmapize}}: Create frequency heatmaps
#' - \code{\link{print_layout}}: ASCII keyboard visualization
#' - \code{\link{plot_layout}}: ggkeyboard wrapper for optimized layouts
#'
#' @section Optimization:
#' - \code{\link{optimize_layout}}: Genetic algorithm optimization
#' - \code{\link{calculate_layout_effort}}: Calculate typing effort
#' - \code{\link{compare_layouts}}: Compare multiple layouts
#'
#' @section Rules System:
#' - \code{\link{fix_keys}}: Fix keys in place (hard constraint)
#' - \code{\link{prefer_hand}}: Soft hand preference
#' - \code{\link{prefer_row}}: Soft row preference
#' - \code{\link{balance_hands}}: Hand balance preference
#' - \code{\link{keep_like}}: Match reference layout
#'
#' @docType package
#' @name lbkeyboard-package
#' @useDynLib lbkeyboard, .registration = TRUE
#' @importFrom Rcpp evalCpp
#' @importFrom GA ga
NULL
