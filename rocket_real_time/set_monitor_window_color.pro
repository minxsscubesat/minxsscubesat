pro set_monitor_window_color, textobjarray, color=color

if color eq !NULL then color='purple' ;default to stale color
for i=0,n_elements(textobjarray)-1 do textobjarray[i].font_color = color

return
end
