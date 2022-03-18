#' Read the ROR data dump
#'
#' In addition to their API, ROR also provide a data dump via Zenodo (updated ~quarterly). It is stored in .zip format. This function saves to a temp directory and then turns the .json file within into a dataframe.
#' @param os Defaults to Windows - if using Apple set to "mac" to read correct files format.
#' @return A list of dataframes holding the data dump.
#' @export

read_data_dump <- function(os = "windows") {

  #file url
  zenodo_url <- "https://zenodo.org/api/records/?communities=ror-data&sort=mostrecent"

  #list of files
  response <- httr::GET(
    url = zenodo_url,
    timeout = httr::timeout(15)
  )

  #display error message if required
  if(response$status_code >= 400) {
    err_msg = httr::http_status(response)
    stop(err_msg)
  }

  #result in text format
  response_text <- httr::content(response, "text")

  #resposne df
  file_url <- jsonlite::fromJSON(response_text) |>
    dplyr::filter(created == max(created)) |>
    tidyr::unnest(files, names_repair = "unique") |>
    tidyr::unnest(links...10) |>
    dplyr::pull(download)

  #save to a temp directory
  temp_name <- tempfile()
  curl::curl_download(file_url, temp_name)

  #ui message - reading json
  usethis::ui_info("Reading .json file - may take some time.")

  #list of files
  dd_df <- utils::unzip(temp_name)[ifelse(os == "mac", 2, 1)] |>
    jsonlite::fromJSON()

  #ui message - json read successfully
  usethis::ui_done(".json file read successfully - process completed.")

  #return the data dump
  return(dd_df)



}
