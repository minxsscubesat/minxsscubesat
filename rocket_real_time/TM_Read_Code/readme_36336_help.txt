Instructions for Extracting and Quicklook for NASA 36.336
----------------------------------------------------------
Tom Woods


TBD *****
36.336 Launch Date = June 18, 2018 (DOY 169)  Time = 19:00:00 UT (68400.0 sec)
Apogee of 285 km at T+274sec  (Preliminary Values)

Earth-Sun Distance = 0.9954 AU
F10.7 = 134.5   <F10.7> = 129.7
Ap = 1.0
TBD *****

IDL SETUP
---------
The alias rocket_idl, rocket_data need to be defined before running IDL.
Example definitions that can live in your .cshrc startup file.

alias rocket_idl 'setenv IDL_PATH "+/Users/twoods/Dropbox/minxss_dropbox/code/rocket_real_time:+/Users/twoods/Dropbox/minxss_dropbox/code/minxss_library:<IDL_DEFAULT>"'

setenv rocket_data /Users/twoods/Dropbox/minxss_dropbox/rocket_eve_docs/36.336/TM_Data


***** STOPPED EDITING HERE *****

FLIGHT RESULTS
--------------
ESP Quad Diode results for flight near apogee:
    ESP X offset = -2.17 arc-mintues (wavelength shift axis for ESP) (SPARCS +Yaw)
    ESP Y offset = -0.75 arc-minutes  (SPARCS +Pitch)

SAM Center results:  (with ESP installed in SAM)
	SAM Sun Center X = 1626 pixel +/- 10 pixels
	               Y = 286 pixel  +/- 10 pixels
	SAM Perfect Center X = 1610, Y = 277
	SAM Angle (arc-min) = (pixel_offset * 15 microns / (32E4 microns))  * 180. * 60. / !PI
	SAM Offset X = +2.64 arc-min  +/- 1 arc-min
	           Y = +1.42 arc-min  +/- 1 arc-min

There were no SPARCS manuevers during this flight.
To keep atmospheric absorption to less than 10%, the time period from T+170 to T+380 is best for analysis.

MEGS Dark Measurements:   T+68 and T+488

There are two types of raw binary data files:
(1)  DVD (CD) files created as post-processing by WSMR  (complete data set)
(2)  DataView files created real-time (RT) (incomplete - not all data captured this way)

Instructions are different based on which file you are trying to process to extract out data.

Tom has processed these files (using instructions below) and extracted the data and saved into
*.dat binary files and also as *.sav IDL savesets for each instrument.
Others do not need to reprocess the Binary files.

NOTE:
IDL save set (*.sav) files are better to use than the binary data files due to new binary file
issues between different type computers in how they consider integers as either 32-bit or 64-bit integers.

Projects phase_development server: Rocket_Woods/Flights/36.290/Flight_Data/
and
EVESCI2 Directory:  /eve_analysis/testing/analysis/Rocket_flight_analysis/rocket_36290/

Subdirectories include:
	binary
	code
	pictures
	saveset
	video

As end user, see the following QUICKLOOK instructions for the data (*.dat) files.

**********   WARNING: while most code has been updated for 36.290 processing, there still might
be some code that works with the old rocket flights but not yet updated for 36.290 (2013 flight).

-----------------------------------------------------------
QUICKLOOK Instructions - How to plot / read the rocket data
-----------------------------------------------------------

MEGS CCD Images - movie & read single image
-------------------------------------------
IDL>  movie_raw_megs, MEGS_FILE_NAME, 'A' or 'B', info=info

Note that MOVIE will not work if using IDL version 6.3 on Mac (IDL bug - get IDL v7.0).

This procedure is written to be able to read single image at a time:
IDL>  aimage = 8  ; index into images in the file
IDL>  movie_raw_megs, MEGS_FILE_NAME, 'A', image=aimage
;  on return, "aimage" is the 8th image

MEGS_FILE_NAME = 36290_Flight_TM2_TTT_TTT_raw_Xmegs.sav

where        X = "a" or "b"
and
       TTT-TTT = -200_100   for dark and flat field data - 29 images
               = Ê100_460   for primary solar data (near apogee) - 34 images
               = Ê460-585   for more dark and flat field data at end of flight - 12 images


ESP Data - plot & read data
---------------------------
IDL>  plot_esp, '36290_Flight_TM1_0_585_esp.SAV', esp_data

MEGS-P Data - plot & read data
---------------------------
IDL>  plot_megsp, '36290_Flight_TM1_0_585_pmegs.SAV', pmegs_data

