; docformat = 'rst'
;+
; :Author:
;   Don Woodraska
;
; :Copyright:
;   Copyright 2018 The Regents of the University of Colorado.
;   This software was developed at Spirit Winds coffee shop in 
;   Las Cruces for the University of Colorado
;   Laboratory for Atmospheric and Space Physics (LASP) to support 
;   NASA rocket 36.336 Jun 2018 payload alignment.
;
;-

;+
; Downloaded mpfitellipse from
; https://www.asu.cas.cz/~sos/software/mpfitellipse.pro
; on 6/10/18. Required mpfit in the path.
;
; NAME:
;   MPFITELLIPSE
;
; AUTHOR:
;   Craig B. Markwardt, NASA/GSFC Code 662, Greenbelt, MD 20770
;   craigm@lheamail.gsfc.nasa.gov
;   UPDATED VERSIONs can be found on my WEB PAGE: 
;      http://cow.physics.wisc.edu/~craigm/idl/idl.html
;
; PURPOSE:
;   Approximate fit to points forming an ellipse
;
; MAJOR TOPICS:
;   Curve and Surface Fitting
;
; CALLING SEQUENCE:
;   parms = MPFITELLIPSE(X, Y, start_parms, [/TILT, WEIGHTS=wts, ...])
;
; DESCRIPTION:
;
;   MPFITELLIPSE fits a closed elliptical or circular curve to a two
;   dimensional set of data points.  The user specifies the X and Y
;   positions of the points, and an optional set of weights.  The
;   ellipse may also be tilted at an arbitrary angle.
;
;   IMPORTANT NOTE: this fitting program performs simple ellipse
;   fitting.  It will not work well for ellipse data with high
;   eccentricity.  More robust answers can usually be obtained with
;   "orthogonal distance regression."  (See FORTRAN package ODRPACK on
;   netlib.org for more information).
;
;   The best fitting ellipse parameters are returned from by
;   MPFITELLIPSE as a vector, whose values are:
;
;      P[0]   Ellipse semi axis 1
;      P[1]   Ellipse semi axis 2   ( = P[0] if CIRCLE keyword set)
;      P[2]   Ellipse center - x value
;      P[3]   Ellipse center - y value
;      P[4]   Ellipse rotation angle (radians) if TILT keyword set
;
;   If the TILT keyword is set, then the P[0] is meant to be the
;   semi-major axis, and P[1] is the semi-minor axis, and P[4]
;   represents the tilt of the semi-major axis with respect to the X
;   axis.  If the TILT keyword is not set, the P[0] and P[1] represent
;   the ellipse semi-axes in the X and Y directions, respectively.
;   The returned semi-axis lengths should always be positive.
;
;   The user may specify an initial set of trial parameters, but by
;   default MPFITELLIPSE will estimate the parameters automatically.
;
;   Users should be aware that in the presence of large amounts of
;   noise, namely when the measurement error becomes significant
;   compared to the ellipse axis length, then the estimated parameters
;   become unreliable.  Generally speaking the computed axes will
;   overestimate the true axes.  For example when (SIGMA_R/R) becomes
;   0.5, the radius of the ellipse is overestimated by about 40%.
;
;   This unreliability is also pronounced if the ellipse has high
;   eccentricity, as noted above.
;
;   Users can weight their data as they see appropriate.  However, the
;   following prescription for the weighting may serve as a good
;   starting point, and appeared to produce results comparable to the
;   typical chi-squared value.
;
;     WEIGHTS = 0.75/(SIGMA_X^2 + SIGMA_Y^2)
;
;   where SIGMA_X and SIGMA_Y are the measurement error vectors in the
;   X and Y directions respectively.  However, this has not been
;   robustly tested, and it should be pointed out that this weighting
;   may only be appropriate for a set of points whose measurement
;   errors are comparable.  If a more robust estimation of the
;   parameter values is needed, the so-called orthogonal distance
;   regression package should be used (ODRPACK, available in FORTRAN
;   at www.netlib.org).
;
; INPUTS:
;
;   X - measured X positions of the points in the ellipse.
;   Y - measured Y positions of the points in the ellipse.
;
;   START_PARAMS - an array of starting values for the ellipse
;                  parameters, as described above.  This parameter is
;                  optional; if not specified by the user, then the
;                  ellipse parameters are estimated automatically from
;                  the properties of the data.
;
; RETURNS:
;
;   Returns the best fitting model ellipse parameters.  Returned
;   values are undefined if STATUS indicates an error condition.
;
; KEYWORDS:
;
;   ** NOTE ** Additional keywords such as PARINFO, BESTNORM, and
;              STATUS are accepted by MPFITELLIPSE but not documented
;              here.  Please see the documentation for MPFIT for the
;              description of these advanced options.
;
;   CIRCULAR - if set, then the curve is assumed to be a circle
;              instead of ellipse.  When set, the parameters P[0] and
;              P[1] will be identical and the TILT keyword will have
;              no effect.
;
;   PERROR - upon return, the 1-sigma uncertainties of the returned
;            ellipse parameter values.  These values are only
;            meaningful if the WEIGHTS keyword is specified properly.
;
;            If the fit is unweighted (i.e. no errors were given, or
;            the weights were uniformly set to unity), then PERROR
;            will probably not represent the true parameter
;            uncertainties.
;
;            If STATUS indicates an error condition, then PERROR is
;            undefined.
;
;   QUIET - if set then diagnostic fitting messages are suppressed.
;           Default: QUIET=1 (i.e., no diagnostics]
;
;   STATUS - an integer status code is returned.  All values greater
;            than zero can represent success (however STATUS EQ 5 may
;            indicate failure to converge).  Please see MPFIT for
;            the definitions of status codes.
;
;   TILT - if set, then the major and minor axes of the ellipse
;          are allowed to rotate with respect to the data axes.
;          Parameter P[4] will be set to the clockwise rotation angle
;          of the P[0] axis in radians, as measured from the +X axis.
;          P[4] should be in the range 0 to !dpi.
;
;   WEIGHTS - Array of weights to be used in calculating the
;             chi-squared value.  The chi-squared value is computed
;             as follows:
;
;                CHISQ = TOTAL( (Z-MYFUNCT(X,Y,P))^2 * ABS(WEIGHTS)^2 )
;
;             Users may wish to follow the guidelines for WEIGHTS
;             described above.
;
;
; EXAMPLE:
;
; ; Construct a set of points on an ellipse, with some noise
;   ph0 = 2*!pi*randomu(seed,50)
;   x =  50. + 32.*cos(ph0) + 4.0*randomn(seed, 50)
;   y = -75. + 65.*sin(ph0) + 0.1*randomn(seed, 50)
;
; ; Compute weights function
;   weights = 0.75/(4.0^2 + 0.1^2)
;
; ; Fit ellipse and plot result
;   p = mpfitellipse(x, y)
;   phi = dindgen(101)*2D*!dpi/100
;   plot, x, y, psym=1
;   oplot, p[2]+p[0]*cos(phi), p[3]+p[1]*sin(phi), color='ff'xl
;
; ; Fit ellipse and plot result - WITH TILT
;   p = mpfitellipse(x, y, /tilt)
;   phi = dindgen(101)*2D*!dpi/100
;   ; New parameter P[4] gives tilt of ellipse w.r.t. coordinate axes
;   ; We must rotate a standard ellipse to this new orientation
;   xm = p[2] + p[0]*cos(phi)*cos(p[4]) + p[1]*sin(phi)*sin(p[4])
;   ym = p[3] - p[0]*cos(phi)*sin(p[4]) + p[1]*sin(phi)*cos(p[4])
;
;   plot, x, y, psym=1
;   oplot, xm, ym, color='ff'xl
;
; REFERENCES:
;
;   MINPACK-1, Jorge More', available from netlib (www.netlib.org).
;   "Optimization Software Guide," Jorge More' and Stephen Wright, 
;     SIAM, *Frontiers in Applied Mathematics*, Number 14.
;
; MODIFICATION HISTORY:
;
;   Ported from MPFIT2DPEAK, 17 Dec 2000, CM
;   More documentation, 11 Jan 2001, CM
;   Example corrected, 18 Nov 2001, CM
;   Change CIRCLE keyword to the correct CIRCULAR keyword, 13 Sep
;      2002, CM
;   Add error messages for SYMMETRIC and CIRCLE, 08 Nov 2002, CM
;   Found small error in computation of _EVAL (when CIRCULAR) was set;
;      sanity check when CIRCULAR is set, 21 Jan 2003, CM
;   Convert to IDL 5 array syntax (!), 16 Jul 2006, CM
;   Move STRICTARR compile option inside each function/procedure, 9
;     Oct 2006
;   Add disclaimer about the suitability of this program for fitting
;     ellipses, 17 Sep 2007, CM
;   Clarify documentation of TILT angle; make sure output contains
;    semi-major axis first, followed by semi-minor; make sure that
;    semi-axes are always positive (and can handle negative inputs)
;      17 Sep 2007, CM
;   Output tilt angle is now in range 0 to !DPI, 20 Sep 2007, CM
;   Some documentation clarifications, including to remove reference
;     to the "ERR" keyword, which does not exist, 17 Jan 2008, CM
;   Swapping of P[0] and P[1] only occurs if /TILT is set, 06 Nov
;     2009, CM
;   Document an example of how to plot a tilted ellipse, 09 Nov 2009, CM
;   Check for MPFIT error conditions and return immediately, 23 Jan 2010, CM
;
;  $Id: mpfitellipse.pro,v 1.14 2010/01/25 03:38:03 craigm Exp $
;-
; Copyright (C) 1997-2000,2002,2003,2007,2008,2009,2010 Craig Markwardt
; This software is provided as is without any warranty whatsoever.
; Permission to use, copy, modify, and distribute modified or
; unmodified copies is granted, provided this copyright and disclaimer
; are included unchanged.
;-


