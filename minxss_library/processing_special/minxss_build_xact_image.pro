;+
; NAME:
;	minxss_build_xact_image.pro
;
; PURPOSE:
;	Build an image from XACT Star Tracker using MinXSS image packets
;	If the image packets are from multiple ISIS tlm files, then call this procedure multiple times
;	with the same image
;
; CATEGORY:
;	Analysis only (not used in data processing)
;
; CALLING SEQUENCE:
;	minxss_build_xact_image, image_packets, image, /first
;
; INPUTS:
;	image_packets	XACT Image packets returned from minxss_read_packets
;	image			output image is also input image if multiple calls are done
;	/first			option to initialize the image as this is first call
;
; OUTPUTS:
;	image			1344 x 1024 image from combining all of the image_packets
;					Value of -1 means no data found for that pixel in image_packets
;					Image is intarr() because XACT ST data is just 10-bits per pixel.
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;   1. Make image (if necessary)
;	2. Loop through image_packets and fill in values into image
;
; MODIFICATION HISTORY:
;   01-26-2015    C. Moore, T. Woods      Original code
;
;
;+
pro  minxss_build_xact_image, image_packets, image, first=first, verbose=verbose

;
;	check input
;
if n_params() lt 2 then begin
  print, 'USAGE: minxss_build_xact_image, image_packets, image, /first'
  return
endif

;
;	Setup some defines
;
N_COLUMNS = 1344
N_ROWS = 1024
EMPTY_PIXEL_VALUE = -1

N_WORDS_PER_GROUP = 32
N_PIXELS_PER_WORD = 3
N_BYTES_PER_WORD = 4
N_PIXELS_PER_GROUP = 96   ; = 32 * 3

count_max = long(N_COLUMNS)*long(N_ROWS)
count = 0L
count_repeat = 0L
count_diff = 0L

;
;   1. Make image (if necessary)
;
if (n_elements(image) lt count_max) or keyword_set(first) then begin
  image = INTARR(N_COLUMNS, N_ROWS) + EMPTY_PIXEL_VALUE
endif

;
;	2. Loop through image_packets and fill in values into image
;		image_packets.image_row  =   0-1023 in lower 12-bits and image number in top 4-bits
;		image_packets.row_group  =   0-13 with each group is for 96 pixels
;		image_packets.image_data =   bytarr(128) that has 96 pixels
;									3-Pixels are stuffed into lower part of 32-bit word
;									each pixel has 10-bits and 32-bit word is Big endian
;
N_PACKETS = n_elements(image_packets)

row = image_packets.image_row AND '0FFF'X
image_num = ishft( image_packets.image_row AND 'F000'X, -12 )
first_num = -1
column1 = image_packets.row_group * N_PIXELS_PER_GROUP  ; first column in image_packet

for k=0L,N_PACKETS-1 do begin
  ; only use image_packets with valid image number
  if (image_num[k] gt 0) and (first_num lt 0) then first_num = image_num[k]

  if (image_num[k] eq first_num) then begin
    ; extract out 3 pixels from every 4-byte word: 10-bits per pixel using Big endian 4-byte words
    for j=0, N_WORDS_PER_GROUP-1 do begin
      count += 3L
      col = column1[k] + j*N_PIXELS_PER_WORD
      ;  Pixel 1 of 3
      temp = fix(image_packets[k].image_data[j*N_BYTES_PER_WORD + 3]) + $
      		ishft(fix(image_packets[k].image_data[j*N_BYTES_PER_WORD + 2]) AND '03'X, 8)
      if (image[col + 0, row[k]] ne EMPTY_PIXEL_VALUE) then begin
        count_repeat += 1L
        if (image[col + 0, row[k]] ne temp) then begin
          count_diff += 1L
          image[col + 0, row[k]] = temp
        endif
      endif else image[col + 0, row[k]] = temp
      ;  Pixel 2 of 3
      temp = ishft(fix(image_packets[k].image_data[j*N_BYTES_PER_WORD + 2]) AND 'FC'X,-2) + $
      		ishft(fix(image_packets[k].image_data[j*N_BYTES_PER_WORD + 1]) AND '0F'X, 6)
      if (image[col + 1, row[k]] ne EMPTY_PIXEL_VALUE) then begin
        count_repeat += 1L
        if (image[col + 1, row[k]] ne temp) then begin
          count_diff += 1L
          image[col + 1, row[k]] = temp
        endif
      endif else image[col + 1, row[k]] = temp
      ;  Pixel 3 of 3
      temp = ishft(fix(image_packets[k].image_data[j*N_BYTES_PER_WORD + 1]) AND 'F0'X,-4) + $
      		ishft(fix(image_packets[k].image_data[j*N_BYTES_PER_WORD + 0]) AND '3F'X, 4)
      if (image[col + 2, row[k]] ne EMPTY_PIXEL_VALUE) then begin
        count_repeat += 1L
        if (image[col + 2, row[k]] ne temp) then begin
          count_diff += 1L
          image[col + 2, row[k]] = temp
        endif
      endif else image[col + 2, row[k]] = temp
    endfor
  endif

endfor

if keyword_set(verbose) then begin
  print, 'minxss_build_xact_image:  image # ', strtrim(first_num,2)
  print, '                          ', strtrim(count,2), ' pixels added to the image (', $
  	string(count*100./float(count_max),format='(F6.2)') + '%)'
  print, '                          ', strtrim(count_repeat,2), ' pixels repeated in the image (', $
  	string(count_repeat*100./float(count_max),format='(F6.2)') + '%)'
  print, '                          ', strtrim(count_diff,2), $
  	' pixels repeated and different in the image (', $
  	string(count_diff*100./float(count_max),format='(F6.2)') + '%)'
  ; stop, 'DEBUG ...'
endif

return
end
