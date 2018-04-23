;+
; NAME:
;   xact_export_tlm_csv
;
; PURPOSE:
;   Export XACT telemetry to a csv file so Blue Canyon Technologies (BCT) can import to MATLAB
;
; INPUTS:
;   savesetPathAndFilename [string]: The path to an IDL saveset containing ADCS data, which should be produced 
;                                by minxss_make_level0b (at the time this code was written; ultimately want
;                                to use minxss_make_level0c)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   CSV file with ADCS data, placed in 9000 Processing/xact_tlm_exported with a filename based on savesetPathAndFilename
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires ParsePathAndFilename  
;
; EXAMPLE:
;   xact_export_tlm_csv, '/Users/jmason86/Drive/CubeSat/MinXSS Server/9000 Processing/data/level0b/minxss_l0b_2015_243.sav'
;
; MODIFICATION HISTORY:
;   2015/08/31: James Paul Mason: Wrote script.
;   2015/10/23: James Paul Mason: Refactored minxss_processing -> minxss_data and changed affected code to be consistent
;-
PRO xact_export_tlm_csv, savesetPathAndFilename

; Initial check for file existence
IF ~file_test(savesetPathAndFilename) THEN BEGIN
  print, 'File does not exist. Check for typos in path. Make sure to include actual .sav filename.'
  return
ENDIF

; Pull up data and check data for ADCS telemetry
restore, savesetPathAndFilename
adcsDataMissing = 0
IF adcs1 EQ !NULL THEN BEGIN
  adcsDataMissing = 1
  print, 'ADCS page 1 telemetry missing in saveset.'
ENDIF
IF adcs2 EQ !NULL THEN BEGIN
  adcsDataMissing = 1
  print, 'ADCS page 2 telemetry missing in saveset.'
ENDIF
IF adcs3 EQ !NULL THEN BEGIN
  adcsDataMissing = 1
  print, 'ADCS page 3 telemetry missing in saveset.'
ENDIF
IF adcs4 EQ !NULL THEN BEGIN
  adcsDataMissing = 1
  print, 'ADCS page 4 telemetry missing in saveset.'
ENDIF
IF adcsDataMissing EQ 1 THEN return

; Get all tag names
adcs1Tags = tag_names(adcs1)
adcs2Tags = tag_names(adcs2)
adcs3Tags = tag_names(adcs3)
adcs4Tags = tag_names(adcs4)

; Create output filenames
parsedPathFilename = ParsePathAndFilename(savesetPathAndFilename)
filenameDate = strmid(parsedPathFilename.filename, 11, 8, /REVERSE_OFFSET)
outputFilename1 = getenv('minxss_data') + '/xact_tlm_exported/' + filenameDate + '_xact_tlm1.txt'
outputFilename2 = getenv('minxss_data') + '/xact_tlm_exported/' + filenameDate + '_xact_tlm2.txt'
outputFilename3 = getenv('minxss_data') + '/xact_tlm_exported/' + filenameDate + '_xact_tlm3.txt'
outputFilename4 = getenv('minxss_data') + '/xact_tlm_exported/' + filenameDate + '_xact_tlm4.txt'

; ADCS 1

; Open first file and provide column headers
openw, lun, outputFilename1, /GET_LUN, WIDTH = 400
printf, lun, strjoin(adcs1Tags, ',', /SINGLE)

; Loop through time (array index) and tag names and store numbers (converted to string) into the file
FOR timeIndex = 0, n_elements(adcs1) - 1 DO BEGIN
  rowData = adcs1[timeIndex]
  rowDataString = ''
  FOR tagIndex = 0, n_elements(adcs1Tags) - 1 DO BEGIN
    IF tagIndex EQ 0 THEN                 rowDataString = strcompress(string(rowData.(tagIndex), /PRINT)) ELSE $
    IF adcs1Tags[tagIndex] EQ 'TIME' THEN rowDataString = strjoin([rowDataString, strcompress(string(rowData.(tagIndex), FORMAT = '(F21.10)'))], ',', /SINGLE) ELSE $
                                          rowDataString = rowDataString + ',' + strjoin(strcompress(string(rowData.(tagIndex), /PRINT)), /SINGLE)
  ENDFOR  
  printf, lun, rowDataString
ENDFOR
close, lun

; ADCS 2

; Open second file and provide column headers
openw, lun, outputFilename2, /GET_LUN, WIDTH = 400
printf, lun, strjoin(adcs2Tags, ',', /SINGLE)

; Loop through time (array index) and tag names and store numbers (converted to string) into the file
FOR timeIndex = 0, n_elements(adcs2) - 1 DO BEGIN
  rowData = adcs2[timeIndex]
  rowDataString = ''
  FOR tagIndex = 0, n_elements(adcs2Tags) - 1 DO BEGIN
    IF tagIndex EQ 0 THEN                 rowDataString = strcompress(string(rowData.(tagIndex), /PRINT)) ELSE $
      IF adcs2Tags[tagIndex] EQ 'TIME' THEN rowDataString = strjoin([rowDataString, strcompress(string(rowData.(tagIndex), FORMAT = '(F21.10)'))], ',', /SINGLE) ELSE $
      rowDataString = rowDataString + ',' + strjoin(strcompress(string(rowData.(tagIndex), /PRINT)), /SINGLE)
  ENDFOR
  printf, lun, rowDataString
ENDFOR
close, lun

; ADCS 3

; Open third file and provide column headers
openw, lun, outputFilename3, /GET_LUN, WIDTH = 400
printf, lun, strjoin(adcs3Tags, ',', /SINGLE)

; Loop through time (array index) and tag names and store numbers (converted to string) into the file
FOR timeIndex = 0, n_elements(adcs3) - 1 DO BEGIN
  rowData = adcs3[timeIndex]
  rowDataString = ''
  FOR tagIndex = 0, n_elements(adcs3Tags) - 1 DO BEGIN
    IF tagIndex EQ 0 THEN                 rowDataString = strcompress(string(rowData.(tagIndex), /PRINT)) ELSE $
      IF adcs3Tags[tagIndex] EQ 'TIME' THEN rowDataString = strjoin([rowDataString, strcompress(string(rowData.(tagIndex), FORMAT = '(F21.10)'))], ',', /SINGLE) ELSE $
      rowDataString = rowDataString + ',' + strjoin(strcompress(string(rowData.(tagIndex), /PRINT)), /SINGLE)
  ENDFOR
  printf, lun, rowDataString
ENDFOR
close, lun

; ADCS 4

; Open fourth file and provide column headers
openw, lun, outputFilename4, /GET_LUN, WIDTH = 400
printf, lun, strjoin(adcs4Tags, ',', /SINGLE)

; Loop through time (array index) and tag names and store numbers (converted to string) into the file
FOR timeIndex = 0, n_elements(adcs4) - 1 DO BEGIN
  rowData = adcs4[timeIndex]
  rowDataString = ''
  FOR tagIndex = 0, n_elements(adcs4Tags) - 1 DO BEGIN
    IF tagIndex EQ 0 THEN                 rowDataString = strcompress(string(rowData.(tagIndex), /PRINT)) ELSE $
      IF adcs4Tags[tagIndex] EQ 'TIME' THEN rowDataString = strjoin([rowDataString, strcompress(string(rowData.(tagIndex), FORMAT = '(F21.10)'))], ',', /SINGLE) ELSE $
      rowDataString = rowDataString + ',' + strjoin(strcompress(string(rowData.(tagIndex), /PRINT)), /SINGLE)
  ENDFOR
  printf, lun, rowDataString
ENDFOR
close, lun

END