;
;	plot relative solar signal for Ti diode 
;
restore, 'ti_rel.sav'

setplot
cc=rainbow(7)
!ytitle='Contribution to XPS Signal (%)'
!xtitle='Wavelength (Angstrom)'
!mtitle=''

plot,wnorm,nsn2*100.,yr=[0,25],xr=[0,100]  
oplot,wnorm,nsn*100,color=cc[0]            
oplot,wnorm,nsr*100,color=cc[3]            
oplot,wnorm,nse*100,color=cc[5]            
oplot,wnorm,nsm*100,color=cc[6]            
oplot,wnorm,nsn2*100,color=cc[1]           
xyouts,10,23,'NRLEUV V2 (0.54 nA)',color=cc[1]
xyouts,10,21,'NRLEUV V1 1-nm (1.4 nA)',color=cc[0]
xyouts,10,19,'Woods VUV_2002 (6.8 nA)',color=cc[3]
xyouts,10,17,'Hinteregger EUV81 (2.3 nA)',color=cc[5]
xyouts,10,15,'Mewe (1.8 nA)',color=cc[6]     

end
