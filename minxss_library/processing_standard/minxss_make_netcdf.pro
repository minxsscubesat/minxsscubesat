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
;   version [integer]: Option to specify MinXSS data version number (default is 2)
;   
; KEYWORD PARAMETERS:
;		FM:			  Flight model number (default is 1)
;		VERBOSE:	Set to print processing messages
;		DEBUG:		Set to trigger stop points for debugging
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
;-
pro minxss_make_netcdf, level, $
                        version=version, $
                        FM=FM, VERBOSE=VERBOSE, DEBUG=DEBUG

if n_params() lt 1 then begin
	print, 'USAGE: minxss_make_netcdf, level [, /fm, /verbose, /debug]'
	return
endif

if keyword_set(verbose) then verbose=1 else verbose=0
if keyword_set(debug) then verbose=1

level_name = strtrim(strupcase(level),2)

if keyword_set(fm) then fm_str = strtrim(fm,2) else fm_str='1'
if (fm_str ne '1') and (fm_str ne '2') then begin
	print, 'ERROR with FM number : ' + fm_str + ' - Exiting minxss_make_netcdf()'
	return
endif

;
;	get root data directory dependent on FM number
;
;  slash for Mac = '/', PC = '\'
slash = path_sep()
dir_data = getenv('minxss_data') + slash + 'fm' + fm_str + slash
dir_metadata = dir_data + 'metadata' + slash

;
;	define Version number
;
if keyword_set(version) then begin
  ver_str = string(long(version),format='(I03)')
endif else begin
  ver_str = '003dev'
endelse

;
;	1.  Setup directory and file names based on Level name provided
;
case level_name of
	'0C':	begin
			indir = dir_data + 'level0c' + slash
			infile = 'minxss'+fm_str+'_l0c_all_mission_length.sav'
			outfile = 'minxss'+fm_str+'_solarSXR_level0C_2016-05-16-mission_V'+ver_str+'.ncdf'
			attfile = 'minxss'+fm_str+'_solarSXR_level0C_metadata.att'
			end
	'0D':	begin
			indir = dir_data + 'level0d' + slash
			infile = 'minxss'+fm_str+'_l0d_mission_length.sav'
			outfile = 'minxss'+fm_str+'_solarSXR_level0D_2016-05-16-mission_V'+ver_str+'.ncdf'
			attfile = 'minxss'+fm_str+'_solarSXR_level0D_metadata.att'
			end
	'1': begin
		 indir = dir_data + 'level1' + slash
		 infile = 'minxss'+fm_str+'_l1_mission_length.sav'
		 outfile = 'minxss'+fm_str+'_solarSXR_level1_2016-05-16-mission_V'+ver_str+'.ncdf'
		 attfile = 'minxss'+fm_str+'_solarSXR_level1_metadata.att'
		 end
	'2': begin
		 indir = dir_data + 'level2' + slash
		 infile = 'minxss'+fm_str+'_l2_mission_length.sav'
		 outfile = 'minxss'+fm_str+'_solarSXR_level2_2016-05-16-mission_V'+ver_str+'.ncdf'
		 attfile = 'minxss'+fm_str+'_solarSXR_level2_metadata.att'
		 end
	'3': begin
			indir = dir_data + 'level3' + slash
			infile = 'minxss'+fm_str+'_l3_mission_length.sav'
			outfile = 'minxss'+fm_str+'_solarSXR_level3_2016-05-16-mission_V'+ver_str+'.ncdf'
			attfile = 'minxss'+fm_str+'_solarSXR_level3_metadata.att'
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
		 minxsslevel2 = minxss_flatten_structure_for_netcdf(minxsslevel2)
		 write_netcdf, minxsslevel2, indir + outfile, status, $
			             path=dir_metadata, att_file=attfile, /clobber
			end
	'3': begin
	    minxsslevel3 = minxss_flatten_structure_for_netcdf(minxsslevel3)
			write_netcdf, minxsslevel3, indir + outfile, status, $
				            path=dir_metadata, att_file=attfile, /clobber
			end
	else:	begin
			print, 'ERROR with Level Name : ', level_name, ' - Exiting minxss_make_netcdf()'
			return
			end
endcase

if keyword_set(VERBOSE) then message, /INFO, 'Completed the NetCDF file write.'
if keyword_set(debug) then stop, 'DEBUG: at end of minxss_make_netcdf.pro ...'

end