FORWARD_FUNCTION mpfitellipse_u, mpfitellipse_eval, mpfitellipse, mpfit

; Compute the "u" value = (x/a)^2 + (y/b)^2 with optional rotation
function mpfitellipse_u, x, y, p, tilt=tilt, circle=circle
  COMPILE_OPT strictarr
  widx  = abs(p[0]) > 1e-20 & widy  = abs(p[1]) > 1e-20 
  if keyword_set(circle) then widy  = widx
  xp    = x-p[2]            & yp    = y-p[3]
  theta = p[4]

  if keyword_set(tilt) AND theta NE 0 then begin
      c  = cos(theta) & s  = sin(theta)
      return, ( (xp * (c/widx) - yp * (s/widx))^2 + $
                (xp * (s/widy) + yp * (c/widy))^2 )
  endif else begin
      return, (xp/widx)^2 + (yp/widy)^2
  endelse

end

; This is the call-back function for MPFIT.  It evaluates the
; function, subtracts the data, and returns the residuals.
function mpfitellipse_eval, p, tilt=tilt, circle=circle, _EXTRA=extra

  COMPILE_OPT strictarr
  common mpfitellipse_common, xy, wc

  tilt = keyword_set(tilt) 
  circle = keyword_set(circle)
  u2 = mpfitellipse_u(xy[*,0], xy[*,1], p, tilt=tilt, circle=circle) - 1.

  if n_elements(wc) GT 0 then begin
      if circle then u2 = sqrt(abs(p[0]*p[0]*wc))*u2 $
      else           u2 = sqrt(abs(p[0]*p[1]*wc))*u2 
  endif

  return, u2
