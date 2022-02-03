#' Helper function - returns org list details one page at a time..
#'
#' Created as a helper function to return org list results one page at a time. Can be used in its own right, however.
#' @param ..page_num Return a specific page number. Enter as an integer - if not set, defaults to 1.
#' @param ..search_terms Query term to narrow results if desired. Separate multiple terms with "|" to search on an OR basis. Will search all indexed fields.
#' @param ..affiliation Specific search term for an affiliation. The API determines closeness of match - only those deemed close enough ('chosen') returned. Will only search name, label and alias fields. You cannot combine affiliation searches with filters.
#' @param ..org_type Only return specified type of organisation. Any of "Education", "Healthcare", "Company", "Archive", "Nonprofit", "Government", "Facility" or "Other".
#' @param ..country_code Filter to specific countries as per the ISO 3166 alpha-2 list. Can combine with `..org_type` filter.
#' @param ..country_name Alternatively, filter by country code instead of name. Can combine with `..org_type` filter.
#' @return A dataframe holding the first page of results from the API.
#' @export
#'

get_results_by_page <- function(
  ..page_num = 1,
  ..search_terms,
  ..affiliation,
  ..org_type,
  ..country_code,
  ..country_name
)  {

  #sleep for 1 second to avoid throttling when use in `get_org_list()`
  Sys.sleep(1)

  #hack to deal with missing errors
  ot_hack <- if(missing(..org_type)) {"blah"} else {..org_type}
  cc_hack <- if(missing(..country_code)) {"blah"} else {..country_code}
  cn_hack <- if(missing(..country_name)) {"blah"} else {..country_name}

  #error handling----------------------------------------------

  #type
  if(!missing(..org_type) & !ot_hack %in% c("Education", "Healthcare", "Company", "Archive", "Nonprofit", "Government", "Facility", "Other"))
    stop("`.org_type` must be (if used) one of: 'Education', 'Healthcare', 'Company', 'Archive', 'Nonprofit', 'Government', 'Facility', or 'Other'.")

  #only one org type, country code, or country
  if(
    (!missing(..org_type) & length(ot_hack) > 1) |
    (!missing(..country_code) & length(cc_hack) > 1) |
    (!missing(..country_name) & length(cn_hack) > 1)
  ) stop("You can only enter a single filter value for each parameter.")

  #only filter one of country_code or country_name
  if(!missing(..country_code) & !missing(..country_name))
    stop("You can only filter one of `.country_code` or `.country_name`.")

  #only search affiliation if chosen
  if(!missing(..affiliation) & (!missing(..search_terms) | !missing(..org_type) | !missing(..country_code) | !missing(..country_name)))
    stop("If using `..affiliation` you can not use `.search_terms` or any filters.")

  #turn spaces into "%20" for upload-------------------------------------------------

  #affiliation
  if(!missing(..affiliation)) {..affiliation <- gsub(" ", "%20", ..affiliation)}

  #search terms
  if(!missing(..search_terms)) {..search_terms <- gsub(" ", "%20", ..search_terms)}

  #country name
  if(!missing(..country_name)) {..country_name <- gsub(" ", "%20", ..country_name)}

  #query settings for prelimianry run (to identify number of pages)-----------------------------------------------

  #affiliation entered
  if(!missing(..affiliation)) {

      .query_settings <- list(
        page = ..page_num,
        affiliation = ..affiliation
        )

      #no parameters (except maybe page number)
  } else if (
    missing(..search_terms) &
    missing(..org_type) &
    missing(..affiliation) &
    missing(..country_code) &
    missing(..country_name)
  ) {

    .query_settings <- list(
      page = ..page_num
    )

    #search term (plus possibly page_number) only
    } else if(!missing(..search_terms) & missing(..org_type) & missing(..country_code) & missing(..country_name)) {

  .query_settings <- list(
    page = ..page_num,
    query = ..search_terms
  )

  #search term and org_type (plus possibly page_number)
} else if(!missing(..search_terms) & !missing(..org_type) & missing(..country_code) & missing(..country_name)) {

  .query_settings <- list(
    page = ..page_num,
    query = ..search_terms,
    filter = paste0("types:", ..org_type)
  )

  #search term, org_type and country code
} else if(!missing(..search_terms) & !missing(..org_type) & !missing(..country_code)) {

  .query_settings <- list(
    page = ..page_num,
    query = ..search_terms,
    filter = paste0("types:", ..org_type, ",country.country_code:", ..country_code)
  )

  #search term, org_type and country name
} else if(!missing(..search_terms) & !missing(..org_type) & !missing(..country_name)) {

  .query_settings <- list(
    page = ..page_num,
    query = ..search_terms,
    filter = paste0("types:", ..org_type, ",country.country_name:", ..country_name)
  )

  #org type only
} else if(missing(..search_terms) & !missing(..org_type) & missing(..country_code) & missing(..country_name)) {

  .query_settings <- list(
    page = ..page_num,
    filter = paste0("types:", ..org_type)
  )

  #org_type and country code
}  else if(missing(..search_terms) & !missing(..org_type) & !missing(..country_code)) {

  .query_settings <- list(
    page = ..page_num,
    filter = paste0("types:", ..org_type, ",country.country_code:", ..country_code)
  )

  #org_type and country name
} else if(missing(..search_terms) & !missing(..org_type) & !missing(..country_name)) {

  .query_settings <- list(
    page = ..page_num,
    filter = paste0("types:", ..org_type, ",country.country_name:", ..country_name)
  )

  #country code only
} else if(missing(..search_terms) & missing(..org_type) & !missing(..country_code)) {

  .query_settings <- list(
    page = ..page_num,
    filter = paste0("country.country_code:", ..country_code)
  )

  #country name only
} else if(missing(..search_terms) & missing(..org_type) & !missing(..country_name)) {

  .query_settings <- list(
    page = ..page_num,
    filter = paste0("country.country_name:", ..country_name)
  )

} else if(!missing(..search_terms) & missing(..org_type) & !missing(..country_code)) {

  .query_settings <- list(
    page = 1,
    query = .search_terms,
    filter = paste0("country.country_code:", .country_code)
  )

  #search terms and country name
} else if(!missing(..search_terms) & missing(..org_type) & !missing(..country_name)) {

  .query_settings <- list(
    page = 1,
    query = ..search_terms,
    filter = paste0("country.country_name:", ..country_name)
  )

}

#run query--------------------------------------

#try running query
result <- httr::GET(
  url = paste0("https://api.ror.org/organizations"),
  query = .query_settings,
  timeout = httr::timeout(15)
)

#display error message if required
if(result$status_code >= 400) {
  err_msg = httr::http_status(result)
  stop(err_msg)
}

#results of query-=------------------

#text
result_text <- httr::content(result, "text")

#json
result_json <- jsonlite::fromJSON(result_text)

#final results, depending on whether affiliation used or not
if(missing(..affiliation)){

  result_df <- result_json[["items"]]

} else {

  results_df <- result_json[["items"]] |>
    dplyr::filter(chosen == T) |>
    tidyr::unnest(organization)

}

}
