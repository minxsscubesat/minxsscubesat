;+
; NAME:
;  read_generic_fits
;
; PURPOSE:
;  Read all of the HDUs in a FITS file, creating a merged set of
;  structures for the data, and string arrays for the keywords.
;
; CATEGORY:
;  SDO-EVE lib
;
; CALLING SEQUENCE:
;  IDL> data = read_generic_fits( filename [, /verbose][,_extra=_extra] )
;
; INPUTS:
;  filename : a scalar string for a FITS file
;             If comressed with gzip (.gz) spawn is called to
;             decompress into a temporary file which is read and
;             subsequently deleted.
;
; OPTIONAL INPUTS:
;  _extra : additional parameters to pass to mrdfits (refer to mrdfits.pro)
;
; KEYWORD PARAMETERS:
;  /verbose : report information on each HDU read (nothing is reported normally)
;
; OUTPUTS:
;  data : returned data is a structure that contains structures from
;         each HDU and an associated string array for the keywords
;
; OPTIONAL OUTPUTS:
;  none
;
; COMMON BLOCKS:
;  none
;
; SIDE EFFECTS:
;  Substructure names correspond to the keyword "EXTNAME", if absent,
;  then a default naming convention is used.
;
; RESTRICTIONS:
;  Requires fits_info.pro and mrdfits.pro (with it's own dependencies).
;
;  This should be compatible with all OSes, but we only test on Linux
;  and Mac OS X. However, if you encounter problems, try decompressing
;  the FITS files before you call this function.
;
;  You can't get something for nothing. Gzip compressed files
;  need to be decompressed to be properly read if multiple HDUs exist
;  in the FITS file. This takes time and disk space. If the /dev/shm
;  directory exists (linux tmpfs volume) then it is used. This
;  restricts file sizes to about half the size of the available
;  RAM. If that directory does not exist, then the current (.)
;  directory is used, so you need to be in a writeable directory.
;
;  The temporary filename used is based on the system clock. There
;  could be conflicts, so this code is not strictly thread-safe, but
;  most users running several processes will never encounter a
;  conflict. The filename uses 43 decimal digits from the systime(1)
;  function which includes some digits beyond the precision of the
;  clock. It is unikely (but possible) that successive calls would
;  occur on the same clock tick.
;
; EXAMPLE:
;  IDL> data=read_generic_fits('EVS_L2_2010120_00_002_01.fit.gz',/verbose)
;
; MODIFICATION HISTORY:
;  2/21/10 DLW Modified from CJs pre-release version.
;  9/01/11 CDJ Gutted. This just calls eve_read_whole_fits, which is the 
;              solarsoft version which handles compression better.
;
; $Id: read_generic_fits.pro,v 4.0 2013/03/28 19:18:20 dlwoodra Exp $
;-
function read_generic_fits,infname,verbose=verbose,_extra=extra
  return,eve_read_whole_fits(infname,verbose=verbose,_extra=extra)
end
