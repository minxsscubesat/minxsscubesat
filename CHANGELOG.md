# MinXSS Code Base Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added
  
### Changed
* With v3.1.0 for DAXSS, we're changing the way we pull level 0 files. It was automatically pulled from Google Drive and storing on Dropbox. Now that will be a manual process. 
  
### Deprecated

### Removed

### Fixed
* TODO: `xp.x123_estimated_xp_fc` is always = 2654.2224 but shouldn't be
* TODO: `minxsslevel2.x123.spectrum_total_count_accuracy` and ""`_precision` are identical but shouldn't be

## [v5.0.0-minxss%2Bv3.0.0-daxss](https://github.com/minxsscubesat/minxsscubesat/releases/tag/v5.0.0-minxss%2Bv3.0.0-daxss)

### Added
* New function to compute flare energy
* Added DAXSS radiation background subtraction algorithm that uses the background signal in the X123 high energy range above 12 keV. This background correction is very close to zero most of the time but can be a few counts per second during major geomagnetic storms near Earth's polar regions.
* Added some geometric calculations (e.g., solar zenith angle/altitude, tangent ray)
* Added handful of convenience functions
* Added handful of new analysis codes
  
### Changed
* Major update to netCDF files. Now only two time formats are included: TAI and Julian date. TAI is the unlimited dimension of the file and is listed simply as "TIME". Metadata has been updated throughout. At Level 1, X123, X123 dark data, XP, and XP dark data are split into separate files (for the netCDFs only; these are still all kept in a single file for the IDL saveset). 
* Updated how histograms of ADCS jitter are presented
* Updated the DAXSS deadtime correction for the X123 to better match the flight solar signal levels (changes for Version 2.1 and Version 2.2).
* For the DAXSS data product archive, the TIME variable was changed to TAI seconds and a new JD_DATE variable is added for the Julian Day.
* Metadata files now have corresponding version numbers
* Some minor directory structure stuff (e.g., aia_code, ospex)

### Deprecated

### Removed

### Fixed


## [v4.0.0-minxss+v2.0.0-daxss](https://github.com/minxsscubesat/minxsscubesat/releases/tag/v4.0.0-minxss%2Bv2.0.0-daxss)

### Added
* Support for IS1/DAXSS (INSPIRESat-1 / Dual-zone Aperture X-ray Solar Spectrometer AKA MinXSS-3) processing and plotting -- note that these data are encoded as flight model 4 (fm=4) initially and then changed to be fm=3.  DAXSS Level OC, OD, and 1 products released in June 2022.
* InspireSat-1 DAXSS has high background signal when in the polar and SAA regions.  A linear fit to the background signal in the 12-20 keV range is used in Level 1 processing to remove the background at all energies before doing the conversion to irradiance units.  The background fit information is stored in the Level 1 product.
* DAXSS Level 1 Version 1.0.0 has text errors in the MetaData, so the MetaData has been updated.  The Level 1 in IDL saveset has correct MetaData descriptions.
* Support for pass prioritization in the pass automator
* Compatability with XSPEC  

### Changed
* `minxss_post_pass_times_plotly.py` now runs for more ground stations (India, Singapore, and Taiwan)
* Massive speed improvements in creating level 1 by using a common block instead of thousands of restores of the same files
* Time averaging algorithm changed for the Level 2 and Level 3 products for DAXSS, MinXSS-1, and MinXSS-2.  MinXSS Version 3.1 had time averaging of just the counts and then Level 1 code used to generate irradiance values.  The new algorithm does time averages of all data points using the Level 1 data product; consequently, it processes the L2/L3 data products very quickly.  The time averages are done based on gridding up UT day into 1-minute, 1-hour, and 24-hour intervals, with the first two being Level 2 products and the 24-hour (daily) average being for the Level 3 product.  Being a major algorithm change, all MinXSS data products are moved up to Version 4.0.0.
* Observations taken through the earth's atmosphere have been cut out of level 1 and above. 

### Deprecated

### Removed

### Fixed
* Units in the response variable
* Incorrect timestamps for levels 2 and 3
* Bug in MinXSS level 1: `time_yd` was calculated incorrectly 

## [v3.1.0](https://github.com/minxsscubesat/minxsscubesat/releases/tag/v3.1.0)

### Added
* MinXSS-2 level 1 data are now available, which (necessarily) includes our calibration!
* Flare catalog generation code (minxss_make_flare_catalog.pro)
* `version` optional input to `minxss_make_level0c`, `minxss_make_level0d`, and `minxss_make_level1` to specify what string will be appended to the output filenames and internal data structure in the corresponding fields
* `cal_version` optional input to `minxss_make_level` to specify which calibration version should be applied
* `version` optional input to `minxss_make_level2` and `minxss_make_level3` to specify which level 1 files to use (level 2 and 3 are just time averages of level 1)
* Improved version of `minxss_fit_2temperature`, including new optional inputs like integration period and energy resolution. Now fits abundance by weighting COR and PHOTO spectra. The old method has been retained, but renamed to `minxss_fit_2temperature_old`

### Changed
*  `lowcnt` filter logic changed to correctly filter out shifted spectra for level ≥1
*  `peakcnt`-`lowcnt` filter changed to dynamicly filter out spectra with large low count noise for level ≥1
* Small time shit to all packets to move them from end of packet integration (time recorded onboard) to mid-point time of sample
  * Moves housekeeping packet (`hk`) back by 1.5 seconds
  * Moves ADCS packets (`adcs1`, `adcs2`, `adcs3`, `adcs4`) back by 0.1 seconds
  * Moves science packet (`sci`) back by half the wall clock integration time (`x123_real_time / 2`)
