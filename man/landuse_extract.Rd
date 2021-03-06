% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/landuse.R
\name{landuse_extract}
\alias{landuse_extract}
\title{Extract landuse for a given catchment polygon}
\usage{
landuse_extract(catchment_sf, ...)
}
\arguments{
\item{catchment_sf}{sf polyogn to extract landuse data for}

\item{...}{additional arguments passed to raster::extract}
}
\value{
data.frame
}
\description{
Extract landuse for a given catchment polygon
}
