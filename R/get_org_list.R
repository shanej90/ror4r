#' Query organisation records to return a list; you can add query terms to refine results.
#'
#' By defaults returns all results from the API. Also let's you specify a specific page number, filter your results by specific categories, or add search terms to your query to refine the results. It is HIGHLY RECOMMENDED you filter your results in some way to minimise running times.
#' @param .search_terms Query term to narrow results if desired. Separate multiple terms with "|" to search on an OR basis. Will search all indexed fields.
#' @param .affiliation Specific search term for an affiliation. The API determines closeness of match - only those deemed close enough ('chosen') returned. Will only search name, label and alias fields. You cannot combine affiliation searches with filters.
#' @param .org_type Only return specified type of organisation. Any of "Education", "Healthcare", "Company", "Archive", "Nonprofit", "Government", "Facility" or "Other".
#' @param .country_code Filter to specific countries as per the ISO 3166 alpha-2 list. Can combine with `.org_type` filter.
#' @param .country_name Alternatively, filter by country code instead of name. Can combine with `.org_type` filter.
#' @param .page_numbers Return a specific page number (or set of page numbers). Enter as a numeric vector. All results will be returned if you do not specify. If you specify page numbers that are not found, all results will be returned.
#' @return A dataframe holding results as per specifications (list of all orgs returned if no parameters are set).
#' @export

