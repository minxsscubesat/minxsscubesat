;+
; NAME:
;	F_2VTH_ABUN_DEFAULTS
;
; PURPOSE: Function to return default values for
;   parameters, minimum and maximum range, free parameter mask,
;   spectrum and model to use, and all spectrum and model options when
;   fitting to f_2vth_abun function.
;
; CALLING SEQUENCE: defaults = f_2vth_abun_defaults()
;
; INPUTS:
;	None
; OUTPUTS:
;	Structure containing default values
;
; MODIFICATION HISTORY:
; Kim Tolbert, 10-Oct-2013
;
;-
;------------------------------------------------------------------------------

FUNCTION F_2VTH_ABUN_DEFAULTS

defaults = { $
  fit_comp_params:           [1e0,   .2,    1e0,   .2,     1.,  1.,  1.,  1., 1., 1.,  1.], $
  fit_comp_minima:           [1e-20, 1e-1, 1e-20, 1e-1, .01, .01, .01, .01, .01, .01, .01], $
  fit_comp_maxima:           [1e20,  8.,   1e20,  8.,   10., 10., 10., 10., 10., 10., 10.], $
  fit_comp_free_mask:        [1b,    1b,   1b,    1b,    1b,  0b,  0b,  0b, 0b, 0b,  0b], $

  fit_comp_spectrum:         'full', $
  fit_comp_model:            'chianti', $

  fc_spectrum_options:		['full','continuum','line'], $
  fc_model_options:			['chianti', 'mewe'] $
}

RETURN, defaults

END
