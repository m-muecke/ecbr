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
  stopifnot(
    is_string(flow),
    is_string_or_null(key),
    is_string_or_null(start_period),
    is_string_or_null(end_period),
    is_count_or_null(first_n),
    is_count_or_null(last_n)
  )

  key <- key %||% "all"
  resource <- paste("data", flow, key, sep = "/")
  body <- ecb(
    resource = resource,
    startPeriod = start_period,
    endPeriod = end_period,
    firstNObservations = first_n,
    lastNObservations = last_n
  )
  res <- parse_ecb_data(body)
  as_tibble(res)
}

parse_ecb_data <- function(body) {
  series <- body |> xml2::xml_find_all(".//generic:Series")
  res <- lapply(series, \(x) {
    series_key <- x |>
      xml2::xml_find_first(".//generic:SeriesKey") |>
      xml2::xml_children()
    nms <- series_key |>
      xml2::xml_attr("id") |>
      tolower()
    series_key <- series_key |>
      xml2::xml_attr("value") |>
      stats::setNames(nms) |>
      as.list()
    names(series_key) <- nms

    attrs <- x |>
      xml2::xml_find_first(".//generic:Attributes") |>
      xml2::xml_children()
    nms <- attrs |>
      xml2::xml_attr("id") |>
      tolower()
    nms <- replace(nms, nms == "title_compl", "description")
    attrs <- attrs |>
      xml2::xml_attr("value") |>
      stats::setNames(nms) |>
      as.list()

    data <- c(series_key, attrs)
    data$key <- paste(series_key, collapse = ".")

    data$freq <- switch(data$freq,
      A = "annual",
      S = "semi-annual",
      Q = "quarterly",
      M = "monthly",
      W = "weekly",
      D = "daily"
    )

    entries <- x |> xml2::xml_find_all(".//generic:Obs[generic:ObsValue]")
    date <- x |>
      xml2::xml_find_all(".//generic:ObsDimension") |>
      xml2::xml_attr("value")

    data$date <- switch(data$freq,
      daily = as.Date(date),
      monthly = as.Date(paste0(date, "-01")),
      annual = as.integer(date),
      date
    )

    data$value <- entries |>
      xml2::xml_find_all(".//generic:ObsValue") |>
      xml2::xml_attr("value") |>
      as.numeric()

    as.data.frame(data)
  })
  nms <- lapply(res, names)
  nms <- Reduce(intersect, nms)
  nms <- union(c("date", "key", "value", "title", "description"), nms)
  res <- lapply(res, \(x) x[nms])
  res <- do.call(rbind, res)
  res
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
  # WARNING: currenty only returning codelist id but not not the code id
  #  <str:Codelist urn="urn:sdmx:org.sdmx.infomodel.codelist.Codelist=ECB:CL_EXR_TYPE(1.0)" isExternalReference="false" agencyID="ECB" id="CL_EXR_TYPE" isFinal="false" version="1.0">
  #  <com:Name xml:lang="en">Exchange rate type code list</com:Name>
  #  <str:Code urn="urn:sdmx:org.sdmx.infomodel.codelist.Code=ECB:CL_EXR_TYPE(1.0).BRC0" id="BRC0">
  #    <com:Name xml:lang="en">Real bilateral exchange rate, CPI deflated</com:Name>
  #  </str:Code>
}

# Note: dataflow for fetching flow id

ecb_metadata2 <- function(resource, agency = NULL, id = NULL) {
  # resource <- match.arg(
  #   resource, c("datastructure", "codelist", "dataflow", "categorisation")
  # )
  stopifnot(
    is_string_or_null(agency),
    is_string_or_null(id)
  )

  xpath <- switch(resource,
    agencyscheme = "//str:AgencyScheme",
    categorisation = "//str:Categorisation",
    categoryscheme = "//str:CategoryScheme",
    codelist = "//str:Codelist",
    conceptscheme = "//str:ConceptScheme",
    contentconstraint = "//str:ContentConstraint",
    dataflow = "//str:Dataflow",
    datastructure = "//str:DataStructure",
    hierarchicalcodelist = "//str:HierarchicalCodelist",
    organisationscheme = "//str:AgencyScheme",
    structureset = "//str:StructureSet"
    # metadatastructure = "//str:MetadataStructure"
    # metadataflow = "//str:MetadataFlow"
    # dataproviderscheme = "//str:DataProviderScheme"
    # dataconsumerscheme = "//str:DataConsumerScheme"
    # organisationunitscheme = "//str:OrganisationUnitScheme"
    # reportingtaxonomy = "//str:ReportingTaxonomy"
  )

  agency <- if (!is.null(agency)) toupper(agency) else "all"
  id <- id %||% "all"
  resource <- paste(resource, agency, id, sep = "/")
  body <- ecb(resource)
  body |> xml2::write_xml("tmp.xml")
  entries <- xml2::xml_find_all(body, xpath)
  res <- parse_metadata(entries)
  as_tibble(res)
}

ecb_metadata <- function(resource, xpath, agency = NULL, id = NULL) {
  stopifnot(
    is_string_or_null(agency),
    is_string_or_null(id)
  )
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
