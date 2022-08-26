;+
; NAME:
;	  minxss_make_netcdf.pro
;
; PURPOSE:
;	  Make MinXSS NetCDF file for specific Level data product stored as IDL save set.
;	  A metadata attributes file must exist.
;
;	INPUTS
;		level [string]: Level name: '0C', '0D', '1', '2', '3', '4'
;
; OPTIONAL INPUTS:
;   fm [integer]:     Flight model number (default is 1)
;   version [string]: The version tag to put in the output filename and internal anonymous structure. Default is '2.0.0'
;
; KEYWORD PARAMETERS:
;		VERBOSE: Set to print processing messages
;		DEBUG:	 Set to trigger stop points for debugging
;
;	OUTPUTS
;		None
;
;	OPTIONAL OUTPUTS:
;	  None
;
;	RESTRICTIONS:
;	  Metadata file corresponding to the input level must exist
;
;	PROCEDURE
;	1.  Setup directory and file names based on Level name provided
;	2.  Read Level file (IDL save set restore)
;	3.	Write NetCDF file
;
;	HISTORY
;	2017		J. Mason, original code
;	2022-08-25	T. Woods, update for L2 and L3 new products and making default Version 4.0.0
;
;-
pro minxss_make_netcdf, level, $
                        fm=fm, version=version, $
                        VERBOSE=VERBOSE, DEBUG=DEBUG

if keyword_set(verbose) then verbose=1 else verbose=0
if keyword_set(debug) then verbose=1

level_name = strtrim(strupcase(level),2)

IF version EQ !NULL THEN version = '4.0.0'

IF fm EQ !NULL THEN fm = 1
if fm lt 1 then fm = 1
if fm gt 3 then fm = 3
IF fm EQ 1 THEN BEGIN
  mission_start_date = '2016-05-16'
ENDIF ELSE IF fm EQ 2 THEN BEGIN
  mission_start_date = '2018-12-03'
ENDIF ELSE IF fm EQ 3 THEN BEGIN
  mission_start_date = '2022-02-14'
ENDIF
fm = strtrim(fm, 2)

;  set to non-zero if want to use the old (pre-2022) L2 and L3 products for MinXSS
use_old_L2L3 = 0

;
;	get root data directory dependent on FM number
;
;  slash for Mac = '/', PC = '\'
slash = path_sep()
dir_data = getenv('minxss_data') + slash + 'fm' + fm + slash
dir_metadata = dir_data + 'metadata' + slash

;
;	1.  Setup directory and file names based on Level name provided
;
SETUP:
case level_name of
	'0C':	begin
			indir = dir_data + 'level0c' + slash
			infile = 'minxss'+fm+'_l0c_all_mission_length_v' + version + '.sav'
			outfile = 'minxss'+fm+'_solarSXR_level0C_' + mission_start_date + '-mission_v' + version + '.ncdf'
			attfile = 'minxss'+fm+'_solarSXR_level0C_metadata.att'
			end
	'0D':	begin
			indir = dir_data + 'level0d' + slash
			infile = 'minxss'+fm+'_l0d_mission_length_v' + version + '.sav'
			outfile = 'minxss'+fm+'_solarSXR_level0D_' + mission_start_date + '-mission_v' + version + '.ncdf'
			attfile = 'minxss'+fm+'_solarSXR_level0D_metadata.att'
			end
	'1': begin
		 indir = dir_data + 'level1' + slash
		 infile = 'minxss'+fm+'_l1_mission_length_v' + version + '.sav'
		 outfile = 'minxss'+fm+'_solarSXR_level1_' + mission_start_date + '-mission_v' + version + '.ncdf'
		 attfile = 'minxss'+fm+'_solarSXR_level1_metadata.att'
		 end
	'2': begin
		 indir = dir_data + 'level2' + slash
		 if (use_old_L2L3 ne 0) then begin
			 infile = 'minxss'+fm+'_l2_1minute_average_mission_length_v' + version + '.sav'
			 outfile = 'minxss'+fm+'_solarSXR_level2_1minute_average_' + mission_start_date + '-mission_v' + version + '.ncdf'
			 attfile = 'minxss'+fm+'_solarSXR_level2_1minute_average_metadata.att'
			 IF one_minute_done NE !NULL THEN BEGIN
			   infile = 'minxss'+fm+'_l2_1hour_average_mission_length_v' + version + '.sav'
			   outfile = 'minxss'+fm+'_solarSXR_level2_1hour_average_' + mission_start_date + '-mission_v' + version + '.ncdf'
			   attfile = 'minxss'+fm+'_solarSXR_level2_1hour_average_metadata.att'
			 ENDIF
		 endif else begin
		 	 ; use 2022 "new" L2 products
		 	 infile = 'minxss'+fm+'_l2new_1minute_average_mission_length_v' + version + '.sav'
			 outfile = 'minxss'+fm+'_solarSXR_level2_1minute_average_' + mission_start_date + '-mission_v' + version + '.ncdf'
			 attfile = 'minxss'+fm+'_solarSXR_level2new_1minute_average_metadata.att'
			 IF one_minute_done NE !NULL THEN BEGIN
			   infile = 'minxss'+fm+'_l2new_1hour_average_mission_length_v' + version + '.sav'
			   outfile = 'minxss'+fm+'_solarSXR_level2_1hour_average_' + mission_start_date + '-mission_v' + version + '.ncdf'
			   attfile = 'minxss'+fm+'_solarSXR_level2new_1hour_average_metadata.att'
			 ENDIF
		 endelse
		 end
	'3': begin
		 if (use_old_L2L3 ne 0) then begin
			indir = dir_data + 'level3' + slash
			infile = 'minxss'+fm+'_l3_1day_average_mission_length_v' + version + '.sav'
			outfile = 'minxss'+fm+'_solarSXR_level3_1day_average_' + mission_start_date + '-mission_v' + version + '.ncdf'
			attfile = 'minxss'+fm+'_solarSXR_level3_1day_average_metadata.att'
		 endif else begin
		 	; use 2022 "new" L3 product
			indir = dir_data + 'level3' + slash
			infile = 'minxss'+fm+'_l3new_1day_average_mission_length_v' + version + '.sav'
			outfile = 'minxss'+fm+'_solarSXR_level3_1day_average_' + mission_start_date + '-mission_v' + version + '.ncdf'
			attfile = 'minxss'+fm+'_solarSXR_level3new_1day_average_metadata.att'
		 endelse
		 end
	else:	begin
			print, 'ERROR with Level Name : ', level_name, ' - Exiting minxss_make_netcdf()'
			return
			end
