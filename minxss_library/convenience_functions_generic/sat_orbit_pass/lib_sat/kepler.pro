pro findc2c3,psi,c2=c2,c3=c3
  eps=ed-6
  if psi gt eps then begin
    c2=(1-cos(sqrt(psi)))/psi
    c3=(sqrt(psi)-sin(psi))/sqrt(psi^3)
  end else if psi lt -eps then begin
    c2=(1-cosh(sqrt(-psi)))/psi
    c3=(sinh(sqrt(-psi))-sqrt(-psi))/sqrt((-psi)^3)
  end else begin
    c2=0.5d
    c3=1d/6d
  end
end

;; ------------------------------------------------------------------------------
;;
;;                           function kepler
;;
;;  this function solves keplers problem for orbit determination and returns a
;;    future geocentric equatorial (ijk) position and velocity vector.  the
;;    solution uses universal variables.
;;
;;  author        : david vallado                  719-573-2600   22 jun 2002
;;
;;  revisions
;;    vallado     - fix some mistakes                             13 apr 2004
;;
;;  inputs          description                    range / units
;;    ro          - ijk position vector - initial  km
;;    vo          - ijk velocity vector - initial  km / s
;;    dtsec       - length of time to propagate    s
;;
;;  outputs       :
;;    r           - ijk position vector            km
;;    v           - ijk velocity vector            km / s
;;    error       - error flag                     'ok', $
;;
;;  locals        :
;;    f           - f expression
;;    g           - g expression
;;    fdot        - f dotp_grid expression
;;    gdot        - g dotp_grid expression
;;    xold        - old universal variable x
;;    xoldsqrd    - xold squared
;;    xnew        - new universal variable x
;;    xnewsqrd    - xnew squared
;;    znew        - new value of z
;;    c2new       - c2(psi) function
;;    c3new       - c3(psi) function
;;    dtsec       - change in time                 s
;;    timenew     - new time                       s
;;    rdotv       - result of ro dotp_grid vo
;;    a           - semi or axis                   km
;;    alpha       - reciprocol  1/a
;;    sme         - specific mech energy           km2 / s2
;;    period      - time period for satellite      s
;;    s           - variable for parabolic case
;;    w           - variable for parabolic case
;;    h           - angular momentum vector
;;    temp        - temporary real*8 value
;;    i           - index
;;
;;  coupling      :
;;    vlength         - vlengthnitude of a vector
;;    findc2c3    - find c2 and c3 functions
;;
;;  references    :
;;    vallado       2004, 95-103, alg 8, ex 2-4
;;
;; [r,v] =  kepler  ( ro,vo, dtsec );
;; ------------------------------------------------------------------------------

;;function [r,v] =  kepler  ( ro,vo, dtseco );
;function [r,v,errork] =  kepler  ( ro,vo, dtseco, fid );
pro kepler,ro,vo,dtseco,fid,r=r,v=v,errork=errork

        ; -------------------------  implementation   -----------------
        ; set constants and intermediate printouts
;        constmath;
        small = 1d-8;

        infinite  = 999999.9d;
        undefined = 999999.1d;

        ; -------------------------  mathematical  --------------------
        rad    = 180.0d / !dpi;
        twopi  = 2.0d * !dpi;
        halfpi = !dpi * 0.5d;

        ; -------------------------  conversions  ---------------------
        ft2m    =    0.3048d;
        mile2m  = 1609.344d;
        nm2m    = 1852d;
        mile2ft = 5280d;
        mileph2kmph = 0.44704d;
        nmph2kmph   = 0.5144444d;

;        constastro;
;        ; -----------------------  physical constants  ----------------
;        ; WGS-84/EGM-96 constants used here
        re         = 6378.137d;         ;; km
        flat       = 1.0d/298.257223563d;
        omegaearth = 7.292115d-11;     ;; rad/s
        mu         = 398600.4418d;      ;; km3/s2
        mum        = 3.986004418d14;   ;; m3/s2

        ; derived constants from the base values
        eccearth = sqrt(2.0d*flat - flat^2);
        eccearthsqrd = eccearth^2;

        renm = re / nm2m;
        reft = re * 1000.0d / ft2m;

        tusec = sqrt(re^3/mu);
        tumin = tusec / 60.0d;
        tuday = tusec / 86400.0d;

        omegaearthradptu  = omegaearth * tusec;
        omegaearthradpmin = omegaearth * 60.0d;

        velkmps = sqrt(mu / re);
        velftps = velkmps * 1000.0d/ft2m;
        velradpmin = velkmps * 60.0d/re;