* Onboard clock drift is now corrected (only a few seconds over the mission)


### Deprecated

### Removed
* `irradiance_low` and `irradiance_high` from level 2 and 3 `x123` structure. Now it's just e.g., `minxsslevel3.x123.irradiance`

### Fixed
* Energy resolution (`x123_spectral_resolution_array`) was calculated slightly wrong before. Recalculated with 0.168 keV at Fe-55 energy: N=13.6. This fix had no impact on the irradiance, however, so is not expected to impact users results.


## [v2.0.0](https://github.com/minxsscubesat/minxsscubesat/releases/tag/v2.0.0)

This changelog only came into existence on 2020-06-04. It's unlikely that all of the major changes in the last few years are captured here because it relies on memory and sifting through the [git commits](https://github.com/minxsscubesat/minxsscubesat/commits/master). Going forward, proper changelogging will be practiced.

### Added
* [MinXSS-1 CubeSat Data User Guide](minxss-1_cubesat_data_user_guide.md)
* Level 2 product: 1-minute and 1-hour time averages of data
* netCDF output: data products are now in both IDL savesets (.sav) and netCDF3 (.ncdf) files
* Plotting routines in [plotting](minxss_library/plotting):
  * pointing jitter
  * commissioning health and safety
  * MinXSS-2 vs CSIM communications conflicts
  * videos and static plots of signal to noise ratio
  * satellite track over Earth
  * history of SXR observations
  * movie of all Level 1 spectra
* Output tables of pass times over Boulder and Fairbanks ground stations that automatically update on our [website](https://lasp.colorado.edu/home/minxss/pass-times/) every day via plotly
* Output leaderboard and map that show where beacons are being collected by ham operators around the world, and updates our [website](https://lasp.colorado.edu/home/minxss/ham/) via plotly
* Support for MinXSS-2 data processing -- but still need calibration/response matrix
* Support for DAXSS (rocket flight and upcoming INSPIRESat-1 smallsat mission)
* Support for flatsat data processing
* Ham operator data: beacon data collected by ham operators around the world is automatically folded in to normal data processing
* Software Defined Radio log data: ASCII of the hex saved to disk directly from the SDR is automatically foldd in to normal data processing (in addition to the "normal" Hydra saved binary; code drops all duplicate data)
* Battery capacity calculation code for ground testing
* [Function to calculate uncertainties on the X123 spectra](minxss_library/processing_standard/minxss_x123_uncertainty_mean_count_rate.pro)
* Testing code for netCDF files
* New method for removing tags from structures (from SolarSoft).. takes 26 different functions but it's orders of magnitude faster than using IDL >8.3's hashes
* Filter for tossing out bad data that would be in Level 1 product otherwise: bin 200 can't be higher than a value of 40 (see [commit](https://github.com/minxsscubesat/minxsscubesat/commit/9f8ad64948e918c788cff6f69e42ee9f25de7c3a))
* Filter for X123 read/write errors that would be in Level 1 product
* Improved filtering out of X123 spectra during times of higher signal noise as related to spacecraft radio or reaction wheels for Level 1 product

### Changed
* All (hopefully) usages of `systime()` to `JPMsystime()` to comply with ISO 8601 time format
* Defaults in code from MinXSS flight model 1 to 2
* Moved some core processing functions from Chris Moore's subdirectory to [processing_standard](minxss_library/processing_standard)
* Removed the "_cm" suffix from several of Chris Moore's codes that are core to standard processing
* A variety of variable names in the data products for clarity and brevity
* Many instances of `print` replaced by `message, /INFO` for processing messages
* `enable_` to `switch_` variable names in Level 1
* `switch_` data type from byte to float type to allow for bad data NaN flag
* `sps_sum` is now in degrees instead of data numbers
* `lowcnt` filter logic changed to correctly filter out shifted spectra for level 1
* `peakcnt`-`lowcnt` filter changed to dynamicly filter out spectra with large low count noise for level 1
* Walked back lowcnt filter logic
* Changed peakcnts check to be above 0.4

### Deprecated
* `PLOT` keyword in [minxss_get_beta()](minxss_library/convenience_functions_minxss/minxss_get_beta.pro)

### Removed
* Numerous redundant copies of code
* Many of the IDL header modification histories since that is now tracked with git
* A lot of commented out code rot
* `spacecraft_in_saa` flag from Level 1 product since these bad data are filtered out already
* `irradiance_low` and `irradiance_high` from Level 1 product
* `spectrum_total_counts`, `spectrum_total_counts_accuracy`, and `spectrum_total_counts_precision` from Level 1 product since they can be calculated by combining the `spectrum_cps_*` with the `integration_time`
* `xp.x123_estimated_xp_fc` from Level 1 product until we find a fix for its calculation (TODO for next release)
* `x123.group_count` from Level 0D because its not needed for Level 1
*  removed SAA exclusion filter for level 1

### Fixed
* Erroneous flight model labeling
* Error that set all XP number of samples to 1
* `x123.spectrum_cps_stddev` and `x123_dark.spectrum_cps_stddev` were always 0 -- fixed
* Numerous minor bugs, for example:
  * Moved timers outside loops as they were intended to go
  * `JPMPrintNumber()` now handles integer rounding when `/NO_DECIMALS` is set, and can handle larger numbers
  * `JPMjd2iso()` handles times with seconds = 60 by setting it to 0 and propagating the increment to minutes
  * Some ADCS telemetry points were read incorrectly because they pointed to the wrong byte addresses in the packet

## [v1.0.0] - 2016-05-16

This changelog only came into existence on 2020-06-04. This retroactive release is only notional.

### Added

* everything needed to process MinXSS-1 data
