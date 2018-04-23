;+
; NAME:
;plotallxrs
;
; PURPOSE:
; simple plot of XRS channels
;  11/30/10    ARJ modified from plotxrs
;+

pro plotallxrs, filename
;
;	Read Raw Dump File
;
alldata = read_rxrs( filename )
nn = n_elements(alldata)
if (nn lt 2) then begin
  print, 'ERROR plotallxrs: No valid data found for ', filename
  return
endif

time = MAKE_ARRAY(nn, /DOUBLE, VALUE = !Values.F_NAN)
D1 =   MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
D2 =   MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
A1 =   MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
A20 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
A21 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
A22 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
A23 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
B1 =   MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
B20 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
B21 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
B22 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)
B23 =  MAKE_ARRAY(nn, /INTEGER, VALUE = !Values.F_NAN)

V1 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V2 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V3 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V4 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V5 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V6 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V7 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V8 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V9 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V10 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V11 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)
V12 = MAKE_ARRAY(nn, /FLOAT, VALUE = !Values.F_NAN)



CMAX = MAKE_ARRAY(12, /FLOAT, VALUE = !Values.F_NAN)
CMIN = MAKE_ARRAY(12, /FLOAT, VALUE = !Values.F_NAN)
CAV =  MAKE_ARRAY(12, /FLOAT, VALUE = !Values.F_NAN)

VMAX = MAKE_ARRAY(12, /FLOAT, VALUE = !Values.F_NAN)
VMIN = MAKE_ARRAY(12, /FLOAT, VALUE = !Values.F_NAN)
VAV =  MAKE_ARRAY(12, /FLOAT, VALUE = !Values.F_NAN)

; --- Parse the data ---

time = alldata.time

ptype = 1
wgd=where(alldata.type eq ptype and alldata.value[0] gt 0, numgd)	
if (numgd lt 2) then begin
  print, 'ERROR plotxrs: not enough data packets for channel ', ch
  return
endif
D1  = alldata[wgd].raw[0]
  CMAX[0] = MAX(D1)
  CMIN[0] = MAX(D1)
  CAV[0] = MEAN(D1)
B20 = alldata[wgd].raw[1]
  CMAX[1] = MAX(B20)
  CMIN[1] = MAX(B20)
  CAV[1] = MEAN(B20)  
B21 = alldata[wgd].raw[2]
  CMAX[2] = MAX(B21)
  CMIN[2] = MAX(B21)
  CAV[2] = MEAN(B21)  
B22 = alldata[wgd].raw[3]
  CMAX[3] = MAX(B22)
  CMIN[3] = MAX(B22)
  CAV[3] = MEAN(B22)
B23 = alldata[wgd].raw[4]
  CMAX[4] = MAX(B23)
  CMIN[4] = MAX(B23)
  CAV[4] = MEAN(B23)
A1  = alldata[wgd].raw[5]
  CMAX[5] = MAX(A1)
  CMIN[5] = MAX(A1)
  CAV[5] = MEAN(A1)
  
V0 = alldata[wgd].value[0]
  VMAX[0] = MAX(V0)
  VMIN[0] = MAX(V0)
  VAV[0] = MEAN(V0)
V1 = alldata[wgd].value[1]
  VMAX[1] = MAX(V1)
  VMIN[1] = MAX(V1)
  VAV[1] = MEAN(V1)
V2 = alldata[wgd].value[2]
  VMAX[2] = MAX(V2)
  VMIN[2] = MAX(V2)
  VAV[2] = MEAN(V2)
V3 = alldata[wgd].value[3]
  VMAX[3] = MAX(V3)
  VMIN[3] = MAX(V3)
  VAV[3] = MEAN(V3)
V4 = alldata[wgd].value[4]
  VMAX[4] = MAX(V4)
  VMIN[4] = MAX(V4)
  VAV[4] = MEAN(V4)
V5 = alldata[wgd].value[5]
  VMAX[5] = MAX(V5)
  VMIN[5] = MAX(V5)
  VAV[5] = MEAN(V5)


ptype = 2
wgd=where(alldata.type eq ptype and alldata.value[0] gt 0, numgd)	
if (numgd lt 2) then begin
  print, 'ERROR plotxrs: not enough data packets for channel ', ch
  return
endif
A20 = alldata[wgd].raw[0]
  CMAX[6] = MAX(A20)
  CMIN[6] = MAX(A20)
  CAV[6] = MEAN(A20)
