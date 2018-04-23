;+
; NAME:
;   JPMColors
;
; PURPOSE:
;   Get the string name for a color by passing in an index. Useful for plot function e.g. p = plot(findgen(10), color = JPMColors(i))
;
; INPUTS:
;   Index [int]: An integer value less than 149
;
; OPTIONAL INPUTS:
;   totalPointsForGradient: The number of points across a gradient to use. Maximum number is 90. 
;                           Colors are shaded from violet, red, orange, yellow, green, blue based on this webpage: 
;                           http://web-tech.ga-usa.com/2012/05/creating-a-custom-hot-to-cold-temperature-color-gradient-for-use-with-rrdtool/
;
; KEYWORD PARAMETERS:
;   SIMPLE:            Get 10 basic colors: black, red, green, blue, magenta, orange, blue violet, saddle brown, cyan, yellow green
;   GREENS:            Get 16 different shades of green
;   RETURN_COLORTABLE: Set this to return the colortable array rather than the single index color
;   
; OUTPUTS:
;   colorString [string]: A string containing the name of an IDL 8 color
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   FOR i = 0, 148 DO p = plot([0,1], [i, i], COLOR = JPMColors(i), THICK = 5, /OVERPLOT, YRANGE = [-1, i+1])
;
; MODIFICATION HISTORY:
;     2013-02-25: James Paul Mason: Wrote script
;     2016-03-19: James Paul Mason: Added totalPointsForGradient optional input. 
;     2018-04-14: James Paul Mason: Added RETURN_COLORTABLE keyword. 
;-
FUNCTION JPMColors, index, totalPointsForGradient = totalPointsForGradient, $
                    SIMPLE = SIMPLE, GREENS = GREENS, RETURN_COLORTABLE = RETURN_COLORTABLE

IF index GE 149 THEN BEGIN 
  message, /INFO, 'Please specify an index < 149 for a color other than black. '
  return, 'Black'
ENDIF

; Default color palette
colors = ['alice_blue','antique_white','aqua','aquamarine','azure','beige','bisque','black','blanched_almond','blue','blue_violet','brown',$
          'burlywood','cadet_blue','chartreuse','chocolate','coral','cornflower','cornsilk','crimson','cyan','dark_blue','dark_cyan','dark_goldenrod',$
          'dark_gray','dark_grey','dark_green','dark_khaki','dark_magenta','dark_olive_green','dark_orange','dark_orchid','dark_red','dark_salmon',$
          'dark_sea_green','dark_slate_blue','dark_slate_gray','dark_slate_grey','dark_turquoise','dark_violet','deep_pink','deep_sky_blue','dim_gray',$
          'dim_grey','dodger_blue','firebrick','floral_white','forest_green','fuchsia','gainsboro','ghost_white','gold','goldenrod','gray','grey','green',$
          'green_yellow','gray','honeydew','hot_pink','indian_red','indigo','ivory','khaki','lavender','lavender_blush','lawn_green','lemon_chiffon',$
          'light_blue','light_coral','light_cyan','light_goldenrod','light_gray','light_green','light_gray','light_grey','light_pink','light_salmon',$
          'light_sea_green','light_sky_blue','light_slate_gray','light_slate_grey','light_steel_blue','light_yellow','lime','lime_green','linen','magenta',$
          'maroon','medium_aquamarine','medium_blue','medium_orchid','medium_purple','medium_sea_green','medium_slate_blue','medium_spring_green',$
          'medium_turquoise','medium_violet_red','midnight_blue','mint_cream','misty_rose','moccasin','navajo_white','navy','old_lace','olive','olive_drab',$
          'orange','orange_red','orchid','pale_goldenrod','pale_green','pale_turquoise','pale_violet_red','papaya_whip','peach_puff','peru','pink','plum',$
          'powder_blue','purple','red','rosy_brown','royal_blue','saddle_brown','salmon','sandy_brown','sea_green','seashell','sienna','silver','sky_blue',$
          'slate_blue','slate_gray','slate_grey','snow','spring_green','steel_blue','tan','teal','thistle','tomato','turquoise','violet','wheat','white',$
          'white_smoke','yellow','yellow_green']

IF keyword_set(SIMPLE) THEN colors =  ['black', 'red', 'green', 'blue', 'magenta', 'orange', 'blue_violet', 'saddle_brown', 'cyan', 'yellow_green']

IF keyword_set(GREENS) THEN colors =  ['dark_green', 'dark_sea_green', 'forest_green', 'green_yellow', 'green', 'lawn_green', 'dark_olive_green', 'light_green', 'light_sea_green', $
                                       'lime_green', 'medium_sea_green', 'medium_spring_green', 'pale_green', 'sea_green', 'spring_green', 'yellow_green']

; Specified as RGB vectors in this case
IF totalPointsForGradient NE !NULL THEN BEGIN
  allColors = [[ 255,14,240], [ 255,13,240], [ 255,12,240], [ 255,11,240], [ 255,10,240], [ 255,9,240], [ 255,8,240], [ 255,7,240], [ 255,6,240], [ 255,5,240], $
               [ 255,4,240], [ 255,3,240], [ 255,2,240], [ 255,1,240], [ 255,0,240], [ 255,0,224], [ 255,0,208], [ 255,0,192], [ 255,0,176], [ 255,0,160], $
               [ 255,0,144], [ 255,0,128], [ 255,0,112], [ 255,0,96], [ 255,0,80], [ 255,0,64], [ 255,0,48], [ 255,0,32], [ 255,0,16], [ 255,0,0], [ 255,10,0], $
               [ 255,20,0], [ 255,30,0], [ 255,40,0], [ 255,50,0], [ 255,60,0], [ 255,70,0], [ 255,80,0], [ 255,90,0], [ 255,100,0], [ 255,110,0], [ 255,120,0], $
               [ 255,130,0], [ 255,140,0], [ 255,150,0], [ 255,160,0], [ 255,170,0], [ 255,180,0], [ 255,190,0], [ 255,200,0], [ 255,210,0], [ 255,220,0], $
               [ 255,230,0], [ 255,240,0], [ 255,250,0], [ 253,255,0], [ 215,255,0], [ 176,255,0], [ 138,255,0], [ 101,255,0], [ 62,255,0], [ 23,255,0], $
               [ 0,255,16], [ 0,255,54], [ 0,255,92], [ 0,255,131], [ 0,255,168], [ 0,255,208], [ 0,255,244], [ 0,228,255], [ 0,212,255], [ 0,196,255], $
               [ 0,180,255], [ 0,164,255], [ 0,148,255], [ 0,132,255], [ 0,116,255], [ 0,100,255], [ 0,84,255], [ 0,68,255], [ 0,50,255], [ 0,34,255], $
               [ 0,18,255], [ 0,2,255], [ 0,0,255], [ 1,0,255], [ 2,0,255], [ 3,0,255], [ 4,0,255], [ 5,0,255]]
  
  ; Step through allColors with spacing sufficiently large to stretch the whole palett with number of points = totalPointsForGradient
  spacing = ceil((n_elements(allColors) / 3 ) / totalPointsForGradient)

  ; IDL doens't treat allColors as an array of arrays, it's just one long array so have to regenerate the 3 element RGB array for output
  startIndex = index * 3 * spacing < 267
  
  IF keyword_set(RETURN_COLORTABLE) THEN BEGIN
    return, allColors[*, 0:(n_elements(allColors[0, *]) - 1):spacing]
  ENDIF
  
  return, allColors[startIndex: startIndex + 2]
ENDIF

IF keyword_set(RETURN_COLORTABLE) THEN BEGIN
  return, allColors
ENDIF

return, colors[index]

END