MEGS-P packet also has the CCD analog monitors.  For plotting those in addition to the
photometer data, use the /all option.

IDL>  plot_megsp, '36290_Flight_TM1_0_585_pmegs.SAV', pmegs_data, /all


XPS Data - plot & read data
---------------------------
IDL>  plot_xps, '36286-tm1-Flt_-200_585_xps.sav', xps_data


GOES XRS Data - plot & read data
---------------------------
IDL>  plot_flt_rxrs, '36290_Flight_TM1_0_585_goes_xrs.dat', data=data


Analog Monitors Data - plot & read data
----------------------------------------
IDL>  plot_analogs, '36290_Flight_TM1_0_585_analogs.SAV', analog_data



---------------------------------------------------
1.  Instructions for Extracting Data from DVD (CD) Binary Files (complete data set)
---------------------------------------------------

DVD TM File Names
-----------------
*.bin are TM files

36290_Flight_TM1.log  is TM#1 file (5 Mbps) for Analog monitors, ESP, XPS, MEGS-P, GOES-XRS

36290_Flight_TM2.log is TM#2 file (10 Mbps) for CCD data (MEGS-A & B)

TM#2 (10 Mbps)  CCD Data
-------------------------
IDL>  file2=''   or  file2 = dialog_pickfile(filter='36*.*')  ; /Volumes/... for DVD
IDL>  read_tm2_all_cd, file2, /amegs, /bmegs

Enter time range (relative to T+0 in sec)  -  e.g.  0, 585

Quicklook:  Play the movies after images are extracted
----------
IDL>  movie_raw_megs, MEGS_FILE_NAME, 'A'

Note that MOVIE will not work if using IDL version 6.3 on Mac (IDL bug - get IDL v7.0).

Read Specific Image from Movie:
IDL>  aimage = 8  ; index into images in the file
IDL>  movie_raw_megs, MEGS_FILE_NAME, 'A', image=aimage
;  on return, "aimage" is the 8th image


TM#1 (5 Mbps)  Analog & Serial Data
-----------------------------------
IDL>  file1=''   or  file1 = dialog_pickfile(filter='36*.*')  ; /Volumes/... for DVD
IDL>  read_tm1_cd, file1, /analog, /esp, /pmegs, /xps, /xrs, /x123, /cmd

Enter time range (relative to T+0 in sec)  -  e.g.  0, 585

Quicklook:  Plot the data after they are extracted
---------
IDL>  plot_analogs, ANALOG_FILE_NAME

IDL>  plot_esp, ESP_FILE_NAME

IDL>  plot_megsp, MEGSP_FILE_NAME

IDL>  plot_xps, XPS_FILE_NAME

IDL>  plot_goes, GOES_FILE_NAME

---------------------------------------------------
2.  Instructions for  Extracting Data from DataView (RT) Files (incomplete data set)
---------------------------------------------------

DataView TM File Names
-----------------
Raw_Data_TM1_YY_MM_DD_HH-MM* are files for TM#1 (analog monitors, ESP, XPS, MEGS-P)

Raw_Data_TM2_YY_MM_DD_HH-MM* are files for TM#2 (CCD data for MEGS-A & B)


TM#2 (10 Mbps)  CCD Data
-------------------------
IDL>  file2=''   or  file2 = dialog_pickfile(filter='Raw_Data_TM2*')
IDL>  read_tm2_rt, file2, /amegs, /bmegs

Enter time range (relative to T+0 in sec)  -  e.g.  0, 450

Quicklook:  Play the movies after images are extracted
----------
IDL>  movie_megs, MEGS_FILE_NAME, 'A', info=ainfo

Note that MOVIE will not work if using IDL version 6.3 on Mac (IDL bug - get IDL v7.0).

Read Specific Image from Movie:
IDL>  aimage = 8  ; index into images in the file
IDL>  movie_megs, MEGS_FILE_NAME, 'A', image=aimage
;  on return, "aimage" is the 8th image


TM#1 (5 Mbps)  Analog & Serial Data
-----------------------------------
IDL>  file1=''   or  file1 = dialog_pickfile(filter='Raw_Data_TM1*')
IDL>  read_tm1_rt, file1, /analog, /esp, /pmegs, /xps

Enter time range (relative to T+0 in sec)  -  e.g.  0, 450

Quicklook:  Plot the data after they are extracted
---------
IDL>  plot_analogs, ANALOG_FILE_NAME

IDL>  plot_esp, ESP_FILE_NAME

IDL>  plot_megsp, MEGSP_FILE_NAME

IDL>  plot_xps, XPS_FILE_NAME



