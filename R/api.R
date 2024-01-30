#' Returns data for a given flow and key
#'
#' @param flow `character(1)` flow to query.
#' @param key `character(1)` key to query.
#' @param start_period `character(1)` start date of the data. Supported formats:
#'   - YYYY for annual data (e.g., "2019")
#'   - YYYY-S\[1-2\] for semi-annual data (e.g., "2019-S1")
#'   - YYYY-Q\[1-4\] for quarterly data (e.g., "2019-Q1")
#'   - YYYY-MM for monthly data (e.g., "2019-01")
#'   - YYYY-W\[01-53\] for weekly data (e.g., "2019-W01")
#'   - YYYY-MM-DD for daily and business data (e.g., "2019-01-01")
#'   If `NULL`, no start date restriction is applied (data retrieved from the
#'   earliest available date). Default `NULL`.
#' @param end_period `character(1)` end date of the data, in the same format as
#'   start_period. If `NULL`, no end date restriction is applied (data
#'   retrieved up to the most recent available date). Default `NULL`.
#' @references <https://data.ecb.europa.eu/help/api/data>
#' @family data
#' @export
#' @examples
#' # fetch US dollar/Euro exchange rate
#' ecb_data("EXR", "D.USD.EUR.SP00.A")
ecb_data <- function(flow,
                     key = NULL,
                     start_period = NULL,
                     end_period = NULL) {
  stopifnot(is_string(flow))
  stopifnot(is_string_or_null(key))
  stopifnot(is_string_or_null(start_period))
  stopifnot(is_string_or_null(end_period))

  key <- key %||% "all"
  resource <- paste("data", flow, key, sep = "/")
  body <- ecb(resource, startPeriod = start_period, endPeriod = end_period)

  freq <- body |>
    xml2::xml_find_first("//generic:Value[@id='FREQ']") |>
    xml2::xml_attr("value")
  freq <- switch(freq,
    A = "annual",
    S = "semi-annual",
    Q = "quarterly",
    M = "monthly",
    W = "weekly",
    D = "daily"
  )

  title <- body |>
    xml2::xml_find_first("//generic:Value[@id='TITLE']") |>
    xml2::xml_attr("value")
  description <- body |>
    xml2::xml_find_first("//generic:Value[@id='TITLE_COMPL']") |>
    xml2::xml_attr("value")

  entries <- body |> xml2::xml_find_all("//generic:Obs[generic:ObsValue]")
  date <- entries |>
    xml2::xml_find_all(".//generic:ObsDimension") |>
    xml2::xml_attr("value")

  # TODO: make monthly date as well
  if (freq == "daily") {
    date <- as.Date(date, format = "%Y-%m-%d")
  } else if (freq == "annual") {
    date <- as.integer(date)
  }

  value <- entries |>
    xml2::xml_find_all(".//generic:ObsValue") |>
    xml2::xml_attr("value") |>
    as.numeric()

  data <- data.frame(
    date = date,
    title = title,
    description = description,
    freq = freq,
    value = value
  )
  as_tibble(data)
}

ecb_data_structure <- function(agency = NULL, id = NULL) {
  # ecb_data_structure("ECB", "ECB_EXR1")
  ecb_metadata("datastructure", id)
}

ecb_metadata <- function(resource, agency = agency, id = NULL) {
  stopifnot(is_string_or_null(agency))
  stopifnot(is_string_or_null(id))
  # TODO: I believe that when id has a value, agency also needs to have a value
  if (!is.null(id)) {
    resource <- paste(resource, toupper(agency), toupper(id), sep = "/")
  }
  ecb(resource)
}

# TODO: code from bundesbank for reference
parse_metadata <- function(x, lang) {
  res <- lapply(x, \(node) {
    id <- xml2::xml_attr(node, "id")
    nms <- node |>
      xml2::xml_find_all(sprintf(".//common:Name[@xml:lang='%s']", lang)) |>
      xml2::xml_text()
    data.frame(id = id, name = nms)
  })
  res <- do.call(rbind, res)
  res
}

ecb <- function(resource, ...) {
  request("https://data-api.ecb.europa.eu/service/") |>
    req_user_agent("ecbr (https://m-muecke.github.io/ecbr)") |>
    # req_headers(`Accept-Language` = "en") |>
    req_url_path_append(resource) |>
    req_url_query(...) |>
    # req_error(body = bb_error_body) |>
    req_perform() |>
    resp_body_xml()
}
