function load_tle,infn,sort=do_sort,no_filter=no_filter
  openr,inf,infn,/get_lun
  line0=''
  line1=''
  while ~eof(inf) do begin
    line2=''
    readf,inf,line2
    if strlen(line1) gt 0 && strmid(line1,0,1) eq '1' && strlen(line2) gt 0 && strmid(line2,0,1) eq '2' then begin
      if n_elements(lines1) eq 0 then begin
        lines0=line0
        lines1=line1
        lines2=line2
      end else begin
        lines0=[lines0,line0]
        lines1=[lines1,line1]
        lines2=[lines2,line2]
      end
      line0=''
      line1=''
      line2=''
    end
    line0=line1
    line1=line2
  end
  free_lun,inf
  result=parse_tle_struct(lines1,lines2,line0=lines0)
  if keyword_set(do_sort) or ~keyword_set(no_filter) then begin
    s=sort(result[*].jdepoch)
    result=result[s]
  end
  if ~keyword_set(no_filter) then filter_tle,result
  return,result
end