A21 = alldata[wgd].raw[1]
  CMAX[7] = MAX(A21)
  CMIN[7] = MAX(A21)
  CAV[7] = MEAN(A21)
A22 = alldata[wgd].raw[2]
  CMAX[8] = MAX(A22)
  CMIN[8] = MAX(A22)
  CAV[8] = MEAN(A22)
A23 = alldata[wgd].raw[3]
  CMAX[9] = MAX(A23)
  CMIN[9] = MAX(A23)
  CAV[9] = MEAN(A23)
B1  = alldata[wgd].raw[4]
  CMAX[10] = MAX(B1)
  CMIN[10] = MAX(B1)
  CAV[10] = MEAN(B1)
D2  = alldata[wgd].raw[5]
  CMAX[11] = MAX(D2)
  CMIN[11] = MAX(D2)
  CAV[11] = MEAN(D2)
  
V6 = alldata[wgd].value[0]
  VMAX[6] = MAX(V6)
  VMIN[6] = MAX(V6)
  VAV[6] = MEAN(V6)
V7 = alldata[wgd].value[1]
  VMAX[7] = MAX(V7)
  VMIN[7] = MAX(V7)
  VAV[7] = MEAN(V7)
V8 = alldata[wgd].value[2]
  VMAX[8] = MAX(V8)
  VMIN[8] = MAX(V8)
  VAV[8] = MEAN(V8)
V9 = alldata[wgd].value[3]
  VMAX[9] = MAX(V9)
  VMIN[9] = MAX(V9)
  VAV[9] = MEAN(V9)
V10 = alldata[wgd].value[4]
  VMAX[10] = MAX(V10)
  VMIN[10] = MAX(V10)
  VAV[10] = MEAN(V10)
V11 = alldata[wgd].value[5]
  VMAX[11] = MAX(V11)
  VMIN[11] = MAX(V11)
  VAV[11] = MEAN(V11)

; --- Plotting ---
!P.Multi=[0,1,2,0]
Pmax = MAX(cmax)
Pmin= MIN(cmin)

PLOT,  D1, yr=[pmin, pmax], /nodata, $
   Title = "Raw Counts", Xtitle="Sample #", Ytitle = "DN"
   OPLOT, D1, color=fsc_color("Black")
   OPLOT, D2, color=fsc_color("Grey")
   OPLOT, A1, color=fsc_color("Red")
   OPLOT, A20, color=fsc_color("Orange")
   OPLOT, A21, color=fsc_color("Yellow")
   OPLOT, A22, color=fsc_color("Gold")
   OPLOT, A23, color=fsc_color("Pink")
   OPLOT, B1, color=fsc_color("Blue")
   OPLOT, B20, color=fsc_color("Navy")
   OPLOT, B21, color=fsc_color("Turquoise")
   OPLOT, B22, color=fsc_color("Aquamarine")
   OPLOT, B23, color=fsc_color("Teal")
   
VVmax = MAX(vmax)
VVmin= MIN(vmin)

PLOT,  V0, yr=[vvmin, vvmax], /nodata, $
   Title = "Values", Xtitle="Sample #", Ytitle = "DN"
   OPLOT, V0, color=fsc_color("Black")
   OPLOT, V1, color=fsc_color("Grey")
   OPLOT, V2, color=fsc_color("Red")
   OPLOT, V3, color=fsc_color("Orange")
   OPLOT, V4, color=fsc_color("Yellow")
   OPLOT, V5, color=fsc_color("Gold")
   OPLOT, V6, color=fsc_color("Pink")
   OPLOT, V7, color=fsc_color("Blue")
   OPLOT, V8, color=fsc_color("Navy")
   OPLOT, V9, color=fsc_color("Turquoise")
   OPLOT, V10, color=fsc_color("Aquamarine")
   OPLOT, V11, color=fsc_color("Teal")
!P.Multi =0

Print, "File :", filename
Print, "Start Time :", time[0]
Print, "Stop Time :", time[nn-1]

;PRINT,"Av Drk", CAV
PRINT, "Dark Ratios"
PRINT, "A1", CAV[5]/CAV[0]
PRINT, "A2", CAV[6]/CAV[11], CAV[7]/CAV[11], CAV[8]/CAV[11], CAV[9]/CAV[11]
PRINT, "B1", CAV[10]/CAV[11]
PRINT, "B2", CAV[1]/CAV[0], CAV[2]/CAV[0], CAV[3]/CAV[0], CAV[4]/CAV[0]


END
