;
;	plot_ttm_rad_test.pro
;
;	3/11/2021 Tom Woods
;

;
;	read TLM data files (3 total)
;
if n_elements(d3) lt 2 then begin
file1='/Users/twoods/Documents/CubeSat/LASP_SIM-super-lite/Radhard_NanoSIM/Tests/TTM_GSFC_Radiation_Test_2021_March/hydra_tlm_2021_069_07_33_45/tlm_packets_2021_069_07_34_09'
file2='/Users/twoods/Documents/CubeSat/LASP_SIM-super-lite/Radhard_NanoSIM/Tests/TTM_GSFC_Radiation_Test_2021_March/hydra_tlm_2021_069_07_33_45/tlm_packets_2021_069_07_35_51'
file3='/Users/twoods/Documents/CubeSat/LASP_SIM-super-lite/Radhard_NanoSIM/Tests/TTM_GSFC_Radiation_Test_2021_March/hydra_tlm_2021_069_07_33_45/tlm_packets_2021_069_07_48_01'

	d1=dualsps_read_file_ccsds(file1,/verbose,messages=msg1,sim=sim1)
	d2=dualsps_read_file_ccsds(file2,/verbose,messages=msg2,sim=sim2)
	d3=dualsps_read_file_ccsds(file3,/verbose,messages=msg3,sim=sim3)
endif

doEPS = 0		; set non-zero to make EPS PLOTS
ans = ' '
pdir='/Users/twoods/Documents/CubeSat/LASP_SIM-super-lite/Radhard_NanoSIM/Tests/TTM_GSFC_Radiation_Test_2021_March/plots/'

;  select good "time" data
jd_start = yd2jd(2021069.D0)
wgd1 = where( d1.jd gt jd_start )
d1g =d1[wgd1]
wgd2 = where( d2.jd gt jd_start )
d2g =d2[wgd2]
wgd3 = where( d3.jd gt jd_start )
d3g =d3[wgd3]

wgd1 = where( sim1.jd gt jd_start )
sim1g =sim1[wgd1]
wgd2 = where( sim2.jd gt jd_start )
sim2g =sim2[wgd2]
wgd3 = where( sim3.jd gt jd_start )
sim3g =sim3[wgd3]

xrange = [ min(d1g.jd), max(d3g.jd) ]

; Event time for Radiation Failure
event_time = yd2jd( 2021069.D0 + (7.+7.+57./60.+26./3600.)/24. )  ; 2021/069-07:57:26 + 7hr to UT

;  make critical plots of Data Packets voltage, current, temperature
data_tag_names = tag_names(d1)
ii_data = [ 16, 17, 18, 19, 20, 21, 24, 25, 26, 30, 40, 41 ]
data_units = [ 'V', 'mA', 'V', 'mA', 'V', 'mA', 'V', 'V', 'C', 'DN', 'C', 'C' ]
num_ii = n_elements(ii_data)

for ii=0L,num_ii-1 do begin

	if (doEPS ne 0) then begin
		efile = 'ttm_data_'+data_tag_names[ii_data[ii]]+'.eps'
		print, 'Graphics written to ',efile
		eps2_p, pdir + efile
	endif

	tomsetplot & cc=rainbow(7) & cs=2.0
	ld = label_date( date_format='%H-%I' )
	yrange = [ min(d1g.(ii_data[ii]))*0.98-0.001, max(d3g.(ii_data[ii]))*1.02+0.001 ]

	plot, d1g.jd, d1g.(ii_data[ii]), xs=1, xrange=xrange, ys=1, yrange=yrange, $
			xtitle='Time (hr-min)', ytitle=data_units[ii], title=data_tag_names[ii_data[ii]], $
			XTICKFORMAT = 'LABEL_DATE', XTICKUNITS = 'Time'
	oplot, d2g.jd, d2g.(ii_data[ii]), color=cc[3]
	oplot, d3g.jd, d3g.(ii_data[ii]), color=cc[1]
	oplot, event_time*[1,1], !y.crange, color=cc[0]

	if (doEPS ne 0) then send2 else read, 'Next Plot ? ', ans
endfor

; make critical plots of SIM Packets voltage, current, temperature
sim_tag_names = tag_names(sim1)
ii_sim = [ 13, 14, 15, 12 ]
sim_units = [ 'C', 'C', 'C', 'DN' ]
num_ii = n_elements(ii_sim)

for ii=0L,num_ii-1 do begin

	if (doEPS ne 0) then begin
		efile = 'ttm_sim_'+sim_tag_names[ii_sim[ii]]+'.eps'
		print, 'Graphics written to ',efile
		eps2_p, pdir + efile
	endif

	tomsetplot & cc=rainbow(7) & cs=2.0
	ld = label_date( date_format='%H-%I' )
	yrange = [ min(sim1g.(ii_sim[ii]))*0.98, max(sim3g.(ii_sim[ii]))*1.02 ]

	sim1data = sim1g.(ii_sim[ii])
	sim2data = sim2g.(ii_sim[ii])
	sim3data = sim3g.(ii_sim[ii])
	if (ii_sim[ii] eq 10) or (ii_sim[ii] eq 11) or (ii_sim[ii] eq 12) then BEGIN
		; select Channel 0 for SIM-A, B, or C array
		sim1data = sim1g.(ii_sim[ii])[0]
		sim2data = sim2g.(ii_sim[ii])[0]
		sim3data = sim3g.(ii_sim[ii])[0]
	ENDIF

	plot, sim1g.jd, sim1data, xs=1, xrange=xrange, ys=1, yrange=yrange, $
			xtitle='Time (hr-min)', ytitle=sim_units[ii], title=sim_tag_names[ii_sim[ii]], $
			XTICKFORMAT = 'LABEL_DATE', XTICKUNITS = 'Time'
	oplot, sim2g.jd, sim2data, color=cc[3]
	oplot, sim3g.jd, sim3data, color=cc[1]
	oplot, event_time*[1,1], !y.crange, color=cc[0]

	if (doEPS ne 0) then send2 else read, 'Next Plot ? ', ans
endfor

end
