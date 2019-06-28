;
;	minxss_make_netcdf.pro
;
;	Make MinXSS NetCDF file for specific Level data product stored as IDL save set.
;	A metadata attributes file must exist.
;
;	INPUTS
;		level		Level name: '0C', '0D', '1', '2', '3', '4'
;		/fm			Flight model number (default is 1)
;		/version	Option to specify version number (default is 2)
;		/verbose	Option to print messages
;		/debug		Option to debug this code
;
;	OUTPUTS
;		NONE
;
;	PROCEDURE
;	1.  Setup directory and file names based on Level name provided
;	2.  Read Level file (IDL save set restore)
;	3.	Write NetCDF file
;
pro minxss_make_netcdf, level, fm=fm, version=version, verbose=verbose, debug=debug

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
if !version.os_family eq 'Windows' then begin
    slash = '\'
endif else begin
    slash = '/'
endelse
dir_data = getenv('minxss_data') + slash + 'fm' + fm_str + slash
dir_metadata = dir_data + 'metadata' + slash

;
;	define Version number
;
if keyword_set(version) then begin
  ver_str = string(long(version),format='(I03)')
endif else begin
  ver_str = '002'
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
	'1':	begin
			indir = dir_data + 'level1' + slash
			infile = 'minxss'+fm_str+'_l1_mission_length.sav'
			outfile = 'minxss'+fm_str+'_solarSXR_level1_2016-05-16-mission_V'+ver_str+'.ncdf'
			attfile = 'minxss'+fm_str+'_solarSXR_level1_metadata.att'
			end
	'3':	begin
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
	'1':	begin   
	   ; Flatten the level 1 structure so that read_netcdf will work
	   x123_time = minxsslevel1.x123.time
	   x123 = rem_tag(minxsslevel1.x123, 'time')
	   
	   x123_dark_time = minxsslevel1.x123_dark.time
	   x123_dark = rem_tag(minxsslevel1.x123_dark, 'time')
	   
	   x123_meta = minxsslevel1.x123_meta
	   
	   xp_time = minxsslevel1.xp.time
	   xp = rem_tag(minxsslevel1.xp, 'time')
	   
	   xp_dark_time = minxsslevel1.xp_dark.time
	   xp_dark = rem_tag(minxsslevel1.xp_dark, 'time')
	   
	   xp_meta = minxsslevel1.xp_meta
	   
	   minxsslevel1 = create_struct('x123', x123, 'x123_time', x123_time, $
	                                'x123_dark', x123_dark, 'x123_dark_time', x123_dark_time, $
	                                'x123_meta', x123_meta, $
	                                'xp', xp, 'xp_time', xp_time, $
	                                'xp_dark', xp_dark, 'xp_dark_time', xp_dark_time, $
	                                'xp_meta', xp_meta)
	 
			write_netcdf, minxsslevel1, indir + outfile, status, $
				            path=dir_metadata, att_file=attfile, /clobber
			end
	'3':	begin
			write_netcdf, minxsslevel3, indir + outfile, status, $
				            path=dir_metadata, att_file=attfile, /clobber
			end
	else:	begin
			print, 'ERROR with Level Name : ', level_name, ' - Exiting minxss_make_netcdf()'
			return
			end
endcase

if (verbose ne 0) then print, 'Completed the NetCDF file write.'
if keyword_set(debug) then stop, 'DEBUG: at end of minxss_make_netcdf.pro ...'
return
end