end

function mpfitellipse, x, y, p0, WEIGHTS=wts, $
                       BESTNORM=bestnorm, nfev=nfev, STATUS=status, $
                       tilt=tilt, circular=circle, $
                       circle=badcircle1, symmetric=badcircle2, $
                       parinfo=parinfo, query=query, $
                       covar=covar, perror=perror, niter=iter, $
                       quiet=quiet, ERRMSG=errmsg, _EXTRA=extra

  COMPILE_OPT strictarr
  status = 0L
  errmsg = ''

  ;; Detect MPFIT and crash if it was not found
  catch, catcherror
  if catcherror NE 0 then begin
      MPFIT_NOTFOUND:
      catch, /cancel
      message, 'ERROR: the required function MPFIT must be in your IDL path', /info
      return, !values.d_nan
  endif
  if mpfit(/query) NE 1 then goto, MPFIT_NOTFOUND
  catch, /cancel
  if keyword_set(query) then return, 1

  if n_params() EQ 0 then begin
      message, "USAGE: PARMS = MPFITELLIPSE(X, Y, START_PARAMS, ... )", $
        /info
      return, !values.d_nan
  endif
  nx = n_elements(x) & ny = n_elements(y)
  if (nx EQ 0) OR (ny EQ 0) OR (nx NE ny) then begin
      message, 'ERROR: X and Y must have the same number of elements', /info
      return, !values.d_nan
  endif

  if keyword_set(badcircle1) OR keyword_set(badcircle2) then $
    message, 'ERROR: do not use the CIRCLE or SYMMETRIC keywords.  ' +$
    'Use CIRCULAR instead.'

  p = make_array(5, value=x[0]*0)

  if n_elements(p0) GT 0 then begin
      p[0] = p0
      if keyword_set(circle) then p[1] = p[0]
  endif else begin
      mx = moment(x)
      my = moment(y)
      p[0] = [sqrt(mx[1]), sqrt(my[1]), mx[0], my[0], 0]
      if keyword_set(circle) then $
        p[0:1] = sqrt(mx[1]+my[1])
  endelse

  common mpfitellipse_common, xy, wc
  if n_elements(wts) GT 0 then begin
      wc = abs(wts)
  endif else begin
      wc = 0 & dummy = temporary(wc)
  endelse

  xy = [[x],[y]]

  nfev = 0L & dummy = temporary(nfev)
  covar = 0 & dummy = temporary(covar)
  perror = 0 & dummy = temporary(perror)
  status = 0
  result = mpfit('mpfitellipse_eval', p, $
                 parinfo=parinfo, STATUS=status, nfev=nfev, BESTNORM=bestnorm,$
                 covar=covar, perror=perror, niter=iter, $
                 functargs={circle:keyword_set(circle), tilt:keyword_set(tilt)},$
                 ERRMSG=errmsg, quiet=quiet, _EXTRA=extra)

  ;; Print error message if there is one.
  if NOT keyword_set(quiet) AND errmsg NE '' then $
    message, errmsg, /info
  ;; Return if there is an error condition
  if status LE 0 then return, result

  ;; Sanity check on resulting parameters
  if keyword_set(circle) then begin
      result[1] = result[0]
      perror[1] = perror[0]
  endif
  if NOT keyword_set(tilt) then begin
      result[4] = 0
      perror[4] = 0
  endif

  ;; Make sure the axis lengths are positive, and the semi-major axis
  ;; is listed first
  result[0:1] = abs(result[0:1])
  if abs(result[0]) LT abs(result[1]) AND keyword_set(tilt) then begin
      tmp = result[0] & result[0] = result[1] & result[1] = tmp
      tmp = perror[0] & perror[0] = perror[1] & perror[1] = tmp
      result[4] = result[4] - !dpi/2d
  endif

  if keyword_set(tilt) then begin
      ;; Put tilt in the range 0 to +Pi
      result[4] = result[4] - !dpi * floor(result[4]/!dpi)
  endif

  return, result
