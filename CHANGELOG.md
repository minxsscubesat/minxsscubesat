# MinXSS Code Base Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added
* Flare catalog generation code (minxss_make_flare_catalog.pro)
* `version` optional input to `minxss_make_level2` and `minxss_make_level3`, to specify which level 1 version of filtering to apply

### Changed
*  `lowcnt` filter logic changed to correctly filter out shifted spectra for level ≥1
*  `peakcnt`-`lowcnt` filter changed to dynamicly filter out spectra with large low count noise for level ≥1
* Small time shit to all packets to move them from end of packet integration (time recorded onboard) to mid-point time of sample
  * Moves housekeeping packet (`hk`) back by 1.5 seconds
  * Moves ADCS packets (`adcs1`, `adcs2`, `adcs3`, `adcs4`) back by 0.1 seconds
  * Moves science packet (`sci`) back by half the wall clock integration time (`x123_real_time / 2`)
* Onboard clock drift is now corrected for (only a few seconds over the mission)

### Deprecated

### Removed

### Fixed
* TODO: `xp.x123_estimated_xp_fc` is always = 2654.2224 but shouldn't be
* TODO: `minxsslevel2.x123.spectrum_total_count_accuracy` and ""`_precision` are identical but shouldn't be


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