;;for afspc
;;velkmps1 = velradpmin*6378.135/60.0   7.90537051051763
;;mu1 = velkmps*velkmps*6378.135        3.986003602567418e+005        
        degpsec = (180.0d / !dpi) / tusec;
        radpday = 2.0 * !dpi * 1.002737909350795d;

        speedoflight = 2.99792458d8; ; m/s
        au = 149597870.0d;      ; km
        earth2moon = 384400.0d; ; km
        moonradius =   1738.0d; ; km
        sunradius  = 696000.0d; ; km

        masssun   = 1.9891d30;
        massearth = 5.9742d24;
        massmoon  = 7.3483d22;


show = 'n';
        numiter    =    50;
        
        if show eq 'y' then begin
            print,string(format='(%" ro %16.8f %16.8f %16.8f ER ")',ro/re );
            print,string(format='(%" vo %16.8f %16.8f %16.8f ER/TU ")',vo/velkmps );
          end

        ; --------------------  initialize values   -------------------
        ktr   = 0;
        xold  = 0.0d;
        znew  = 0.0d;
        errork = '      ok'; 
        dtsec = dtseco;
        mulrev = 0;
        
        if ( abs( dtseco ) gt small ) then begin
            vlengthro = vlength( ro );
            vlengthvo = vlength( vo );
            rdotv= dotp_grid( ro,vo );

            ; -------------  find sme, alpha, and a  ------------------
            sme= ( (vlengthvo^2)*0.5  ) - ( mu /vlengthro );
            alpha= -sme*2.0/mu;

            if ( abs( sme ) gt small ) then begin
                a= -mu / ( 2.0 *sme );
            end else begin
                a= infinite;
            end
            if ( abs( alpha ) lt small ) then begin  ; parabola
                alpha= 0.0;
              end

            if show eq 'y' then begin
                print,string(format='(%" sme %16.8f  a %16.8f alp  %16.8f ER ")',sme/(mu/re), a/re, alpha*re );
                print,string(format='(%" sme %16.8f  a %16.8f alp  %16.8f km ")',sme, a, alpha );
                print," ktr      xn        psi           r          xn+1        dtn ";
              end

            ; ------------   setup initial guess for x  ---------------
            ; -----------------  circle and ellipse -------------------
            if ( alpha ge small ) then begin
                period= twopi * sqrt( abs(a)^3.0/mu  );
                ; ------- next if needed for 2body multi-rev ----------
                if ( abs( dtseco ) gt abs( period ) ) then begin
; including the truncation will produce vertical lines that are parallel
; (plotting chi vs time)
;                    dtsec = rem( dtseco,period );
                    mulrev = floor(dtseco/period);
                end;
                if ( abs(alpha-1.0 ) gt small ) then begin
                     xold = sqrt(mu)*dtsec * alpha;
                end else begin
                     ; - first guess can't be too close. ie a circle, r=a
                     xold = sqrt(mu) * dtsec * alpha * 0.97;
                  end
              end else begin
                ; --------------------  parabola  ---------------------
                if ( abs( alpha ) lt small ) then begin
                    h = crossp_grid( ro,vo );
                    vlengthh = vlength(h);
                    p= vlengthh*vlengthh/mu;
                    s= 0.5  * (halfpi - datan( 3.0 *sqrt( mu / (p*p*p) )* dtsec ) );
                    w= atan( tan( s )^(1.0 /3.0 ) );
                    xold = sqrt(p) * ( 2.0 *cot(2.0 *w) );
                    alpha= 0.0;
                end else begin
                    ; ------------------  hyperbola  ------------------
                    temp= -2.0 * mu * dtsec / $
                          ( a*( rdotv + sign(dtsec)*sqrt(-mu*a)* $
                          (1.0 -vlengthro*alpha) ) );
                    xold= sign(dtsec) * sqrt(-a) *log(temp);
                  end

              end

            ktr= 1;
            dtnew = -10.0;
            while ((abs(dtnew/sqrt(mu) - dtsec) ge small) and (ktr lt numiter)) do begin
                xoldsqrd = xold*xold;
                znew     = xoldsqrd * alpha;

                ; ------------- find c2 and c3 functions --------------
                findc2c3, znew,c2new,c3new;

                ; ------- use a newton iteration for new values -------
                rval = xoldsqrd*c2new + rdotv/sqrt(mu) *xold*(1.0 -znew*c3new) + $
                         vlengthro*( 1.0  - znew*c2new );
                dtnew= xoldsqrd*xold*c3new + rdotv/sqrt(mu)*xoldsqrd*c2new + $
                         vlengthro*xold*( 1.0  - znew*c3new );

                ; ------------- calculate new value for x -------------
                xnew = xold + ( dtsec*sqrt(mu) - dtnew ) / rval;

               ; ------------------------------------------------------
               ; check if the orbit is an ellipse and xnew > 2!dpi sqrt(a), the step
               ; size must be changed.  this is accomplished by multiplying rval
               ; by 10.0 .  note that 10.0  is arbitrary, but seems to produce good
               ; results.  the idea is to keep xnew from increasing too rapidily.
               ; ------------------------------------------------------
