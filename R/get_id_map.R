#' Get a map of different organisation IDs.
#'
#' ROR holds multiple types of unique ID for organisations. This function let's you enter one such ID and return all the other IDs in the database for that organisation. NOTE THIS FUNCTION IS ONLY RECOMMENDED IF YOU HAVE A RELATIVELY SMALL NUMBER OF IDs TO MAP. Otherwise use `read_data_dump()` to access a snapshot of the full dataset.
#' @param id The unique, non-ROR ID for the organisation concerned.
#' @return A list of any available IDs (or a message confirming a match could not be found).
#' @export

get_id_map <- function(id) {

  #convert id into format for entering into query
  fmt_id <- paste0("%22", id, "%22")

  #list of files
  response <- httr::GET(
    url = paste0("https://api.ror.org/organizations?query=", fmt_id),
    timeout = httr::timeout(15)
  )

  #display error message if required
  if(response$status_code >= 400) {
    err_msg = httr::http_status(response)
    stop(err_msg)
  }

  #response text
  response_text <- httr::content(response, "text")

  #json
  response_json <- jsonlite::fromJSON(response_text)

  #checkl if there are actually any results
  if(length(response_json$items) == 0) {

    print("No results found - stopping process")

    return("No IDs found")

    }

  #response df
  response_df <- dplyr::bind_cols(
    response_json[["items"]][["name"]],
    response_json[["items"]][["external_ids"]]
  )

  #column names - use to make sensible names later
  response_colnames <- colnames(response_df)[2:length(colnames(response_df))]

  #new colnames
  new_colnames <- c()

  for (c in response_colnames) {

    new_colnames[2 * match(c, response_colnames) - 1] <- paste0("preferred_", c)
    new_colnames[2 * match(c, response_colnames)] <- paste0("all_", c)

  }

  #unnest response and set new names
  response_final <- response_df |>
    tidyr::unnest(cols = dplyr::everything(), names_repair = "unique") |>
    stats::setNames(c("name", new_colnames)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character)) |>
    tidyr::pivot_longer(
      cols = -1,
      names_to = "temp",
      values_to = "id"
    ) |>
    tidyr::separate(
      temp,
      into = c("type", "source"),
      sep = "_"
    )



}
