  function udtf_convert_type, udtf, success
;
; Convert a UARS Date/Time format timetag from a structure type to an
; an array type, or vice-versa.
;
; B. Knapp, 98.09.25
;
  info = size( udtf )
  if info[n_elements( info )-2] eq 8 then begin
;
;    Convert from structure to array
     success = n_tags( udtf ) eq 2
     if success then begin
        tnames = tag_names( udtf )
        success = tnames[0] eq 'YEAR_DAY' and tnames[1] eq 'MILLISEC'
     endif
     if success then $
        return, transpose( [[udtf.year_day],[udtf.millisec]] ) $
     else $
        return, [0l,0l]
;
  endif else begin
;
;    Convert from array to structure
     case info[0] of
        1:begin
           success = info[1] eq 2
           if success then $
              return,{ year_day:long(udtf[0]), millisec:long(udtf[1]) } $
           else $
              return,{ year_day:0l, millisec:0l }
          end

        2:begin
           result = replicate( { year_day:0l, millisec:0l }, info[2] )
           success = info[1] eq 2
           if success then begin
              result.year_day = (udtf[0,*])[*]
              result.millisec = (udtf[1,*])[*]
           endif
           return, result
          end

        else:$
          begin
           success = 0 eq 1
           return,{ year_day:0l, millisec:0l }
          end
     endcase
  endelse
;
  end