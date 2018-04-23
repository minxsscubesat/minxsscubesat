

;+
; NAME:
;   gauss_variable_fwhm_convolve
;
; AUTHOR:
;   Chris Moore, LASP, Boulder, CO 80303
;   christopher.moore-1@colorado.edu
;
; PURPOSE: Calculate the gaussian psf convolution of a 1d dataset with a fwhm as a function of the x values, spectral resolution.
;         x_array, x_fwhm_spectral_array and fwhm_spectral_array must be in the same units!
;         
;
; MAJOR TOPICS: uses the gaussfold function
;
; CALLING SEQUENCE:
;
; DESCRIPTION: x_array - 1d array, the x values, energy, wavelength, etc.
;              y_array - 1d array, the y values, intensity, flux, etc.
;              x_fwhm_spectral_array - 1d array, the x values for the fwhm array, in units of energy, wavelength, etc.
;              fwhm_spectral_array - 1d array, the fwhm values as a function of x_fwhm_spectral_array, must be in the same units as x_array and x_fwhm_spectral_array.

; INPUTS:

;
; INPUT KEYWORD PARAMETERS:
;

; RETURNS:
;
;
; EXAMPLE:
;
;
; REFERENCES:
;
; MODIFICATION HISTORY:
;   Written, April, 2016, Christopher S. Moore
;   Laboratory for Atmospheric and Space Physics
;
;
;-
;-



function gauss_variable_fwhm_convolve, x_data_array, y_data_array, x_fwhm_spectral_array, fwhm_spectral_array

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;find the number of wavelengths/elemennts
  n_data = n_elements(x_data_array)
  data_gaussian_convolved_variable_fwhm = dblarr(n_data)
  max_x_data_array = max(x_data_array)
  min_x_data_array = min(x_data_array)
  
  ;find the largest fwhm value to pad the spectrum to be convolved
  max_fwhm_spectral_array = max(fwhm_spectral_array)
  Scale_factor = 10.0
  ;for evenly spaced data, find the # of bins that correspond to the largest fwhm and expand the array by twice this on each side
  delta_x_data_array = abs(x_data_array[0] - x_data_array[1])
  size_x_data_max_fwhm_spectral_array = float(long((Scale_factor*max_fwhm_spectral_array)/delta_x_data_array) + 1.0)
 ;Pad the data array with 0's
 min_padded_x_data_array = min_x_data_array - (delta_x_data_array*size_x_data_max_fwhm_spectral_array)
 
 
  ;interpolate the fwhm array to the data array
  interpol_fwhm_spectral_array = interpol(fwhm_spectral_array, x_fwhm_spectral_array, x_data_array, /NAN)
  
  if WHERE(interpol_fwhm_spectral_array LT 0.0) GT 0.0 THEN PRINT, 'interpolated fwhm array has negative values!!!!'
  
  ;create a padded array, so that we do not need to convelve the entire array every time for speed improvements
  n_padded = n_data + 2.0*(size_x_data_max_fwhm_spectral_array)
  padded_x_data_array = (delta_x_data_array*dindgen(n_padded)) + min_padded_x_data_array
  padded_y_data_array = dblarr(n_padded)
  padded_y_data_array[size_x_data_max_fwhm_spectral_array-1:n_padded-size_x_data_max_fwhm_spectral_array-2] = y_data_array


  for k = size_x_data_max_fwhm_spectral_array - 1, n_padded-size_x_data_max_fwhm_spectral_array-1 do begin
    temp = gaussfold(padded_x_data_array[k-size_x_data_max_fwhm_spectral_array+1:k+size_x_data_max_fwhm_spectral_array-1], padded_y_data_array[k-size_x_data_max_fwhm_spectral_array+1:k+size_x_data_max_fwhm_spectral_array-1], interpol_fwhm_spectral_array[k-size_x_data_max_fwhm_spectral_array])
    data_gaussian_convolved_variable_fwhm[k-size_x_data_max_fwhm_spectral_array] = temp[long(size_x_data_max_fwhm_spectral_array)]
  endfor
 
;    for k = 0, n_data - 1 do begin
;      temp = gaussfold(x_data_array, y_data_array, interpol_fwhm_spectral_array[k])
;      data_gaussian_convolved_variable_fwhm[k] = temp[k]
;    endfor
    

  ;return the model output signal
  return, data_gaussian_convolved_variable_fwhm


end