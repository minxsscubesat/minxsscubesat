;
;	bar.pro
;	User symbol for plotting that is a bar (rectangle)
;
;	10/1/2022  T. Woods
;
pro bars, width, height

if n_params() lt 2 then height = 11	; setup up default values
if n_params() lt 1 then width = 5

;	reduce width, height of "pixel" to "character" size as needed for usersym.pro
width /= 5.
height /= 5.

xbar = [ -1.*width/2.,width/2.,width/2., -1.*width/2., -1.*width/2. ]
ybar = [ -1.*height/2.,-1.*height/2.,height/2., height/2., -1.*height/2. ]

usersym, xbar, ybar, /fill

return
end
