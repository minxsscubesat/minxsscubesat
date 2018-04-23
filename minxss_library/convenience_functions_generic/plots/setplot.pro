;  
;	setplot.pro
;
;	Set plot font, thickness, and background
;
;	Default values are:
;		font = 'Helvetica Bold'
;		fsize = font size
;		thick = 2
;		and  /black is NOT set
;
;	Tom Woods	11/20/03
;
pro  setplot, font=font, fsize=fsize, thick=thick, black=black

;
;  Set FONT
;
if not keyword_set(font) then font = 'Helvetica'
if not keyword_set(fsize) then fsize=9
!p.font = 1
if (!d.name eq 'PS') then begin
  device, set_font=font, font_size=fsize, /TT_FONT
endif else begin
  device, set_font=font, /TT_FONT
endelse

;
; Set THICKNESS
;
if not keyword_set(thick) then thick=2.
if (!d.name eq 'PS') then tfactor=3. else tfactor=1.
!p.thick=thick * tfactor
!x.thick=thick * tfactor
!y.thick=thick * tfactor
!z.thick=thick * tfactor
!p.charthick = thick + 0.5
!p.charsize = thick + 0.5

;
; Set Background Color
;
if keyword_set(black) then begin
  !p.color = '00FFFFFF'X	; white
  !p.background = 0		; black
endif else begin
  !p.background = '00FFFFFF'X	; white
  !p.color = 0			; black
endelse

return
end
