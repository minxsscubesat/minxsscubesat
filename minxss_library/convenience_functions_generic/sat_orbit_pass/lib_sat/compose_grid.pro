;A Grid is a multidimensional array of vectors. It is inconvenient to talk about
;an array of things which themselves are arrays, so it'ss a grid.
;
;A grid of vectors can have any number of dimensions, but the last dimension
;is the vector component index. So, a grid would typically look like v[i,j,3].
;Even though this is a 3D array, it is only a 2D grid of vectors.
;
;A grid can have any number of dimensions, but if more than three are needed, this function
;and resolve_grid will need to be extended.
;
;This function takes three arrays of scalars of the same size and shape, and builds a grid
;of vectors with the same size and shape. Each input array becomes one vector component.
function compose_grid,x,y,z,w,v,u,t,s
  ndims=size(x,/n_dimensions)
  ss=0
  if n_elements(x) gt 0 then ss+=1
  if n_elements(y) gt 0 then ss+=1
  if n_elements(z) gt 0 then ss+=1
  if n_elements(w) gt 0 then ss+=1
  if n_elements(v) gt 0 then ss+=1
  if n_elements(u) gt 0 then ss+=1
  if n_elements(t) gt 0 then ss+=1
  if(ndims gt 0) then begin
    result=make_array([size(x,/dimensions),ss],type=size(x,/type));
  end else begin
    result=make_array(ss,type=size(x,/type));
  end
  case ndims of
    0:  begin
          if ss ge 1 then result[0]=x;
          if ss ge 2 then result[1]=y;
          if ss ge 3 then result[2]=z;
          if ss ge 4 then result[3]=w;
          if ss ge 5 then result[4]=v;
          if ss ge 6 then result[5]=u;
          if ss ge 7 then result[6]=t;
          if ss ge 8 then result[7]=s;
        end
    1:  begin
          if ss ge 1 then result[*,0]=x;
          if ss ge 2 then result[*,1]=y;
          if ss ge 3 then result[*,2]=z;
          if ss ge 4 then result[*,3]=w;
          if ss ge 5 then result[*,4]=v;
          if ss ge 6 then result[*,5]=u;
          if ss ge 7 then result[*,6]=t;
          if ss ge 8 then result[*,7]=s;
        end
    2:  begin
          if ss ge 1 then result[*,*,0]=x;
          if ss ge 2 then result[*,*,1]=y;
          if ss ge 3 then result[*,*,2]=z;
          if ss ge 4 then result[*,*,3]=w;
          if ss ge 5 then result[*,*,4]=v;
          if ss ge 6 then result[*,*,5]=u;
          if ss ge 7 then result[*,*,6]=t;
          if ss ge 8 then result[*,*,7]=s;
        end
    3:  begin
          if ss ge 1 then result[*,*,*,0]=x;
          if ss ge 2 then result[*,*,*,1]=y;
          if ss ge 3 then result[*,*,*,2]=z;
          if ss ge 4 then result[*,*,*,3]=w;
          if ss ge 5 then result[*,*,*,4]=v;
          if ss ge 6 then result[*,*,*,5]=u;
          if ss ge 7 then result[*,*,*,6]=t;
          if ss ge 8 then result[*,*,*,7]=s;
        end
    4:  begin
          if ss ge 1 then result[*,*,*,*,0]=x;
          if ss ge 2 then result[*,*,*,*,1]=y;
          if ss ge 3 then result[*,*,*,*,2]=z;
          if ss ge 4 then result[*,*,*,*,3]=w;
          if ss ge 5 then result[*,*,*,*,4]=v;
          if ss ge 6 then result[*,*,*,*,5]=u;
          if ss ge 7 then result[*,*,*,*,6]=t;
          if ss ge 8 then result[*,*,*,*,7]=s;
        end
    5:  begin
          if ss ge 1 then result[*,*,*,*,*,0]=x;
          if ss ge 2 then result[*,*,*,*,*,1]=y;
          if ss ge 3 then result[*,*,*,*,*,2]=z;
          if ss ge 4 then result[*,*,*,*,*,3]=w;
          if ss ge 5 then result[*,*,*,*,*,4]=v;
          if ss ge 6 then result[*,*,*,*,*,5]=u;
          if ss ge 7 then result[*,*,*,*,*,6]=t;
          if ss ge 8 then result[*,*,*,*,*,7]=s;
        end
    6:  begin
          if ss ge 1 then result[*,*,*,*,*,*,0]=x;
          if ss ge 2 then result[*,*,*,*,*,*,1]=y;
          if ss ge 3 then result[*,*,*,*,*,*,2]=z;
          if ss ge 4 then result[*,*,*,*,*,*,3]=w;
          if ss ge 5 then result[*,*,*,*,*,*,4]=v;
          if ss ge 6 then result[*,*,*,*,*,*,5]=u;
          if ss ge 7 then result[*,*,*,*,*,*,6]=t;
          if ss ge 8 then result[*,*,*,*,*,*,7]=s;
        end
    7:  begin
          if ss ge 1 then result[*,*,*,*,*,*,*,0]=x;
          if ss ge 2 then result[*,*,*,*,*,*,*,1]=y;
          if ss ge 3 then result[*,*,*,*,*,*,*,2]=z;
          if ss ge 4 then result[*,*,*,*,*,*,*,3]=w;
          if ss ge 5 then result[*,*,*,*,*,*,*,4]=v;
          if ss ge 6 then result[*,*,*,*,*,*,*,5]=u;
          if ss ge 7 then result[*,*,*,*,*,*,*,6]=t;
          if ss ge 8 then result[*,*,*,*,*,*,*,7]=s;
        end
    else: begin
          print,"Unsupported grid dimension"
          return,-1
        end
  endcase
  return,result
end
