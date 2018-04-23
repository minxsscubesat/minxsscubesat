;;; equation based on chianti dem to make accurate model
;; CL- Summer 2016

function make_sun_spectrum, fqs, far, fch, rqs, rar, rch
rd_genx, 'demquietsun_02.genx', demqs
rd_genx, 'demactive_region_02.genx', demar
rd_genx, 'demcoronal_hole_02.genx', demch
rqs=(demqs.spectrum*6.8e-5)*fqs[0]
rar=(interpol(demar.spectrum,demar.lambda,demqs.lambda)*6.8e-5)*far[0]
rch=(interpol(demch.spectrum,demch.lambda,demqs.lambda)*6.8e-5)*fch[0]
sp=rqs+rar+rch
result=[[demqs.lambda], [sp]]
return, result
end