end



;+
; This function converts a high-res image to a low res image for
; display. The scale parameter is fixed at 1024, but should be
; adjusted to match the display window size.
; 
; :Params:
;    img_in: in, required, type=any
;      This is the input image and must be a 2d array. The data type
;      can be any float type or byte type.
;
;-
function scale_image_for_display, img_in

; scale using first dimension length to preserve aspect ratio
scale  = 768. / n_elements(img_in[0,*])
xscale = n_elements(img_in[*,0]) * scale
yscale = n_elements(img_in[0,*]) * scale

new_img = congrid( img_in, xscale, yscale )

return, new_img
end

;+
; This function reads a PNG or JPG file. It also converts to a 2d
; array to remove color channels and removes 200 pixels around the
; border.
;-
function read_the_image_file, file

edgewidth=200 ; pixels to remove from each side

; figure out file type
extension = strlowcase((strsplit(file,'.',/extract))[-1])

; png
if extension eq 'png' then rawimg=read_png(file)
; jpg or jpeg
if strmid(extension,0,1) eq 'j' then read_jpeg,file,rawimg

img2d=float(rawimg) ; convert to float

; reduce image to just 2 dimensions
if n_elements(size(rawimg,/dim)) gt 2 then begin
   ; find the smallest dimension (rgb) and collapse to grayscale
   dimlength = size( rawimg, /dim )
   smallestlength = min( dimlength, smallestdimloc )
   img2d = total( float(rawimg), smallestdimloc+1 )
endif
print,'read '+file

; mask off the edges
; some images have weird edges, so just mask them off
dims = size(img2d,/dim)
edgemask = fltarr(dims) + 1. ; fill mask with 1, same image dims as img
edgemask[0:edgewidth,*]   = 0. ; remove left edge
edgemask[dims[0]-edgewidth:dims[0]-1,*] = 0. ; remove right edge
edgemask[*,0:edgewidth]   = 0. ; remove top edge
edgemask[*,dims[1]-edgewidth:dims[1]-1] = 0. ; remove bottom edge

