#' Return record for a single specified organisation.
#'
#' Returns the details from ROR API for the organisation specified.
#' @param id The ROR ID of the organisation in question. Can be found using `get_org_list()` or via looking up on the ROR website.
#' @return A list holding the pertinent details for the chosen organisation.
#' @export

get_single_org <- function(id) {

  #run query
  result <- httr::GET(
    url = paste0("https://api.ror.org/organizations/", id)
  )

  #error result if needed
  if(result$status_code >= 400) {
    err_msg = httr::http_status(result)
    stop(err_msg)
  }

  #text format
  result_text <- httr::content(result, "text")

  #json
  result_json <- jsonlite::fromJSON(result_text)

}
