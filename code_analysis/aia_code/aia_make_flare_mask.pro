;
;	aia_make_flare_mask.pro
;
;	AIA Analysis Code
;	-----------------
;
;	Purpose:  	Identify flare region in AIA images and return mask image
;
;	Input:  	imdata		image data structure from aia_cutout_read.pro
;
;	Options:	/level		Specify level for flare intensity (relative 0-1 to Maximum) [default is 0.7]
;				/diff		Option to subtract off first image so examining change since start time
;				/loud		Print information and do plot of mask
;
;	Output:		mask_data	Data structure that includes:
;								mask = mask image of flare region - same size as imdata.image
;										0 = non-flaring and 1 = flare region
;								outline = image with outline of mask identified - same size as imdata.image
;								ts_time = SOD
;								ts_mask = signal of just mask area
;								ts_full = signal of full image
;
;	Plot:		Image showing mask / outline if /loud is given
;
;	History:	1/15/11  	T. Woods, original code
;

function aia_make_flare_mask, imdata, level=level, diff=diff, loud=loud

  ;
  ;  check inputs
  ;
  num_im = (size(imdata))[1]
  im_center = num_im/2L
  if (n_params() lt 1) or (num_im lt 1) then begin
     print, 'USAGE:  image_mask = aia_make_flare_mask( imdata [, level=level, /loud, outline=outline] '
     return, -1
  endif

  flare_level = 0.7   ; note that 0.7 is factor of 2 lower than Maximum as use alog( image )
  if keyword_set(level) then flare_level = float(level[0])
  if (flare_level lt 0.05) then flare_level = 0.05
  if (flare_level gt 0.95) then flare_level = 0.95
  
  ;
  ;  make image mask based on level from maximum
  ;
  image_mask = imdata[0].image - imdata[0].image 	; same size image but with 0.0 values
  
  for k=0L,num_im-1 do begin
    if keyword_set(diff) then imlog = alog((imdata[k].image - imdata[0].image) > 1) $
    else imlog = alog(imdata[k].image > 1)
    immax = max(imlog) > alog(2.)
    if (k eq im_center) then begin
      implot = imlog  ; keep center image for plot
      implotmax = immax
    endif
    whigh = where( imlog gt (flare_level*immax), numhigh )
    if (numhigh gt 1) then image_mask[whigh] += 1
  endfor
  
  ;
  ;  now make the outline image using image at center of time range 
  ;	 and making the edges at the maximum level
  ;
  outline = implot
  imsize = size(implot)
  for i=1L,imsize[1]-2 do begin
    for j=1L, imsize[2]-2 do begin
      if (image_mask[i,j] gt 0) and ((image_mask[i-1,j] eq 0) or (image_mask[i+1,j] eq 0) $
               or (image_mask[i,j-1] eq 0) or (image_mask[i,j+1] eq 0)) then begin
        outline[i,j]=implotmax
      endif
    endfor
  endfor

  ;
  ;  make the mask_data structure
  ;
  mask_data = { mask: image_mask, outline: outline, ts_time: fltarr(num_im), ts_mask: fltarr(num_im), ts_full: fltarr(num_im) }
  wmask = where( image_mask gt 0, nummask )
  for k=0L,num_im-1 do begin
    mask_data.ts_time[k] = imdata[k].sod
    mask_data.ts_full[k] = total(imdata[k].image)
    if (nummask gt 1) then mask_data.ts_mask[k] = total(imdata[k].image[wmask])
  endfor
  
  ;
  ;  plot the image mask result
  ;
  if keyword_set(loud) then begin
     print, 'Number of Mask Pixels = ', strtrim(nummask,2)
     tvscl, outline
  endif
  
  return, mask_data
end
