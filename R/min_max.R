#' Standardizes an atomic vector of numbers using the min-max method
#'
#' @param x An atomic vector of numbers
#'
#' @export
#'
#' @examples
#' \dontrun{
#' min_max(seq(1, 10))
#' }
min_max <- function(x){
  (x - min(x))/(max(x)-min(x))
}
