  function days,date1,date2

; Returns the number of days elapsed between two dates of the
; form yyyyddd.dd.
;
; B. G. Knapp, 1987-02-04, 1997-11-17
;
; RCS Data:
;
; $Header: /home/betelgeuse/knapp/idllib/RCS/days.pro,v 1.1 1999/12/03 18:37:44 knapp Exp $
;
; $Log: days.pro,v $
; Revision 1.1  1999/12/03 18:37:44  knapp
; Initial revision
;
  if n_params() lt 2 then begin
      print,"                                                              "
      print,"  DAYS requires two arguments representing dates in the form  "
      print,"  yyyyddd.dd. It returns the number of days between the two   "
      print,"  dates.  A positive number of days will be returned if the   "
      print,"  first argument represents an earlier date than the second.  "
      print,"                                                              "
      print,"  ndays = days(date1,date2)                                   "
      return,"                                                              "
  endif
;
  return,dyd(date1,date2)
;
  end