endcase

;
;	2.  Read Level file (IDL save set restore)
;
if (verbose ne 0) then print, 'Reading IDL save set ', indir + infile, ' ...'
restore, indir + infile

;
;	3.	Write NetCDF file
;
if (verbose ne 0) then begin
	print, 'Writing NetCDF file:  ', indir + outfile, ' ...'
	print, ' with metadata file: ', dir_metadata + attfile
endif
case level_name of
	'0C':	begin
			minxsslevel0c = { hk: hk, sci: sci, log: log }
			write_netcdf, minxsslevel0c, indir + outfile, status, $
				            path=dir_metadata, att_file=attfile, /clobber
			end
	'0D':	begin
			write_netcdf, minxsslevel0d, indir + outfile, status, $
				            path=dir_metadata, att_file=attfile, /clobber
			end
  '1': begin
	   minxsslevel1 = minxss_flatten_structure_for_netcdf(minxsslevel1)
		 write_netcdf, minxsslevel1, indir + outfile, status, $
				           path=dir_metadata, att_file=attfile, /clobber
			end
  '2': begin
		 if (use_old_L2L3 ne 0) then begin
		 	minxsslevel2 = minxss_flatten_structure_for_netcdf(minxsslevel2)
		 	write_netcdf, minxsslevel2, indir + outfile, status, $
			             path=dir_metadata, att_file=attfile, /clobber
		 endif else begin
		 	; 2022 "new" L2 products do not require flattening
		 	write_netcdf, minxsslevel2_x123, indir + outfile, status, $
			             path=dir_metadata, att_file=attfile, /clobber
		 endelse
		 IF one_minute_done EQ !NULL THEN BEGIN
		   one_minute_done = 1
       GOTO, SETUP
		 ENDIF
			end
	'3': begin
			if (use_old_L2L3 ne 0) then begin
	    		minxsslevel3 = minxss_flatten_structure_for_netcdf(minxsslevel3)
				write_netcdf, minxsslevel3, indir + outfile, status, $
				            path=dir_metadata, att_file=attfile, /clobber
			endif else begin
		 		; 2022 "new" L3 products do not require flattening
		 		write_netcdf, minxsslevel3_x123, indir + outfile, status, $
			             path=dir_metadata, att_file=attfile, /clobber
			endelse
			end
	else:	begin
			print, 'ERROR with Level Name : ', level_name, ' - Exiting minxss_make_netcdf()'
			return
			end
endcase

if keyword_set(VERBOSE) then message, /INFO, 'Completed the NetCDF file write.'
if keyword_set(debug) then stop, 'DEBUG: at end of minxss_make_netcdf.pro ...'

end
