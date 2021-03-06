% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fdk_collect_drivers.R
\name{fdk_collect_drivers}
\alias{fdk_collect_drivers}
\title{Collect all drivers}
\usage{
fdk_collect_drivers(site_info, params_siml, meteo, fapar, co2, params_soil)
}
\arguments{
\item{site_info}{A data frame containing site meta info (rows for sites).
Required columns are: \code{"sitename", "date_start",
"date_end", "lon", "lat", "elv"}.}

\item{params_siml}{A nested data frame with rows for each site containing
simulation parameters by site.}

\item{meteo}{A nested data frame with rows for each site and meteo
forcing data time series nested inside a column named \code{"data"}}

\item{fapar}{A nested data frame with rows for each site and fAPAR
forcing data time series nested inside a column named \code{"data"}}

\item{co2}{A nested data frame with rows for each site and CO2
forcing data time series nested inside a column named \code{"data"}}

\item{params_soil}{Soil texture data descriptor}
}
\value{
a rsofun input data frame
}
\description{
Collect all drivers for site-level simulations
into a nested data frame with one row for each site
}
