#' Return record for a single specified organisation.
#'
#' Returns the details from ROR API for the organisation specified.
#' @param id The ROR ID of the organisation in question. Can be found using `get_org_list()` or via looking up on the ROR website.
#' @param include_non_active Option to include 'inactive' or 'withdrawn' entities. Must be 'true' or 'false'.
#' @return A list holding the pertinent details for the chosen organisation.
#' @export

get_single_org <- function(id, include_non_active = "false") {


  #run query
  result <- httr::GET(
    url = paste0("https://api.ror.org/organizations/", id, "?all_status=", include_non_active)
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