get_org_list <- function(
  .search_terms,
  .affiliation,
  .org_type,
  .country_code,
  .country_name,
  .page_numbers
) {

  #hack to deal with missing errors
  ot_hack <- if(missing(.org_type)) {"blah"} else {.org_type}
  cc_hack <- if(missing(.country_code)) {"blah"} else {.country_code}
  cn_hack <- if(missing(.country_name)) {"blah"} else {.country_name}

  #error handling----------------------------------------------

  #type
  if(!missing(.org_type) & !ot_hack %in% c("Education", "Healthcare", "Company", "Archive", "Nonprofit", "Government", "Facility", "Other"))
    stop("`.org_type` must be (if used) one of: 'Education', 'Healthcare', 'Company', 'Archive', 'Nonprofit', 'Government', 'Facility', or 'Other'.")

  #only one org type, country code, or country
  if(
    (!missing(.org_type) & length(ot_hack) > 1) |
    (!missing(.country_code) & length(cc_hack) > 1) |
    (!missing(.country_name) & length(cn_hack) > 1)
  ) stop("You can only enter a single filter value for each parameter.")

  #only filter one of country_code or country_name
  if(!missing(.country_code) & !missing(.country_name))
    stop("You can only filter one of `.country_code` or `.country_name`.")

  #only search affiliation if chosen
  if(!missing(.affiliation) & (!missing(.search_terms) | !missing(.org_type) | !missing(.country_code) | !missing(.country_name)))
    stop("If using `.affiliation` you can not use `.search_terms` or any filters.")


  #turn spaces into "%20" for upload-------------------------------------------------

  #affiliation
  if(!missing(.affiliation)) {.affiliation <- gsub(" ", "%20", .affiliation)}

  #search terms
  if(!missing(.search_terms)) {.search_terms <- gsub(" ", "%20", .search_terms)}

  #country name
  if(!missing(.country_name)) {.country_name <- gsub(" ", "%20", .country_name)}

  #query settings for prelimianry run (to identify number of pages)-----------------------------------------------

  #no paramaters set (or only page numbers)
  if(
    missing(.search_terms) &
    missing(.affiliation) &
    missing(.org_type) &
    (missing(.country_code) | missing(.country_name))
  ) {

    query_settings <- list(
      page = 1
    )

    #affiliation entered
  } else if(!missing(.affiliation)) {

    query_settings <- list(
      page = 1,
      affiliation = .affiliation
    )

    #search term (plus possibly page_number) only
  } else if(!missing(.search_terms) & missing(.org_type) & missing(.country_code) & missing(.country_name)) {

    query_settings <- list(
      page = 1,
      query = .search_terms
    )

    #search term and org_type (plus possibly page_number)
  } else if(!missing(.search_terms) & !missing(.org_type) & missing(.country_code) & missing(.country_name)) {

    query_settings <- list(
      page = 1,
      query = .search_terms,
      filter = paste0("types:", .org_type)
    )

    #search term, org_type and country code
  } else if(!missing(.search_terms) & !missing(.org_type) & !missing(.country_code)) {

    query_settings <- list(
      page = 1,
      query = .search_terms,
      filter = paste0("types:", .org_type, ",country.country_code:", .country_code)
    )

    #search term, org_type and country name
  } else if(!missing(.search_terms) & !missing(.org_type) & !missing(.country_name)) {

    query_settings <- list(
      page = 1,
      query = .search_terms,
      filter = paste0("types:", .org_type, ",country.country_name:", .country_name)
    )

    #org type only
  } else if(missing(.search_terms) & !missing(.org_type) & missing(.country_code) & missing(.country_name)) {

    query_settings <- list(
      page = 1,
      filter = paste0("types:", .org_type)
    )

    #org_type and country code
  }  else if(missing(.search_terms) & !missing(.org_type) & !missing(.country_code)) {

    query_settings <- list(
      page = 1,
      filter = paste0("types:", .org_type, ",country.country_code:", .country_code)
    )

    #org_type and country name
  } else if(missing(.search_terms) & !missing(.org_type) & !missing(.country_name)) {

    query_settings <- list(
      page = 1,
      filter = paste0("types:", .org_type, ",country.country_name:", .country_name)
    )

    #country code only
  } else if(missing(.search_terms) & missing(.org_type) & !missing(.country_code)) {

    query_settings <- list(
      page = 1,
      filter = paste0("country.country_code:", .country_code)
    )

    #country name only
  } else if(missing(.search_terms) & missing(.org_type) & !missing(.country_name)) {

    query_settings <- list(
      page = 1,
      filter = paste0("country.country_name:", .country_name)
    )

    #search term and country code
  } else if(!missing(.search_terms) & missing(.org_type) & !missing(.country_code)) {

    query_settings <- list(
      page = 1,
      query = .search_terms,
      filter = paste0("country.country_code:", .country_code)
    )

    #search terms and country name
  } else if(!missing(.search_terms) & missing(.org_type) & !missing(.country_name)) {

    query_settings <- list(
      page = 1,
      query = .search_terms,
      filter = paste0("country.country_name:", .country_name)
    )

  }

  #run preliminary query--------------------------------------

  #try running query
  prelim_result <- httr::GET(
    url = paste0("https://api.ror.org/organizations"),
    query = query_settings,
    timeout = httr::timeout(15)
  )

  #display error message if required
  if(prelim_result$status_code >= 400) {
    err_msg = httr::http_status(prelim_result)
    stop(err_msg)
  }

  #results of preliminary query - use to determine page numbers if required-=------------------

  #text
  prelim_result_text <- httr::content(prelim_result, "text")

  #json
  prelim_result_json <- jsonlite::fromJSON(prelim_result_text)

  #total pages
  total_pages <- ceiling((prelim_result_json$number_of_results / 20))

  #determine page numbers
  if(missing(.page_numbers)) {

    #pages bector
    pages <- c(1:total_pages)

  } else if (any(.page_numbers > total_pages)) {

    pages <- c(1:total_pages)

  } else {

    pages <- .page_numbers

    }

  #get all required results-------------------------------------------

  #affiliation parameter
  if(!missing(.affiliation)) {


    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..affiliation = .affiliation
    ) |>
      dplyr::bind_rows()

    #no parameters
  } else if(
    missing(.affiliation) &
    missing(.org_type) &
    missing(.country_code) &
    missing(.country_name) &
    missing(.search_terms)
    ) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page
    ) |>
      dplyr::bind_rows()


    #search term only
  } else if(!missing(.search_terms) & missing(.org_type) & missing(.country_code) & missing(.country_name)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..search_terms = .search_terms
    ) |>
      dplyr::bind_rows()


    #search term and org type
  } else if(!missing(.search_terms) & !missing(.org_type) & missing(.country_code) & missing(.country_name)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..search_terms = .search_terms,
      ..org_type = .org_type
    ) |>
      dplyr::bind_rows()

    #search term, org_type and country code
  } else if(!missing(.search_terms) & !missing(.org_type) & !missing(.country_code)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..search_terms = .search_terms,
      ..org_type = .org_type,
      ..country_code = .country_code
    ) |>
      dplyr::bind_rows()


    #search term, org type and country name
  } else if(!missing(.search_terms) & !missing(.org_type) & !missing(.country_name)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..search_terms = .search_terms,
      ..org_type = .org_type,
      ..country_name = .country_name
    ) |>
      dplyr::bind_rows()


    #org type only
  } else if(missing(.search_terms) & !missing(.org_type) & missing(.country_code) & missing(.country_name)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..org_type = .org_type
    ) |>
      dplyr::bind_rows()

    #org type and country code
  }  else if(missing(.search_terms) & !missing(.org_type) & !missing(.country_code)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..org_type = .org_type,
      ..country_code = .country_code
    ) |>
      dplyr::bind_rows()

    #org type and coutry name
  } else if(missing(.search_terms) & !missing(.org_type) & !missing(.country_name)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..org_type = .org_type,
      ..country_name = .country_name
    ) |>
      dplyr::bind_rows()

    #country code only
  } else if(missing(.search_terms) & missing(.org_type) & !missing(.country_code)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..country_code = .country_code
    ) |>
      dplyr::bind_rows()


    #country nasme only
  } else if(missing(.search_terms) & missing(.org_type) & !missing(.country_name)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..country_name = .country_name
    ) |>
      dplyr::bind_rows()

    #search term and country code
  } else if(!missing(.search_terms) & missing(.org_type) & !missing(.country_code)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..search_terms = .search_terms,
      ..country_code = .country_code
    ) |>
      dplyr::bind_rows()


  } else if(!missing(.search_terms) & missing(.org_type) & !missing(.country_name)) {

    result_df <- lapply(
      X = pages,
      FUN = get_results_by_page,
      ..search_terms = .search_terms,
      ..country_name = .country_name
    ) |>
      dplyr::bind_rows()


  }


return(result_df)



}
