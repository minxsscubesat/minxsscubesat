pro neighbor_consistency,tle,cR, cV
  cr=dblarr(n_elements(tle))
  cv=dblarr(n_elements(tle))
  for j=1,n_elements(tle)-2 do begin
;        Get 3 distances (in both dRdT and dVdt)
    Pair_Difference,tle[j-1],tle[j]  ,dT12, dR12, dV12, dRdT12, dVdT12
    Pair_Difference,tle[j],tle[j+1]  ,dT23, dR23, dV23, dRdT23, dVdT23
    Pair_Difference,tle[j-1],tle[j+1],dT13, dR13, dV13, dRdT13, dVdT13

;        Set j is inconsistent if sets j-1 and j+1 agree with each
;        other, but not with j:
    cR[j] = (dRdT12 + dRdT23 + dRdT13)/(3.*dRdT13)
    cV[j] = (dVdT12 + dVdT23 + dVdT13)/(3.*dVdT13)
  end
end
