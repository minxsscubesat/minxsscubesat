function plotrange, x, log = log, margin = margin

  if not keyword_set(margin) then margin = 0.025
  if (n_elements(x) gt 1) then begin
    range = [min(x), max(x)]
    if keyword_set(log) then range = alog10(range)
    range = range + ([-1,1] * margin * (range[1] - range[0]))
    return, keyword_set(log) ? 10^range : range
  endif else return, x * [1 - margin, 1 + margin]
  
end