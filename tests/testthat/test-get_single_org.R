#check that you get a list
testthat::expect_type(
  get_single_org(id = "03yghzc09"),
  "list"
)
