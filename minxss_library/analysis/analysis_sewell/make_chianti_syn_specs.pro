PRO make_chianti_syn_specs
  !PATH='+C:\Users\rsewe\Documents\ssw\packages\chianti\idl;'+!PATH
  !PATH=EXPAND_PATH(!PATH)
  use_chianti,'C:\Users\rsewe\Documents\ssw\packages\chianti\dbase'
  mod_abund_file='C:\Users\rsewe\Documents\ssw\packages\chianti\dbase\abundance\sun_coronal_1992_feldman_ext_mod.abund'
  
  readcol,'C:\Users\rsewe\Documents\ssw\packages\chianti\dbase\abundance\sun_coronal_1992_feldman_ext.abund',format='I,F,A',ind,abund,el
  ind=fix(strtrim(string(ind),2))
  abund=float(strtrim(string(abund),2))
  el=strtrim(el,2)
  low_fip_inds=where(el eq 'Ni' or el eq 'Fe' or el eq 'Si' or el eq 'Mg' or el eq 'Ca')
  s_ind=where(el eq 'S')
  ch_bin=0.01
  kev_min=.9
  kev_max=5.1
  wmax=12.398/kev_min
  wmin=12.398/kev_max
  vem_arr=[0.01,.01,1.,10.];*10^49 cm^-3
  t_arr=[0.1,2,6,14]; MK
  abund_factor_arr=[0.001,.1,1.,2.5]; Scaling factor to feldman coronal ext abund 
  spectra=[[]];[[fltarr(fix((kev_max-kev_min)/ch_bin)+1)]]
  spec_params=[[]]
  foreach t, t_arr, i do begin
    foreach vem, vem_arr, j do begin
      log_sem=alog10(vem)+49-26.352; 10^49 cm^-3 -> log cm^-5
      log_t=alog10(t)+6; log MK
      if vem ne 0. or t ne 0. then begin
        ch_synthetic,wmin,wmax, output=str, density=1e10,/all,/photons,/verbose, $
          logt_isothermal=log_t,logem_isothermal=log_sem
      endif
      foreach abund_factor, abund_factor_arr, k do begin
        if abund_factor eq 0. or vem eq 0. or t eq 0. then begin
          spectra=[[spectra],[fltarr(fix((kev_max-kev_min)/ch_bin)+1)]]
          spec_params=[[spec_params],[t,vem,abund_factor]]
        endif else begin
          abund_mod=abund
          abund_mod[low_fip_inds]=abund[low_fip_inds]*abund_factor
          abund_mod[s_ind]=abund[s_ind]*(1.+(abund_factor-1.)/2.);sulfur is mid fip so half the abundance factor change
          writecol,mod_abund_file,ind,abund_mod,el,FMT='(I2,2X,F8.4,2X,A2)'
          filnum = 91
          close, filnum
          openu, filnum, mod_abund_file,/append
          printf, filnum, -1, FORMAT='(I2)'
          printf, filnum, 'Modified sun_coronal_1992_feldman_ext.abund', FORMAT='(A)'
          printf, filnum, -1, FORMAT='(I2)'
          close, filnum
          make_chianti_spec, str, kev_bins, struct, /CONTINUUM,$
            BIN_SIZE=ch_bin, instr_fwhm=ch_bin,/kev,/photons,$
            abund_name=concat_dir(concat_dir(!xuvtop,'abundance'),'sun_coronal_1992_feldman_ext_mod.abund')
          spectra=[[spectra],[struct.spectrum]]
          spec_params=[[spec_params],[t,vem,abund_factor]]
        endelse
      endforeach
    endforeach
  endforeach
  
  spec_sum_struct=sum_chianti_specs(spectra,spec_params)
  save,file='C:\Users\rsewe\Documents\X123_Analysis\chianti_syn_specs.sav',spec_sum_struct,kev_bins
  stop
END