;
;	pv_to_j2000
;
;	Transform Position & Velocity vector for specific time (JD) into Position & Velocity for J2000
;	Apply Earth's precession and nutation from that specified time to 1-1-2000
;
;	INPUT
;		time			Julian Date
;		pv				Position [0:2] and Velocity [3:5]
;		/verbose		Option to print debug messages
;
;	OUTPUT
;		pv_j2000		J2000 ECI coordinates of the Position and Velocity
;
;	LIBRARY
;		This depends on the Astronomy Library SGP4 and MSGP4,
;		that calls nutate_matrix() and precess_matrix() with difference in JD to J2000 in JD-centuries
;
;	HISTORY
;		2016-02-06	T. Woods	Original code
;
function pv_to_j2000, time, pv, verbose=verbose

if n_params() lt 2 then begin
	print, 'USAGE:  pv_j2000 = pv_to_j2000( time, pv, /verbose)
	return, -1
endif

jd_2000 =  2451545.0D0
jd_diff = (jd_2000-time) / (365.25D0 * 1000.)

;
;	get Earth's nutation matrix and precession matrix
;
nmatrix = nutate_matrix( jd_diff )
pmatrix = precess_matrix( jd_diff )

;
;	Order of transformations is precession first and then nutation
;
pv_j2000 = pv
pv_j2000[0:2] = nmatrix # (pmatrix # pv[0:2])
pv_j2000[3:5] = nmatrix # (pmatrix # pv[3:5])

if keyword_set(verbose) then begin
  print, ' '
  print, 'Position Input = ', pv[0:2]
  print, 'Position J2000 = ', pv_j2000[0:2]
  print, ' '
  print, 'Velocity Input = ', pv[3:5]
  print, 'Velocity J2000 = ', pv_j2000[3:5]
  print, ' '
endif

return, pv_j2000
end
