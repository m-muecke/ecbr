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
#' @param first_n `numeric(1)` number of observations to retrieve from the
#'   start of the series. If `NULL`, no restriction is applied. Default `NULL`.
#' @param last_n `numeric(1)` number of observations to retrieve from the end
#'  of the series. If `NULL`, no restriction is applied. Default `NULL`.
#' @references <https://data.ecb.europa.eu/help/api/data>
#' @family data
#' @export
#' @examples
#' # fetch US dollar/Euro exchange rate
#' ecb_data("EXR", "D.USD.EUR.SP00.A")
ecb_data <- function(flow,
                     key = NULL,
                     start_period = NULL,
                     end_period = NULL,
                     first_n = NULL,
                     last_n = NULL) {
  stopifnot(is_string(flow))
  stopifnot(is_string_or_null(key))
  stopifnot(is_string_or_null(start_period))
  stopifnot(is_string_or_null(end_period))
  stopifnot(is_count_or_null(first_n))
  stopifnot(is_count_or_null(last_n))

  key <- key %||% "all"
  resource <- paste("data", flow, key, sep = "/")
  body <- ecb(
    resource = resource,
    startPeriod = start_period,
    endPeriod = end_period,
    firstNObservations = first_n,
    lastNObservations = last_n
  )

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
  unit <- body |>
    xml2::xml_find_first("//generic:Value[@id='UNIT']") |>
    xml2::xml_attr("value")

  entries <- body |> xml2::xml_find_all("//generic:Obs[generic:ObsValue]")
  date <- entries |>
    xml2::xml_find_all(".//generic:ObsDimension") |>
    xml2::xml_attr("value")

  date <- switch(freq,
    daily = as.Date(date),
    monthly = as.Date(paste0(date, "-01")),
    annual = as.integer(date),
    date
  )

  value <- entries |>
    xml2::xml_find_all(".//generic:ObsValue") |>
    xml2::xml_attr("value") |>
    as.numeric()

  data <- data.frame(
    date = date,
    title = title,
    description = description,
    unit = unit,
    frequency = freq,
    value = value
  )
  as_tibble(data)
}

#' Returns available data structures
#'
#' @param agency `character(1)` the agency to query. Defaut `NULL`.
#' @param id `character(1)` id to query. Default `NULL`.
#' @returns A `data.frame()` with the available data structures.
#' The columns are:
#'   \item{id}{The id of the data structure}
#'   \item{name}{The name of the data structure}
#' @references <https://data.ecb.europa.eu/help/api/metadata>
#' @family metadata
#' @export
#' @examples
#' ecb_data_structure()
#' # or filter by id
#' ecb_data_structure(id = "ECB_BCS1")
ecb_data_structure <- function(agency = NULL, id = NULL) {
  ecb_metadata("datastructure", "//str:DataStructure", agency, id)
}

#' Returns available code lists
#'
#' @inheritParams ecb_data_structure
#' @inherit ecb_data_structure references
#' @returns A data.frame with the available code lists. The columns are:
#'   \item{id}{The id of the code list}
#'   \item{name}{The name of the code list}
#' @family metadata
#' @export
#' @examples
#' ecb_codelist()
#' # or filter by id
#' ecb_codelist(id = "CLI_EONIA_BANK")
ecb_codelist <- function(agency = NULL, id = NULL) {
  ecb_metadata("codelist", "//str:Codelist", agency, id)
}

ecb_metadata <- function(resource, xpath, agency = NULL, id = NULL) {
  stopifnot(is_string_or_null(agency))
  stopifnot(is_string_or_null(id))
  agency <- if (!is.null(agency)) toupper(agency) else "all"
  id <- if (!is.null(id)) toupper(id) else "all"
  resource <- paste(resource, agency, id, sep = "/")
  body <- ecb(resource)
  entries <- xml2::xml_find_all(body, xpath)
  res <- parse_metadata(entries)
  as_tibble(res)
}

parse_metadata <- function(x, lang = "en") {
  res <- lapply(x, \(node) {
    agency <- xml2::xml_attr(node, "agencyID")
    id <- xml2::xml_attr(node, "id")
    nms <- node |>
      xml2::xml_find_all(sprintf(".//com:Name[@xml:lang='%s']", lang)) |>
      xml2::xml_text()
    data.frame(agency = agency, id = id, name = nms)
  })
  do.call(rbind, res)
}

ecb_error_body <- function(resp) {
  message <- resp_body_string(resp)
  docs <- "See docs at <https://data.ecb.europa.eu/help/api/status-codes>"
  c(message, docs)
}

ecb <- function(resource, ...) {
  request("https://data-api.ecb.europa.eu/service/") |>
    req_user_agent("ecbr (https://m-muecke.github.io/ecbr)") |>
    req_url_path_append(resource) |>
    req_url_query(...) |>
    req_error(body = ecb_error_body) |>
    req_perform() |>
    resp_body_xml()
}
