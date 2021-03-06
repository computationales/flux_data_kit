
#' Generate LSM data
#'
#' Convert FLUXNET data to land surface model compatible netcdf files, using
#' the FluxnetLSM package and PLUMBER2 based workflows.
#'
#' @param df dataframe with sites to process
#' @param out_path output directory
#' @param format the format of the output (fluxnet = FLUXNET formatting)
#' @param save_tmp_files retain temporary files (TRUE or FALSE)
#'
#' @return
#' @export

fdk_process_lsm <- function(
    df,
    out_path,
    format = "fluxnet",
    save_tmp_files = TRUE,
    overwrite = TRUE
    ) {

  # check if files are already processed
  if(!overwrite){
    if(any(grepl(df$sitename, list.files(out_path, "*.nc")))) {
      message(paste0(df$sitename, " files exist, skipping"))
      return(invisible())
    }
  }

  # create full data path
  df$data_path <- file.path(df$data_path, df$product)

  # process sites row by row
  apply(df, 1, function(x){

      message(sprintf("-- processing site: %s", x['sitename']))

      # Outputs will be saved to this directory
      tmp_path <- file.path(tempdir(), "fluxnetlsm", x['sitename'])

      if ( x['product'] != "fluxnet2015"){
        infile <- FluxnetLSM::get_fluxnet_files(
          x['data_path'],
          x['sitename'],
          resolution = "HH",
          datasetversion = "[A-Z]{4}-[0-9]{1}"
        )

        # Retrieve dataset version
        datasetversion <- FluxnetLSM::get_fluxnet_version_no(
          infile
        )

        # Retrieve ERAinterim file
        era_file <- FluxnetLSM::get_fluxnet_erai_files(
          x['data_path'],
          x['sitename'],
          resolution = "HH",
          datasetversion = "[A-Z]{4}-[0-9]{1}"
        )

      } else {
        infile <- FluxnetLSM::get_fluxnet_files(
          x['data_path'],
          x['sitename'],
          resolution = "HH"
        )

        # Retrieve dataset version
        datasetversion <- FluxnetLSM::get_fluxnet_version_no(
          infile
        )

        # Retrieve ERAinterim file
        era_file <- FluxnetLSM::get_fluxnet_erai_files(
          x['data_path'],
          x['sitename'],
          resolution = "HH"
        )
      }

      #---- Settings ----

      # Thresholds for missing and gap-filled time steps
      missing_met <- 100   #max. percent missing (must be set)
      missing_flux <- 100
      gapfill_met_tier1 <- 100  #max. gapfilled percentage
      gapfill_met_tier2 <- 100
      gapfill_flux <- 100
      min_yrs <- 1   #min. number of consecutive years

      #---- Run analysis ----

      status <- try(
        suppressWarnings(
          suppressMessages(
            convert_fluxnet_to_netcdf(
              infile = infile,
              site_code = x['sitename'],
              out_path = tmp_path,
              met_gapfill = "ERAinterim",
              flux_gapfill = "statistical",
              era_file = era_file,
              missing_met = missing_met,
              missing_flux = missing_flux,
              gapfill_met_tier1 = gapfill_met_tier1,
              gapfill_met_tier2 = gapfill_met_tier2,
              gapfill_flux=gapfill_flux, min_yrs=min_yrs,
              check_range_action = "warn",
              include_all_eval=TRUE
            )
          )
        )
      )

      if(inherits(status, "try-error")){
        warning("conversion failed --- skipping")
        return(invisible())
      }

      #----- Corrections ----

      message("applying ERA corrections")

      era_file <- list.files(
        tmp_path,
        utils::glob2rx("*Met.nc"),
        full.names = TRUE,
        recursive = TRUE
      )

      # meteorological corrections
      # written to ncdf file
      fdk_correct_era(
        infile_met = era_file,
        new_qc = 101
        )

      message("applying FLUX corrections")

      flux_file <- list.files(
        tmp_path,
        utils::glob2rx("*Flux.nc"),
        full.names = TRUE,
        recursive = TRUE
      )

      # correct energy balance
      fdk_flux_corrections(
        infile = flux_file
      )

      #----- Downloading and adding MODIS data ----

      if(FALSE) {

        modis_data <- fdk_download_modis(
          df,
          path
        )

        # Define variable:
        laivar <- ncvar_def(
          'LAI_MODIS',
          '-',
          list(site_nc[[s]]$dim[[1]], site_nc[[s]]$dim[[2]], site_nc[[s]]$dim[[3]]),
          missval = -9999,
          longname ='MODIS 8-daily LAI'
        )

        # Add variable and then variable data:
        site_nc[[s]] <- ncvar_add(
          site_nc[[s]],
          laivar
        )

        ncvar_put(
          site_nc[[s]],
          'LAI_MODIS',
          modis_tseries
        )

        #Close file handle
        nc_close(site_nc[[s]])
      }


      #----- Convert to FLUXNET formatting ----

      if(format == "fluxnet") {

        message("converting to fluxnet")

        message("saving data in your output directory")
      }
    })

  #---- cleanup of files ----

  # copy "raw" netcdf files to output path
  # if requested (format != fluxnet)
  if(format != "fluxnet") {
    nc_files <- list.files(
      path = file.path(tempdir(), "fluxnetlsm"),
      pattern = "*.nc",
      recursive = TRUE,
      full.names = TRUE
    )

    file.copy(
      from = nc_files,
      to = out_path,
      overwrite = TRUE
    )
  }

  # delete tmp files if requested
  if (!save_tmp_files) {
    message("cleanup all temporary files...")
    unlink(file.path(tempdir(), "fluxnetlsm"), recursive = T)
  }

}

