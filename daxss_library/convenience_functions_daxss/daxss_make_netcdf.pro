;+
; NAME:
;   daxss_make_netcdf.pro
;
; PURPOSE:
;   Make daxss NetCDF file for specific Level data product stored as IDL save set.
;   A metadata attributes file must exist.
;
; INPUTS
;   level [string]: Level name: '0C', '0D', '1', '2', '3', '4'
;
; OPTIONAL INPUTS:
;   fm [integer]:     Flight model number (default is 3)
;   version [string]: The version tag to put in the output filename and internal anonymous structure. Default is '1.0.0'
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set to print processing messages
;   DEBUG:   Set to trigger stop points for debugging
;
; OUTPUTS
;   None
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Metadata file corresponding to the input level must exist
;
; PROCEDURE
; 1.  Setup directory and file names based on Level name provided
; 2.  Read Level file (IDL save set restore)
; 3.  Write NetCDF file
;-
pro daxss_make_netcdf, level, $
                       fm=fm, version=version, $
                       VERBOSE=VERBOSE, DEBUG=DEBUG

if keyword_set(verbose) then verbose=1 else verbose=0
if keyword_set(debug) then verbose=1

level_name = strtrim(strupcase(level),2)

IF version EQ !NULL THEN version = '2.0.0'
version_float = float(version)  ; keeps first 2 digits
version_long = long(version)	; keeps only first digit

IF fm EQ !NULL THEN fm = 3
IF fm EQ 3 THEN BEGIN
  mission_start_date = '2022-02-14'
ENDIF
fm = strtrim(fm, 2)


;
; get root data directory dependent on FM number
;
;  slash for Mac = '/', PC = '\'
slash = path_sep()
dir_data = getenv('minxss_data') + slash + 'fm' + fm + slash
dir_metadata = dir_data + 'metadata' + slash

;
; 1.  Setup directory and file names based on Level name provided
;
SETUP:
case level_name of
  '0C': begin
    indir = dir_data + 'level0c' + slash
    infile = 'daxss_l0c_all_mission_length_v' + version + '.sav'
    outfile = 'daxss_solarSXR_level0C_' + mission_start_date + '-mission_v' + version + '.nc'
    attfile = 'daxss_solarSXR_level0C_metadata_v' + version + '.att'
  end
  '0D': begin
    indir = dir_data + 'level0d' + slash
    infile = 'daxss_l0d_mission_length_v' + version + '.sav'
    outfile = 'daxss_solarSXR_level0D_' + mission_start_date + '-mission_v' + version + '.nc'
    attfile = 'daxss_solarSXR_level0D_metadata_v' + version + '.att'
  end
  '1': begin
    indir = dir_data + 'level1' + slash
    infile = 'daxss_l1_mission_length_v' + version + '.sav'
    outfile = 'daxss_solarSXR_level1_' + mission_start_date + '-mission_v' + version + '.nc'
    attfile = 'daxss_solarSXR_level1_metadata_v' + version + '.att'
  end
  '2': begin
    indir = dir_data + 'level2' + slash
    infile = 'daxss_l2_1minute_average_mission_length_v' + version + '.sav'
    outfile = 'daxss_solarSXR_level2_1minute_average_' + mission_start_date + '-mission_v' + version + '.nc'
    attfile = 'daxss_solarSXR_level2_1minute_average_metadata_v' + version + '.att'
    IF one_minute_done NE !NULL THEN BEGIN
      infile = 'daxss_l2_1hour_average_mission_length_v' + version + '.sav'
      outfile = 'daxss_solarSXR_level2_1hour_average_' + mission_start_date + '-mission_v' + version + '.nc'
      attfile = 'daxss_solarSXR_level2_1hour_average_metadata_v' + version + '.att'
    ENDIF
  end
  '3': begin
    indir = dir_data + 'level3' + slash
    infile = 'daxss_l3_1day_average_mission_length_v' + version + '.sav'
    outfile = 'daxss_solarSXR_level3_1day_average_' + mission_start_date + '-mission_v' + version + '.nc'
    attfile = 'daxss_solarSXR_level3_1day_average_metadata_v' + version + '.att'
  end
  else: begin
    print, 'ERROR with Level Name : ', level_name, ' - Exiting daxss_make_netcdf()'
    return
  end
endcase

;
; 2.  Read Level file (IDL save set restore)
;
if (verbose ne 0) then print, 'Reading IDL save set ', indir + infile
restore, indir + infile

; stop, 'DEBUG data from SAV file...'

;
; 3.  Write NetCDF file
;
if (verbose ne 0) then begin
  print, 'Writing NetCDF file:  ', indir + outfile, ' with metadata file: ', dir_metadata + attfile
endif
case level_name of
  '0C': begin
    if (dump EQ !NULL) then dump = -1
    daxsslevel0c = { hk: hk, p1sci: p1sci, p2sci: p2sci, sci: sci, dump: dump }
    write_netcdf, daxsslevel0c, indir + outfile, status, $
                  path=dir_metadata, att_file=attfile, /clobber
  end
  '0D': begin
    write_netcdf, daxss_level0d, indir + outfile, status, $
                  path=dir_metadata, att_file=attfile, /clobber
  end
  '1': begin
    write_netcdf, daxss_level1_data, indir + outfile, status, $
                  path=dir_metadata, att_file=attfile, /clobber
  end
  '2': begin
    write_netcdf, daxss_average_data, indir + outfile, status, $
                  path=dir_metadata, att_file=attfile, /clobber
    IF one_minute_done EQ !NULL THEN BEGIN
      one_minute_done = 1
      GOTO, SETUP
    ENDIF
  end
  '3': begin
    write_netcdf, daxss_average_data, indir + outfile, status, $
                  path=dir_metadata, att_file=attfile, /clobber
  end
  else: begin
    print, 'ERROR with Level Name : ', level_name, ' - Exiting daxss_make_netcdf()'
    return
  end
endcase

if keyword_set(VERBOSE) then message, /INFO, 'Completed the NetCDF file write.'
if keyword_set(debug) then stop, 'DEBUG: at end of daxss_make_netcdf.pro ...'

end
