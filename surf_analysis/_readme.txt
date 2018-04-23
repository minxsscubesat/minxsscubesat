;
;	_readme.txt
;
;	ReadMe file for processing SURF data for Rocket XRS-X123-SPS instrument
;	March 2018
;	Tom Woods
;

Computer Directory Information  (copy from twoods user's .cshrc file on Mac)
-----------------------------
alias rktcal_idl 'setenv IDL_PATH "+~/Dropbox/minxss_dropbox/code/surf_analysis:+~/Dropbox/minxss_dropbox/code/minxss_library:<IDL_DEFAULT>"'
setenv rktcal_code "~/Dropbox/minxss_dropbox/code/surf_analysis"
setenv rktcal_data "~/Dropbox/minxss_dropbox/data/calibration/rocket_x123_xrs_picosim/hydra_telemetry_files"
setenv rktcal_dir "~/Dropbox/minxss_dropbox/data/calibration/rocket_x123_xrs_picosim/results"
setenv SURF_LOG  "~/Dropbox/minxss_dropbox/data/calibration/rocket_x123_xrs_picosim/surfer_files"

Startup Code for starting IDL for SURF March 2018 calibrations
-------------------------------
$  rktcal_idl			; setup IDL Path before calling IDL
$  idl	or  idlde		; start IDL command line or IDL Development Environment (DE)
IDL> .run files2018.pro    ; define directories and Hydra / SURFER files for each experiment
						   ; Assuming one includes file names in this procedure after each experiment

Main procedure to get HYDRA data and SURFER file data
-------------------------------------------------------
IDL>  plot_rxrs_hydra, channel, filename, surffile,  $
			data=data, surfdata=surfdata, quaddata=quaddata, /debug

;  where  channel = 'A1', 'A2', 'B1', 'B2' for XRS channels
;					'X123', 'X123_Fast' for XRS slow and fast counts
;					'SPS', 'PS1', 'PS2', 'PS3', 'PS4', 'PS5', 'PS6' for PicoSIM-SPS channels
;  filename is HYDRA telemetry file
;  surffile is SURFER log file
;  data, surfdata, and quaddata are return values

This procedure calls read_hydra_rxrs.pro to read the HYDRA telemetry data files into structure arrays.
----------------------------------------------------------------
IDL>  read_hydra_rxrs, filename, hk=hk, sci=sci, log=log, sps=sps, /verbose

;	where  filename is HYDRA telemetry file
;		and hk, sci, log, sps are return values (structure arrays)
;	hk = HK packets of monitors
;	sci = Science packets for X123 and XRS
;	log = message packets
;	sps = Solar Position Sensor (SPS) science packets for PicoSIM and SPS

EXAMPLES
---------
IDL> filename = '/Users/twoods/Dropbox/HYDRA_Rocket/Rundirs/2018_085_10_02_41/tlm_packets_2018_085_11_51_09'
IDL> surffile = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/rocket_x123_xrs_picosim/surfer_files/SURF_032618_211321.txt'

IDL>
IDL> read_hydra_rxrs, filename, hk=hk, sci=sci, log=log, sps=sps, /verbose

READING 394994 bytes from
/Users/twoods/Dropbox/HYDRA_Rocket/Rundirs/2018_085_10_02_41/tlm_packets_2018_085_11_51_09
Number of HK     Packets =          530
Number of LOG    Packets =          222
Number of SCI    Packets =          532
Number of PS-SPS Packets =         1154

IDL>
IDL> plot_rxrs_hydra, 'X123', filename, surffile, data=data

	;  makes a plot of X123_SLOW_COUNT in counts per second over time

Centering Analysis is by rxrs_center.pro
------------------------------------------
rxrs_center.pro will read HYDRA and SURFER data files using the plot_rxrs_hydra.pro and then
make plot of the selected channel's data with SURF axis that moved the most (X, Y, U, or V).
Then user can narrow the time range to select just the scan data of interest.

EXAMPLE
--------
IDL> .run files2018.pro					; define the SURF experiment files including file1 and surf1
IDL> rxrs_center, 'B2', file1, surf1