img2d *= edgemask ; img2d is already a float so edgemask preserves data type

print,!d.x_size,!d.y_size
if !d.x_size ne 1024 then window,xs=1024,ys=768
tvscl,scale_image_for_display(img2d)

return,img2d
end

;+
; This procedure calculates the x,y centroid of img in pixels
; This assumes there is a bright spot on the image
;-
pro calc_img_cm,img, x, y

xpixdist=findgen(n_elements(img[*,0]))
ypixdist=findgen(n_elements(img[0,*]))

; from bytes values, the saturation value is 765
maxval = max(img)


return
end

;+
; Remove a representative "dark" strip from the whole image.
;-
function remove_background,img

; find a strip that has no saturated pixels
; find nearby representative "dark" rows
dims=size(img,/dim)
rowtot=total(img,1)

strip=median(img[*,dims[1] - 400:dims[1]-200], dim=2) ; make just one row
; now median filter the one row
tmp=median(strip,99) ; this removes most of the grid lines
; replace the large differences from the median, then median filter again
bad=where(abs(strip-tmp) gt 10,n_bad)
newstrip=strip
if n_bad gt 0 then newstrip[bad]=tmp[bad]
newstrip=median(newstrip,99)
stop
newimg=img
for i=0,dims[1]-1 do newimg[*,i] -= newstrip ; could vectorize using reform


return,newimg > 0. ; clip negative values
end

;+
; This calculates a mask where pixels are saturated. All of these
; pixels are expected to lie within the solar disk.
; An optional keyword allows for a mask to be found for some fraction
; of the maximum value.
;-
function get_sat_mask, img, maxf=maxf

if size(maxf,/type) eq 0 then maxf=1.0 ; allow user to define a fraction below saturation

satmask=fltarr(size(img,/dim))
satpix = where(img ge round(max(img))*maxf,n_satpix)
satmask[satpix] = 1.0

tvscl,scale_image_for_display(satmask)

return,satmask
end

;+
;-
pro get_max_min_pixels, satmask, xmins, xmaxs ;, ymins, ymaxs

dims=size(satmask,/dim)
for i=0,dims[1]-1 do begin
   gd=where(satmask[*,i] gt 0.99,n_gd)
   if n_gd gt 0 then begin
      xmins[i]=gd[0]
      xmaxs[i]=gd[n_gd-1]
   endif
endfor
;for i=0,dims[0]-1 do begin
;   gd=where(satmask[i,*] gt 0.99,n_gd)
;   if n_gd gt 0 then begin
;      ymins[i]=gd[0]
;      ymaxs[i]=gd[n_gd-1]
;   endif
;endfor

return
end


;+
; This procedure uses the mask to locate the min/max pairs for each
; row to define a rough ellipse that is then fit. The fit results are
; returned as the center coordinates and the length of the semimajor
; axes. This could be modified to allow for tilt of the ellipse, but
; that seems unecessary.
;-
pro get_sun_ellipse, satmask, center, semix, semiy, filename

dims=size(satmask,/dim)

; find first and last occurrence of mask pixel in each row
xmins=lonarr(dims[0])
xmaxs=xmins
ymins=lonarr(dims[1])
ymaxs=ymins
get_max_min_pixels, satmask, xmins, xmaxs ;, ymins, ymaxs

y1=where(xmins gt 0)
; cat xy coord to pass to mpfitellipse
x=float([xmins[y1],xmaxs[y1]])
y=float([y1,y1])

; try to fit an ellipse
; uncertainties are like 50 pixels in some places so be liberal
r=mpfitellipse(x,y,weights=100.+fltarr(n_elements(x)))
print,'first fit'
rfirst=r
print,rfirst
center=[r[2],r[3]]
semix=r[0]
semiy=r[1]

; calculate the radius of each x,y pair from the centerpoint
rad = sqrt((x-center[0])^2 + (y-center[1])^2)
n_gd=0
scale=1.5
while n_gd lt 150 do begin
  scale *= 0.99 ; creep down in 1% increments
  gd=where(rad gt median(rad,/even)*scale,n_gd) ; keep points larger than median rad
endwhile
xorig=x
yorig=y

