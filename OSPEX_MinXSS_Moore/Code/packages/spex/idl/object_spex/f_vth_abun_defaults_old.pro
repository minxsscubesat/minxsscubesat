;+
; NAME:
;	F_TH_ABUN_DEFAULTS_Old
;
; PURPOSE: Function to return default values for
;   parameters, minimum and maximum range, free parameter mask,
;   spectrum and model to use, and all spectrum and model options when
;   fitting to f_vth_abun function.
;
; CALLING SEQUENCE: defaults = f_vth_abun_defaults()
;
; INPUTS:
;	None
; OUTPUTS:
;	Structure containing default values
;
; MODIFICATION HISTORY:
; Kim Tolbert, February 2006
; 7-Apr-2006, Kim.  Added fit_comp_spectrum,fit_comp_model
; 19-Apr-2006, Kim.  added defaults for 3rd param (rel abun)
; 13-Nov-2006, Kim.  Default for a[1] (temp) changed from 5e1 to 8.
; 16-Oct-2007, Kim.  Added fc_spectrum_options and fc_model_options
; 12-May-2008, Kim.  Added defaults for 3,4,5th parameters (separate abundances)
; 30-Jun-2008, Kim.  Added defaults for 6,7th params (argon abun, abun for 10 other elements)
; 27-Aug-2008, Kim.  Narrowed down min and max
; 24-Feb-2014, Kim.  Changed abun param minima to .1 (was .2)
;
;-
;------------------------------------------------------------------------------

FUNCTION F_VTH_ABUN_DEFAULTS_OLD

defaults = { $
  fit_comp_params:           [1e0,   2,    1.,   1.,  1.,  1.,  1.,  1.], $
  fit_comp_minima:           [1e-20, 5e-1, .1, .1, .1, .1, .1, .1], $
  fit_comp_maxima:           [1e20,  8.,   2.,  2., 2., 2., 2., 2.], $
  fit_comp_free_mask:        [1b,    1b,   1b,   1b,  0b,  0b,  0b,  0b], $

  fit_comp_spectrum:         'full', $
  fit_comp_model:            'chianti', $

  fc_spectrum_options:		['full','continuum','line'], $
  fc_model_options:			['chianti', 'mewe'] $
}

RETURN, defaults

END
