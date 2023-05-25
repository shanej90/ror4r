#s3 classes----------------------------------------------

#test that you get a dataframe, assuming no errors
testthat::expect_s3_class(
  get_org_list(.page_numbers = 1),
  "data.frame"
)

#error handling------------------------------------------------------

#test that incorrect org type gives an error
testthat::test_that(
  "wring org_type gives and error",
  expect_error(
    get_org_list(.org_type = "blah"),
    "`.org_type` must be (if used) one of: 'Education', 'Healthcare', 'Company', 'Archive', 'Nonprofit', 'Government', 'Facility', or 'Other'.",
    fixed = T
  )
)

#>1 value for a single parameter
testthat::test_that(
  "that you can only enter one country code",
  expect_error(
    get_org_list(.country_code = c("GB", "US")),
    "You can only enter a single filter value for each parameter.",
    fixed = T
  )
)

#you can only enter a country code or name, not both
testthat::test_that(
  "that you can only enter one country code",
  expect_error(
    get_org_list(.country_code = "FR", .country_name = "France"),
    "You can only filter one of `.country_code` or `.country_name`.",
    fixed = T
  )
)

#that if using affiliation, you can't enter other filters/terms, except page numbers
testthat::test_that(
  "that you can only enter one country code",
  expect_error(
    get_org_list(.affiliation = "University of Exeter", .org_type = "Education"),
    "If using `.affiliation` you can not use `.search_terms` or any filters.",
    fixed = T
  )
)