x=x[gd]
y=y[gd]
; repeat fit with better data
r=mpfitellipse(x,y,weights=stddev(rad[gd])*2. + fltarr(n_elements(x)))
print,'second fit'
rsecond=r
print,rsecond
center=[r[2],r[3]]
semix=r[0]
semiy=r[1]

; make an image to display showing the ellipse
tmpimg=satmask
tmpimg[x,y]=2. ; color the fit points
; add center
tmpimg[round(center[0]),*]=2.0
tmpimg[*,round(center[1])]=2.0
; add vertial and horizontal lines at ellipse semimajor axis edges
tmpimg[round(center[0]-semix),*]=2.
tmpimg[round(center[0]+semix),*]=2.
tmpimg[*,round(center[1]-semiy)]=2.
tmpimg[*,round(center[1]+semiy)]=2.

; add ellipse
thedist=satmask
x2dist=rebin((findgen(dims[0])-center[0])^2,dims[0],dims[1])
y2dist=rebin(transpose((findgen(dims[1])-center[1])^2),dims[0],dims[1])
thedist=sqrt(x2dist+y2dist)
;; get points within 0.5 pixel radius of semimajor axes
;atrx=where(abs(thedist-semix) lt 0.25,n_atrx)
;if n_atrx gt 0 then tmpimg[atrx] = 3.
;atry=where(abs(thedist-semiy) lt 0.25,n_atry)
;if n_atry gt 0 then tmpimg[atry] = 3.

; calculate the ellipse
for i=long(center[0]-semix),long(center[0]+semix)-1L do begin
   thisx=i
   ; (x-xc)^2/a^2 + (y-yc)^2/b^2 = 1
   ; so (y-yc)^2/b^2 = 1 - (x-xc)^2/a^2
   ; y = sqrt(b^2*(1 - (x-xc)^2/a^2)) + yc
   posy=sqrt(semiy^2 * (1.d - ((thisx-center[0])^2 / semix^2) )>0. )
   thispy=posy + center[1]
   thisny=(-1.*posy) + center[1]
   tmpimg[i,round(thispy)]=2.
   tmpimg[i,round(thisny)]=2.
endfor

;stop

; show just the sun part
tmpimg=tmpimg[center[0]-semix-20:center[0]+semix+20, center[1]-semiy-20:center[1]+semiy+20]

tvscl,scale_image_for_display(tmpimg)
; label center pixel
!p.charsize=2
xyouts,50,50,file_basename(filename),/dev,color='fe00'x
xyouts,50,80,'suncenterpixels = ( '+strtrim(r[2],2)+', '+strtrim(r[3],2)+' )',/dev,color='fe00'x
; label semix
xyouts,50,110,'ecc='+strtrim(abs(r[1]-r[0])/(r[0]+r[1]),2)+' semimajor = '+strtrim(r[0],2)+', '+strtrim(r[1],2),/dev

stop

return
end

;+
; Calculate the pixel scale in x and y using the AU factor from the
; EVE/EXIS annual file. Should be updated for each alignment day.
; The xscale and yscale have units of arcmin/pixel.
;-
pro get_pixel_scale, semix, semiy, xscale, yscale

; get 1au for date 2018-06-07, changes by about 0.0003 per day (decreasing)
inv_au = 0.97128257992d0 ; lookup the 1/au^2 correction from the yearly file
solar_diameter_arcmin = 32.0d * inv_au
; the sun is further away in june so the au correction is less than 1
; the apparent diameter is smaller than at 1-au

xscale = solar_diameter_arcmin / (2.d*semix)
yscale = solar_diameter_arcmin / (2.d*semiy)

return
end

;+
; Find the grid center in pixels.
;-
pro get_grid_ref_center, img, xctr, yctr, filename, sunctr, semix, semiy

dims=size(img,/dim)
;tvscl,scale_image_for_display(img[sunctr[0]-semix:sunctr[0]+semix,sunctr[1]-semiy:sunctr[1]+semiy])
tvscl,scale_image_for_display(img)

; assume the grid center is near the sun center
; large grid lines show deeper lines, one of these is the reference center
; mask out everything beyond 3 semimajor axis lengths
mask=fltarr(dims)
mask[sunctr[0]-semix*3:sunctr[0]+semix*3,sunctr[1]-semiy*3:sunctr[1]+semiy*3]=1
xsum=total(img*mask,2)
ysum=total(img*mask,1)

distx = sqrt((dindgen(dims[0])-sunctr[0])^2)
disty = sqrt((dindgen(dims[1])-sunctr[1])^2)

