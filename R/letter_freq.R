#' Counts the frequency of each letter in a string of text
#'
#' @param text A string
#' @param only_alpha TRUE (default) or FALSE. Should only letters be considered? If FALSE, every character is taken into account.
#' @return A dataframe with 4 columns. \code{characters} contains the characters; \code{total} the total number of times the characters appears in the text, \code{scaled} is the min-max transform of \code{total} and \code{frequencies} are the relative frequencies of appearance of each letter.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create some random string
#' text <- sample(replicate(10, letters), replace = TRUE)
#' letter_freq(text)
#' }
letter_freq <- function(text, only_alpha = TRUE){
  text %>%
    purrr::map(~strsplit(., split = "")) %>%
    unlist() %>%
    purrr::map(~strsplit(., split = "")) %>%
    unlist() %>%
    tolower() %>%
    {
      if(only_alpha){
        stringr::str_extract_all(string = ., pattern = "[:alpha:]") 
      } else {
        .
      }
    } %>%
    unlist() %>%
    table() %>%
    as.data.frame() %>%
    dplyr::rename(characters = ".",
           total = Freq) %>%
    dplyr::filter(characters != " ") %>%
    dplyr::filter(characters != "") %>%
    dplyr::mutate(scaled = min_max(total)) %>%
    dplyr::mutate(frequencies =total/sum(total)) %>%
    dplyr::arrange(desc(frequencies))
}


