pro resolve_grid,vv,x=x,y=y,z=z,w=w,v=v,u=u,t=t,s=s,n_dimension_vec=n_dimension_vec  
  ss=size(vv,/dim)
  ndims=n_elements(ss)-1
  n_dimension_vec=ss[ndims]
  ;Column vector exception
  if ndims eq 1 and ss[0] eq 1 then ndims--
  case ndims of
    -1: begin
          message,"Must pass a vector or grid of vectors"
          return
        end
    0:  begin
          if n_dimension_vec ge 1 then x=vv[0];
          if n_dimension_vec ge 2 then y=vv[1];
          if n_dimension_vec ge 3 then z=vv[2];
          if n_dimension_vec ge 4 then w=vv[3];
          if n_dimension_vec ge 5 then v=vv[4];
          if n_dimension_vec ge 6 then u=vv[5];
          if n_dimension_vec ge 7 then t=vv[6];
          if n_dimension_vec ge 8 then s=vv[7];
        end
    1:  begin
          if n_dimension_vec ge 1 then x=vv[*,0];
          if n_dimension_vec ge 2 then y=vv[*,1];
          if n_dimension_vec ge 3 then z=vv[*,2];
          if n_dimension_vec ge 4 then w=vv[*,3];
          if n_dimension_vec ge 5 then v=vv[*,4];
          if n_dimension_vec ge 6 then u=vv[*,5];
          if n_dimension_vec ge 7 then t=vv[*,6];
          if n_dimension_vec ge 8 then s=vv[*,7];
        end
    2:  begin
          if n_dimension_vec ge 1 then x=vv[*,*,0];
          if n_dimension_vec ge 2 then y=vv[*,*,1];
          if n_dimension_vec ge 3 then z=vv[*,*,2];
          if n_dimension_vec ge 4 then w=vv[*,*,3];
          if n_dimension_vec ge 5 then v=vv[*,*,4];
          if n_dimension_vec ge 6 then u=vv[*,*,5];
          if n_dimension_vec ge 7 then t=vv[*,*,6];
          if n_dimension_vec ge 8 then s=vv[*,*,7];
        end
    3:  begin
          if n_dimension_vec ge 1 then x=vv[*,*,*,0];
          if n_dimension_vec ge 2 then y=vv[*,*,*,1];
          if n_dimension_vec ge 3 then z=vv[*,*,*,2];
          if n_dimension_vec ge 4 then w=vv[*,*,*,3];
          if n_dimension_vec ge 5 then v=vv[*,*,*,4];
          if n_dimension_vec ge 6 then u=vv[*,*,*,5];
          if n_dimension_vec ge 7 then t=vv[*,*,*,6];
          if n_dimension_vec ge 8 then s=vv[*,*,*,7];
        end
    4:  begin
          if n_dimension_vec ge 1 then x=vv[*,*,*,*,0];
          if n_dimension_vec ge 2 then y=vv[*,*,*,*,1];
          if n_dimension_vec ge 3 then z=vv[*,*,*,*,2];
          if n_dimension_vec ge 4 then w=vv[*,*,*,*,3];
          if n_dimension_vec ge 5 then v=vv[*,*,*,*,4];
          if n_dimension_vec ge 6 then u=vv[*,*,*,*,5];
          if n_dimension_vec ge 7 then t=vv[*,*,*,*,6];
          if n_dimension_vec ge 8 then s=vv[*,*,*,*,7];
        end
    5:  begin
          if n_dimension_vec ge 1 then x=vv[*,*,*,*,*,0];
          if n_dimension_vec ge 2 then y=vv[*,*,*,*,*,1];
          if n_dimension_vec ge 3 then z=vv[*,*,*,*,*,2];
          if n_dimension_vec ge 4 then w=vv[*,*,*,*,*,3];
          if n_dimension_vec ge 5 then v=vv[*,*,*,*,*,4];
          if n_dimension_vec ge 6 then u=vv[*,*,*,*,*,5];
          if n_dimension_vec ge 7 then t=vv[*,*,*,*,*,6];
          if n_dimension_vec ge 8 then s=vv[*,*,*,*,*,7];
        end
    6:  begin
          if n_dimension_vec ge 1 then x=vv[*,*,*,*,*,*,0];
          if n_dimension_vec ge 2 then y=vv[*,*,*,*,*,*,1];
          if n_dimension_vec ge 3 then z=vv[*,*,*,*,*,*,2];
          if n_dimension_vec ge 4 then w=vv[*,*,*,*,*,*,3];
          if n_dimension_vec ge 5 then v=vv[*,*,*,*,*,*,4];
          if n_dimension_vec ge 6 then u=vv[*,*,*,*,*,*,5];
          if n_dimension_vec ge 7 then t=vv[*,*,*,*,*,*,6];
          if n_dimension_vec ge 8 then s=vv[*,*,*,*,*,*,7];
        end
    7:  begin
          if n_dimension_vec ge 1 then x=vv[*,*,*,*,*,*,*,0];
          if n_dimension_vec ge 2 then y=vv[*,*,*,*,*,*,*,1];
          if n_dimension_vec ge 3 then z=vv[*,*,*,*,*,*,*,2];
          if n_dimension_vec ge 4 then w=vv[*,*,*,*,*,*,*,3];
          if n_dimension_vec ge 5 then v=vv[*,*,*,*,*,*,*,4];
          if n_dimension_vec ge 6 then u=vv[*,*,*,*,*,*,*,5];
          if n_dimension_vec ge 7 then t=vv[*,*,*,*,*,*,*,6];
          if n_dimension_vec ge 8 then s=vv[*,*,*,*,*,*,*,7];
        end
    else: begin
          message,"Unsupported grid dimension"
        end
  endcase

end