; find minimum within 0.5*semix at sunctr[0]
xhalf = 0.5*semix
yhalf = 0.5*semiy
junk = min(xsum[round(sunctr[0] - xhalf):round(sunctr[0] + xhalf)],xloc)
xctr = xloc + round((sunctr[0] - xhalf))

junk = min(ysum[round(sunctr[1] - yhalf):round(sunctr[1] + yhalf)],yloc)
yctr = yloc + round(sunctr[1] - yhalf)

tmpimg=img
tmpimg[xctr-2L+lindgen(5),*]=max(tmpimg)
tmpimg[*,yctr-2L+lindgen(5)]=max(tmpimg)

tvscl,scale_image_for_display(tmpimg[sunctr[0]-semix*3:sunctr[0]+semix*3,sunctr[1]-semiy*3:sunctr[1]+semiy*3])

;stop
return
end


;+
; This is the main procedure. It is inspired by the email from Tom
; Woods below.
; The analysis goal is to get the relative offset in arc-minutes
; between ROS and LISS in both Yaw (X) and Pitch (Y).
; That is, Offset = (ROS_image_center - ROSS_grid_center) * ROS_scale  $
; -  (LISS_image_center - LISS_grid_center) * LISS_scale
; The "center" values are in units of pixels.  
; The "scale" values are in units of arc-min per pixel.
; The scale values (which could be different for X and Y directions) 
; can be determined by:
; XXX_scale = solar_diameter_in_arcmin  /  XXX_image_diameter_in_pixels
; The solar diameter of image is smeared by the size of the pinhole
; aperture but image diameter ~50% edge points will still be the 
; solar diameter =  32.0 arc-min / D_au
; where D_au is Earth-Sun distance in units of AU.
;-
pro calculate_rocket_center

;file=dialog_pickfile(path='~/Downloads/darktable_exported',
;filter=['*.jpg','*.JPG','*.jpeg','*.png'])

; png files are created from Toms JPG files using the darktable programs
; perspective correction that orthogonalized the grid
lissfile='~/Downloads/darktable_exported/LISS_set2_post-vibe_IMG_5348.jpg'
lissimg=read_the_image_file(lissfile)

rosfile='~/Downloads/darktable_exported/ROS_set2_IMG_5354.jpg'
rosimg=read_the_image_file(rosfile)

; the ros image has almost 90% solar signal far away from the sun
; so set the maxf to 0.9, this is the fraction of saturation to define
; the edge of the sun
lisssatmask90 = get_sat_mask(lissimg,maxf=.9)
rossatmask90  = get_sat_mask(rosimg, maxf=.9)

; convert saturation mask to a sun mask to estimate diameter in pixels
get_sun_ellipse, lisssatmask90, lisscenter, lisssemix, lisssemiy, lissfile
get_sun_ellipse,  rossatmask90,  roscenter,  rossemix,  rossemiy,  rosfile

; get pixel scale using semimajor axes
get_pixel_scale, lisssemix, lisssemiy, lissxscale, lissyscale
get_pixel_scale,  rossemix,  rossemiy,  rosxscale,  rosyscale

; get the grid reference center pixel, trying to find the pinhole
get_grid_ref_center, lissimg, lissgridxctr, lissgridyctr, lissfile, lisscenter, lisssemix, lisssemiy
get_grid_ref_center,  rosimg,  rosgridxctr,  rosgridyctr,  rosfile,  roscenter, rossemix,   rossemiy

print,'LISS grid ref center (pix)=',lissgridxctr, lissgridyctr
print,'LISS suncenter (pix)=',lisscenter
print,'LISS scale (arcmin/pix)=',lissxscale, lissyscale
print,''
print,'ROS grid ref center (pix)=',rosgridxctr, rosgridyctr
print,'ROS suncenter (pix)=',roscenter
print,'ROS scale (arcmin/pix)=',rosxscale, rosyscale

; calculate the offsets
xoffset=(roscenter[0] - rosgridxctr)*rosxscale - $
        (lisscenter[0] - lissgridxctr)*lissxscale
yoffset=(roscenter[1] - rosgridyctr)*rosyscale - $
        (lisscenter[1] - lissgridyctr)*lissyscale

print,''
print,'ROS to LISS Offsets'
print,'Yaw (arcmin) = ',xoffset
print,'Pitch (arcmin) = ',yoffset
stop


stop
return
end
