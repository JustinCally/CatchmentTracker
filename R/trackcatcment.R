#' Track catchments upstream
#'
#' @param point sf point of location to begin at
#'
#' @return sf/data.frame
#' @export
track_catchments <- function(point) {

  base_option <- getOption("vicmap.base_url")
  options(vicmap.base_url = "http://geofabric.bom.gov.au/simplefeatures/ahgf_shcatch/wfs")
  # options(vicmap.max_geom_pred_size = 3000)

  catch_upstream <- list()
  i <- 0
  ret_row <- TRUE
  while(ret_row) {
    i <- i + 1

    if(i == 1) {
      catch_upstream[[i]] <- VicmapR::vicmap_query("ahgf_shcatch:AHGFCatchment") %>%
        VicmapR::filter(VicmapR::INTERSECTS(point)) %>%
        VicmapR::collect() %>%
        dplyr::mutate(nth_upstream = i)

      hydroid_val <- catch_upstream[[i]]$hydroid %>% unique()
    } else {

      hits <- VicmapR::vicmap_query("ahgf_shcatch:AHGFCatchment") %>%
        VicmapR::filter(nextdownid %in% hydroid_val) %>%
        VicmapR::feature_hits()

      if(hits == 0 | is.na(hits) | is.null(hits)) {
        ret_row <- FALSE
      } else {
        catch_upstream[[i]] <- VicmapR::vicmap_query("ahgf_shcatch:AHGFCatchment") %>%
          VicmapR::filter(nextdownid %in% hydroid_val) %>%
          VicmapR::collect() %>%
          dplyr::mutate(nth_upstream = i)

        hydroid_val <- catch_upstream[[i]]$hydroid %>% unique()
      }

    }
  }

  options(vicmap.base_url = base_option)

  # bind rows
  catchments_joined <- dplyr::bind_rows(catch_upstream)
  return(catchments_joined)
}