;  including this doesn't work if you don't mod the dtsec
;               if ( ( a > 0.0  ) and ( abs(xnew)>twopi*sqrt(a) ) and ( sme < 0.0  ) )
;                   dx= ( dtsec-dtnew ) / rval  ; *7.0   * 10.0
;                   xnew = xold + dx / 7.0    ; /(1.0  + dx)
;                alternate method to test various values of change
;                   xnew = xold + ( dtsec-dtnew ) / ( rval*10 chgamt  )
;                 end

               if show eq 'y' then begin
                   print,string(format='(%"%3i %11.7f %11.7f %11.7f %11.7f %11.7f ")', $
                          ktr,xold,znew,rval,xnew,dtnew);                      
                   print,string(format='(%"%3i %11.7f %11.7f %11.7f %11.7f %11.7f ")', $
                          ktr,xold/sqrt(re),znew,rval/re,xnew/sqrt(re),dtnew/sqrt(mu));
                 end

                ktr = ktr + 1;
                xold = xnew;
              end

            if ( ktr >= numiter ) then begin
                errork= 'knotconv';
                print,string(format='(%"not converged in %2i iterations ")',numiter );
                r=[0d,0,0]
                v=[0d,0,0]
            end else begin
                ; --- find position and velocity vectors at new time --
                xnewsqrd = xnew*xnew;
                f = 1.0d  - ( xnewsqrd*c2new / vlengthro );
                g = dtsec - xnewsqrd*xnew*c3new/sqrt(mu);

                r=f*ro+g*vo
                vlengthr = vlength( r );
                gdot = 1.0  - ( xnewsqrd*c2new / vlengthr );
                fdot = ( sqrt(mu)*xnew / ( vlengthro*vlengthr ) ) * ( znew*c3new-1.0  );
                v=fdot*ro+gdot*vo
                temp= f*gdot - fdot*g;
                if ( abs(temp-1.0 ) gt 0.00001  ) then begin
                    errork= 'fandg';
                end

                if show eq 'y' then begin
                    print,string(format='(%"f %16.8f g %16.8f fdot %16.8f gdot %16.8f ")',f, g, fdot, gdot );
                    print,string(format='(%"f %16.8f g %16.8f fdot %16.8f gdot %16.8f ")',f, g/tusec, fdot*tusec, gdot );
                    print,string(format='(%"r1 %16.8f %16.8f %16.8f ER ")',r/re );
                    print,string(format='(%"v1 %16.8f %16.8f %16.8f ER/TU ")',v/velkmps );
                  end
              end  ; if
          end else begin
                                ; ----------- set vectors to incoming
                                ;             since 0 time --------
            r=ro
            v=vo
          end
            
;       fprintf( fid,';11.5f  ;11.5f ;11.5f  ;5i ;3i ',znew, dtseco/60.0, xold/(rad), ktr, mulrev );

                  
                  

end
