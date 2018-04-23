;This system used to be fully object-oriented using the full-blown ::
;notation. Unfortunately under IDL, real object-orientation means
;pointers, heap variables, and all the headaches and garbage that comes
;with it. So, we do fake object orientation. We have an sgp4core__define
;which defines a structure, but we don't define methods for it, and
;we don't use obj_new to instantiate it, just {sgp4core}. This way
;it doesn't have to be a heap variable.
function pow,a,b
  return,a^b
end

pro sgp4core_init,tle
  tle.msgp4.radiusearthkm=6378.135d
  tle.msgp4.mu=398600.8d
;  tle.msgp4.xke=60.0d / sqrt(tle.msgp4.radiusearthkm*tle.msgp4.radiusearthkm*tle.msgp4.radiusearthkm/tle.msgp4.mu);
  tle.msgp4.xke=0.743669161D-1;
  tle.msgp4.tumin=1.0d/tle.msgp4.xke;
  tle.msgp4.j2=0.001082616d;
  tle.msgp4.j3=-0.00000253881d;
  tle.msgp4.j4=-0.00000165597d;
  tle.msgp4.j3oj2=tle.msgp4.j3/tle.msgp4.j2;
  xpdotp =  1440.0d / (2.0d * !DPI);  // 229.1831180523293
  tle.msgp4.error = 0;
  tle.msgp4.bstar=TLE.bstar;

  tle.msgp4.ecco=TLE.ecco;

  ;// ---- convert to sgp4 units ----
  tle.msgp4.no   = TLE.no / xpdotp; // * rad/min
  tle.msgp4.a    = pow( TLE.no*tle.msgp4.tumin, (-2.0d/3.0d) );

  ;  // ---- find standard orbital elements ----
  tle.msgp4.inclo = TLE.inclo*!DPI/180d;
  tle.msgp4.nodeo = TLE.nodeo*!DPI/180d;
  tle.msgp4.argpo = TLE.argpo*!DPI/180d;
  tle.msgp4.mo    = TLE.mo*!DPI/180d;


  tle.msgp4.jdsatepoch=yd2jd(TLE.ydepoch);
  epoch=tle.msgp4.jdsatepoch-2433281.5d

  ;old sgp4core::init
       ; --------------------- local variables ------------------------ */
    ;double ao, con42, cosio, sinio, cosio2, eccsq,
    ;omeosq, posq,   rp,     rteosq,
    ; cosim , sinim , cc1sq ,
    ;cc2   , cc3   , coef  , coef1 , cosio4,
    ;em    , emsq  , eeta  , etasq , argpm , nodem ,
    ;inclm , mm    , nm    , perige, pinvsq, psisq , qzms24,
    ;s1    , s2    , s3    , s4    , s5    ,
    ;sfour , ss1   , ss2   , ss3   , ss4   , ss5   ,
    ;sz1   , sz3   , sz11  ,
    ;sz13  , sz21  , sz23  , sz31  , sz33  ,
    ;tc    , temp  , temp1 , temp2 , temp3 , tsi   , xpidot,
    ;xhdot1, z1    , z3    , z11   , z13   ,
    ;z21   , z23   , z31   , z33,
    ;qzms2t, ss,  x2o3;
    r=dblarr(3);
    v=dblarr(3);

       ;/* ------------------------ initialization --------------------- */
       ;// sgp4fix divisor for divide by zero check on inclination
       temp4    =   1.0d + cos(!DPI-1.0d-9);

       ;/* ----------- set all near earth variables to zero ------------ */
       tle.msgp4.isimp   = 0&   tle.msgp4.isdeep=0& tle.msgp4.aycof    = 0.0d
       tle.msgp4.con41   = 0.0d& tle.msgp4.cc1    = 0.0d& tle.msgp4.cc4      = 0.0d
       tle.msgp4.cc5     = 0.0d& tle.msgp4.d2     = 0.0d& tle.msgp4.d3       = 0.0d
       tle.msgp4.d4      = 0.0d& tle.msgp4.delmo  = 0.0d& tle.msgp4.eta      = 0.0d
       tle.msgp4.argpdot = 0.0d& tle.msgp4.omgcof = 0.0d& tle.msgp4.sinmao   = 0.0d
       tle.msgp4.t2cof  = 0.0d& tle.msgp4.t3cof    = 0.0d
       tle.msgp4.t4cof   = 0.0d& tle.msgp4.t5cof  = 0.0d& tle.msgp4.x1mth2   = 0.0d
       tle.msgp4.x7thm1  = 0.0d& tle.msgp4.mdot   = 0.0d& tle.msgp4.nodedot  = 0.0d
       tle.msgp4.xlcof   = 0.0d& tle.msgp4.xmcof  = 0.0d& tle.msgp4.nodecf   = 0.0d

       ;/* ----------- set all deep space variables to zero ------------ */
       tle.msgp4.irez  = 0&   tle.msgp4.d2201 = 0.0d& tle.msgp4.d2211 = 0.0d
       tle.msgp4.d3210 = 0.0d& tle.msgp4.d3222 = 0.0d& tle.msgp4.d4410 = 0.0d
       tle.msgp4.d4422 = 0.0d& tle.msgp4.d5220 = 0.0d& tle.msgp4.d5232 = 0.0d
       tle.msgp4.d5421 = 0.0d& tle.msgp4.d5433 = 0.0d& tle.msgp4.dedt  = 0.0d
       tle.msgp4.del1  = 0.0d& tle.msgp4.del2  = 0.0d& tle.msgp4.del3  = 0.0d
       tle.msgp4.didt  = 0.0d& tle.msgp4.dmdt  = 0.0d& tle.msgp4.dnodt = 0.0d
       tle.msgp4.domdt = 0.0d& tle.msgp4.e3    = 0.0d& tle.msgp4.ee2   = 0.0d
       tle.msgp4.peo   = 0.0d& tle.msgp4.pgho  = 0.0d& tle.msgp4.pho   = 0.0d
       tle.msgp4.pinco = 0.0d& tle.msgp4.plo   = 0.0d& tle.msgp4.se2   = 0.0d
       tle.msgp4.se3   = 0.0d& tle.msgp4.sgh2  = 0.0d& tle.msgp4.sgh3  = 0.0d
       tle.msgp4.sgh4  = 0.0d& tle.msgp4.sh2   = 0.0d& tle.msgp4.sh3   = 0.0d
       tle.msgp4.si2   = 0.0d& tle.msgp4.si3   = 0.0d& tle.msgp4.sl2   = 0.0d
       tle.msgp4.sl3   = 0.0d& tle.msgp4.sl4   = 0.0d& tle.msgp4.gsto  = 0.0d
       tle.msgp4.xfact = 0.0d& tle.msgp4.xgh2  = 0.0d& tle.msgp4.xgh3  = 0.0d
       tle.msgp4.xgh4  = 0.0d& tle.msgp4.xh2   = 0.0d& tle.msgp4.xh3   = 0.0d
       tle.msgp4.xi2   = 0.0d& tle.msgp4.xi3   = 0.0d& tle.msgp4.xl2   = 0.0d
       tle.msgp4.xl3   = 0.0d& tle.msgp4.xl4   = 0.0d& tle.msgp4.xlamo = 0.0d
       tle.msgp4.zmol  = 0.0d& tle.msgp4.zmos  = 0.0d

       ;* ------------------------ earth constants ----------------------- */
       ;/ sgp4fix identify constants and allow alternate values
       ss     = 78.0d / tle.msgp4.radiusearthkm + 1.0d;
       qzms2t = pow(((120.0d - 78.0d) / tle.msgp4.radiusearthkm), 4.0d);
       x2o3   =  2.0d / 3.0d;


       ;* body of initl function (only used here) */
       ;double ak, d1, del, adel, po;

       ;* ------------- calculate auxillary epoch quantities ---------- */
       eccsq  = tle.msgp4.ecco * tle.msgp4.ecco;
       omeosq = 1.0d - eccsq;
       rteosq = sqrt(omeosq);
       cosio  = cos(tle.msgp4.inclo);
       cosio2 = cosio * cosio;

       ;* ------------------ un-kozai the mean motion ----------------- */
       ak    = pow(tle.msgp4.xke / tle.msgp4.no, x2o3);
       d1    = 0.75d * tle.msgp4.j2 * (3.0d * cosio2 - 1.0d) / (rteosq * omeosq);
       del   = d1 / (ak * ak);
       adel  = ak * (1.0d - del * del - del * $
               (1.0d / 3.0d + 134.0d * del * del / 81.0d));
       del   = d1/(adel * adel);
       tle.msgp4.no    = tle.msgp4.no / (1.0d + del);

       ao    = pow(tle.msgp4.xke / tle.msgp4.no,x2o3);
       sinio = sin(tle.msgp4.inclo);
       po    = ao * omeosq;
       con42 = 1.0d - 5.0d * cosio2;
       tle.msgp4.con41 = -con42-cosio2-cosio2;
       posq  = po * po;
       rp    = ao * (1.0d - tle.msgp4.ecco);
       tle.msgp4.isdeep=0;

       tle.msgp4.gsto = gstime(epoch + 2433281.5d);
       ;* end of initl function */
         tle.msgp4.error = 0;

       if (rp lt 1.0d) then begin
           print,"# *** epoch elts sub-orbital ***";
           tle.msgp4.error = 5;
       end

       if ((omeosq ge 0.0d ) || ( tle.msgp4.no ge 0.0d)) then begin
           tle.msgp4.isimp = 0;
           if (rp lt (220.0d / tle.msgp4.radiusearthkm + 1.0d)) then tle.msgp4.isimp = 1;
           sfour  = ss;
           qzms24 = qzms2t;
           perige = (rp - 1.0d) * tle.msgp4.radiusearthkm;

           ; - for perigees below 156 km, s and qoms2t are altered - */
           if (perige lt 156.0d) then begin
             sfour = perige - 78.0d;
             if (perige lt 98.0d) then sfour = 20.0d;
             qzms24 = pow(((120.0d - sfour) / tle.msgp4.radiusearthkm), 4.0d);
             sfour  = sfour / tle.msgp4.radiusearthkm + 1.0d;
           end
           pinvsq = 1.0d / posq;

           tsi  = 1.0d / (ao - sfour);
           tle.msgp4.eta  = ao * tle.msgp4.ecco * tsi;
           etasq = tle.msgp4.eta * tle.msgp4.eta;
           eeta  = tle.msgp4.ecco * tle.msgp4.eta;
           psisq = abs(1.0d - etasq);
           coef  = qzms24 * pow(tsi, 4.0d);
           coef1 = coef / pow(psisq, 3.5d);
           cc2   = coef1 * tle.msgp4.no * (ao * (1.0d + 1.5d * etasq + eeta * $
                          (4.0d + etasq)) + 0.375d * tle.msgp4.j2 * tsi / psisq * tle.msgp4.con41 * $
                          (8.0d + 3.0d * etasq * (8.0d + etasq)));
           tle.msgp4.cc1   = tle.msgp4.bstar * cc2;
           cc3   = 0.0d;
           if (tle.msgp4.ecco gt 1.0d-4) then cc3 = -2.0d * coef * tsi * tle.msgp4.j3oj2 * tle.msgp4.no * sinio / tle.msgp4.ecco;
           tle.msgp4.x1mth2 = 1.0d - cosio2;
           tle.msgp4.cc4    = 2.0* tle.msgp4.no * coef1 * ao * omeosq * $
                             (tle.msgp4.eta * (2.0d + 0.5d * etasq) + tle.msgp4.ecco * $
                             (0.5d + 2.0d * etasq) - tle.msgp4.j2 * tsi / (ao * psisq) * $
                             (-3.0d * tle.msgp4.con41 * (1.0d - 2.0d * eeta + etasq * $
                             (1.5 - 0.5d * eeta)) + 0.75d * tle.msgp4.x1mth2 * $
                             (2.0d * etasq - eeta * (1.0d + etasq)) * cos(2.0d * tle.msgp4.argpo)));
           tle.msgp4.cc5 = 2.0d * coef1 * ao * omeosq * (1.0d + 2.75d * $
                          (etasq + eeta) + eeta * etasq);
           cosio4 = cosio2 * cosio2;
           temp1  = 1.5d * tle.msgp4.j2 * pinvsq * tle.msgp4.no;
           temp2  = 0.5d * temp1 * tle.msgp4.j2 * pinvsq;
           temp3  = -0.46875d *tle.msgp4.j4 * pinvsq * pinvsq * tle.msgp4.no;
           tle.msgp4.mdot     = tle.msgp4.no + 0.5d * temp1 * rteosq * tle.msgp4.con41 + 0.0625d * $
                              temp2 * rteosq * (13.0d - 78.0d * cosio2 + 137.0d * cosio4);
           tle.msgp4.argpdot  = -0.5d * temp1 * con42 + 0.0625d * temp2 * $
                               (7.0d - 114.0d * cosio2 + 395.0d * cosio4) + $
                               temp3 * (3.0d - 36.0d * cosio2 + 49.0d * cosio4);
           xhdot1            = -temp1 * cosio;
           tle.msgp4.nodedot = xhdot1 + (0.5d * temp2 * (4.0d - 19.0d * cosio2) + $
                                2.0d * temp3 * (3.0d - 7.0d * cosio2)) * cosio;
           xpidot            =  tle.msgp4.argpdot+ tle.msgp4.nodedot;
           tle.msgp4.omgcof   = tle.msgp4.bstar * cc3 * cos(tle.msgp4.argpo);
           tle.msgp4.xmcof    = 0.0d;
           if (tle.msgp4.ecco gt 1.0d-4) then tle.msgp4.xmcof = -x2o3 * coef * tle.msgp4.bstar / eeta;
           tle.msgp4.nodecf = 3.5d * omeosq * xhdot1 * tle.msgp4.cc1;
           tle.msgp4.t2cof   = 1.5d * tle.msgp4.cc1;
           ;/ sgp4fix for divide by zero with xinco = 180 deg
           if (abs(cosio+1.0d) gt 1.5d-12) then begin
             tle.msgp4.xlcof = -0.25d * tle.msgp4.j3oj2 * sinio * (3.0d + 5.0d * cosio) / (1.0d + cosio);
           end else begin
             tle.msgp4.xlcof = -0.25d * tle.msgp4.j3oj2 * sinio * (3.0d + 5.0d * cosio) / temp4;
           end
           tle.msgp4.aycof   = -0.5d * tle.msgp4.j3oj2 * sinio;
           tle.msgp4.delmo   = pow((1.0d + tle.msgp4.eta * cos(tle.msgp4.mo)), 3);
           tle.msgp4.sinmao  = sin(tle.msgp4.mo);
           tle.msgp4.x7thm1  = 7.0d * cosio2 - 1.0d;

           ;* --------------- deep space initialization ------------- */
           if ((2*!DPI / tle.msgp4.no) ge 225.0d) then begin
             tle.msgp4.isdeep=1;
             tle.msgp4.isimp  = 1;
             tc    =  0.0;
             inclm = tle.msgp4.inclo;
             dsc_r={dscom_return};

             sgp4core_dscom,tle,epoch, tc, dsc_r;
             em=dsc_r.em;
             nm=dsc_r.nm;

             argpm  = 0.0;
             nodem  = 0.0;
             mm     = 0.0;
             dsi_r={dsinit_return};
             dsi_r.em=em;
             dsi_r.argpm=argpm;
             dsi_r.inclm=inclm;
             dsi_r.mm=mm;
             dsi_r.nm=nm;
             dsi_r.nodem=nodem;

             sgp4core_dsinit,tle,dsc_r, tc, xpidot,eccsq, dsi_r;
             em=dsi_r.em;
             argpm=dsi_r.argpm;
             inclm=dsi_r.inclm;
             mm=dsi_r.mm;
             nm=dsi_r.nm;
             nodem=dsi_r.nodem;
             end

         ;* ----------- set variables if not deep space ----------- */
         if (tle.msgp4.isimp ne 1) then begin
             cc1sq          = tle.msgp4.cc1 * tle.msgp4.cc1;
             tle.msgp4.d2    = 4.0d * ao * tsi * cc1sq;
             temp           = tle.msgp4.d2 * tsi * tle.msgp4.cc1 / 3.0d;
             tle.msgp4.d3    = (17.0d * ao + sfour) * temp;
             tle.msgp4.d4    = 0.5d * temp * ao * tsi * (221.0d * ao + 31.0d * sfour) * tle.msgp4.cc1;
             tle.msgp4.t3cof = tle.msgp4.d2 + 2.0d * cc1sq;
             tle.msgp4.t4cof = 0.25 * (3.0d * tle.msgp4.d3 + tle.msgp4.cc1 * (12.0d * tle.msgp4.d2 + 10.0d * cc1sq));
             tle.msgp4.t5cof = 0.2d * (3.0d * tle.msgp4.d4 + $
                              12.0d * tle.msgp4.cc1 * tle.msgp4.d3 + $
                              6.0d * tle.msgp4.d2 * tle.msgp4.d2 +   $
                              15.0d * cc1sq * (2.0d * tle.msgp4.d2 + cc1sq));
         end
       end ;/ if omeosq = 0 ...
  tle.msgp4.init=1
end  ;/ end sgp4init

pro sgp4core_sgp4,tle,tsince,r,v,error=error
  if ~tle.msgp4.init then sgp4core_init,tle
;      double am   , axnl  , aynl , betal ,  cosim , cnod  ,
;          cos2u, coseo1, cosi , cosip ,  cosisq, cossu , cosu,
;          delm , delomg, em   , emsq  ,  ecose , el2   , eo1 ,
;          ep   , esine , argpm, argpp ,  argpdf, pl,     mrt = 0.0,
;          mvt  , rdotl , rl   , rvdot ,  rvdotl, sinim ,
;          sin2u, sineo1, sini , sinip ,  sinsu , sinu  ,
;          snod , su    , t2   , t3    ,  t4    , tem5  , temp,
;          temp1, temp2 , tempa, tempe ,  templ , u     , ux  ,
;          uy   , uz    , vx   , vy    ,  vz    , inclm , mm  ,
;          nm   , nodem, xinc , xincp ,  xl    , xlm   , mp  ,
;          xmdf , xmx   , xmy  , nodedf, xnode , nodep, tc  ,
;          twopi, x2o3  ,
;          vkmpersec;
;      int ktr;
       error=intarr(n_elements(tsince))
       ;/* ------------------ set mathematical constants --------------- */
       ;// sgp4fix divisor for divide by zero check on inclination
       temp4    =   1.0d + cos(!DPI-1.0e-9);
       twopi = 2.0d * !DPI;
       x2o3  = 2.0d / 3.0d;
       ;// sgp4fix identify constants and allow alternate values
       vkmpersec     = tle.msgp4.radiusearthkm * tle.msgp4.xke/60.0d;

       ;/* --------------------- clear sgp4 error flag ----------------- */
       tle.msgp4.error = 0;

       ;/* ------- update for secular gravity and atmospheric drag ----- */
       xmdf    = tle.msgp4.mo + tle.msgp4.mdot * tsince;
       argpdf  = tle.msgp4.argpo + tle.msgp4.argpdot * tsince;
       nodedf  = tle.msgp4.nodeo + tle.msgp4.nodedot * tsince;
       argpm   = argpdf;
       mm      = xmdf;
       t2      = tsince * tsince;
       nodem   = nodedf + tle.msgp4.nodecf * t2;
       tempa   = 1.0d - tle.msgp4.cc1 * tsince;
       tempe   = tle.msgp4.bstar * tle.msgp4.cc4 * tsince;
       templ   = tle.msgp4.t2cof * t2;

       if (tle.msgp4.isimp ne 1) then begin
           delomg = tle.msgp4.omgcof * tsince;
           delm   = tle.msgp4.xmcof * $
                    (pow((1.0d + tle.msgp4.eta * cos(xmdf)), 3d) - tle.msgp4.delmo);
           temp   = delomg + delm;
           mm     = xmdf + temp;
           argpm  = argpdf - temp;
           t3     = t2 * tsince;
           t4     = t3 * tsince;
           tempa  = tempa - tle.msgp4.d2 * t2 - tle.msgp4.d3 * t3 - $
                            tle.msgp4.d4 * t4;
           tempe  = tempe + tle.msgp4.bstar * tle.msgp4.cc5 * (sin(mm) - $
                            tle.msgp4.sinmao);
           templ  = templ + tle.msgp4.t3cof * t3 + t4 * (tle.msgp4.t4cof + $
                            tsince * tle.msgp4.t5cof);
         end

       nm    = tsince*0d +tle.msgp4.no;
       em    = tsince*0d +tle.msgp4.ecco;
       inclm = tsince*0d +tle.msgp4.inclo;
       if (tle.msgp4.isdeep) then begin
         for i=0,n_elements(tsince)-1 do begin
           ds_r={dspace_return};
           ds_r.em=em[i];
           ds_r.argpm=argpm[i];
           ds_r.inclm=inclm[i];
           ds_r.mm=mm[i];
           ds_r.nodem=nodem[i];
           ds_r.nm=nm[i];
           sgp4core_dspace,tle,tsince[i],ds_r;
           em[i]=ds_r.em;
           argpm[i]=ds_r.argpm;
           inclm[i]=ds_r.inclm;
           mm[i]=ds_r.mm;
           nodem[i]=ds_r.nodem;
           nm[i]=ds_r.nm;
         end
       end ;// if method = d

       w=where(nm le 0.0d,count)
       if count gt 0 then error[w]=2;
       ratio=(tle.msgp4.xke / nm);
       power=pow(ratio,x2o3);
       am = power * tempa * tempa;
       nm = tle.msgp4.xke / pow(am, 1.5d);
       em = em - tempe;

       ;// fix tolerance for error recognition
       w=where(logical_or(logical_or(em ge 1.0d,em lt -0.001d),(am lt 0.95d)),count)
       if count gt 0 then  begin
;//      printf("# error em %f\n", em);
         error[w]=1;
       end
       w=where((em lt 0.0d),count)
       if count gt 0 then em[w]  = 1.0d-6;
       mm     = mm + tle.msgp4.no * templ;
       xlm    = mm + argpm + nodem;
       emsq   = em * em;
       temp   = 1.0d - emsq;

       nodem  = (nodem) mod (twopi);
       argpm  = (argpm) mod (twopi);
       xlm    = (xlm) mod (twopi);
       mm     = (xlm - argpm - nodem) mod (twopi);

       ;/* ----------------- compute extra mean quantities ------------- */
       sinim = sin(inclm);
       cosim = cos(inclm);

       ;/* -------------------- add lunar-solar periodics -------------- */
       ep     = em;
       xincp  = inclm;
       argpp  = argpm;
       nodep  = nodem;
       mp     = mm;
       sinip  = sinim;
       cosip  = cosim;
       if (tle.msgp4.isdeep) then begin
         dpp_r=make_array(value={dpper_return},n_elements(tsince));
         dpp_r[*].ep=ep;
         dpp_r[*].inclp=xincp;
         dpp_r[*].nodep=nodep;
         dpp_r[*].argpp=argpp;
         dpp_r[*].mp=mp;
         sgp4core_dpper,tle,tsince, dpp_r;
         ep=dpp_r[*].ep;
         xincp=dpp_r[*].inclp;
         nodep=dpp_r[*].nodep;
         argpp=dpp_r[*].argpp;
         mp=dpp_r[*].mp;
         w=where(logical_or(ep lt 0.0d, ep gt 1.0d),count)
         if count gt 0 then begin
           error[w]=3;
   ;//            printf("# error ep %f\n", ep);
         end
         w=where(xincp lt 0.0d,count)
         if count gt 0 then begin
           xincp[w]  = -xincp[w];
           nodep[w] = nodep[w] + !DPI;
           argpp[w]  = argpp[w] - !DPI;
         end

       ;/* -------------------- long period periodics ------------------ */
         sinip =  sin(xincp);
         cosip =  cos(xincp);
         aycof = -0.5d*tle.msgp4.j3oj2*sinip;
         ;// sgp4fix for divide by zero for xincp = 180 deg
         xlcof=tsince*0d;
         w=where(abs(cosip+1.0d) gt 1.5d-12,count,complement=nw,ncomp=ncount)
         if count gt 0 then begin
             xlcof[w] = -0.25d * tle.msgp4.j3oj2 * sinip[w] * (3.0d + 5.0d * cosip[w]) / (1.0d + cosip[w]);
         end
         if ncount gt 0 then begin
             xlcof[nw] = -0.25d * tle.msgp4.j3oj2 * sinip[nw] * (3.0d + 5.0d * cosip[nw]) / temp4[nw];
         end
       end else begin
         aycof=tle.msgp4.aycof;
         xlcof=tle.msgp4.xlcof;
       end
       axnl = ep * cos(argpp);
       temp = 1.0d / (am * (1.0d - ep * ep));
       aynl = ep* sin(argpp) + temp * aycof;
       xl   = mp + argpp + nodep + temp * xlcof * axnl;

       ;/* --------------------- solve kepler's equation --------------- */
       u    = (xl - nodep) mod (twopi);
       eo1  = u;
       tem5 = 9999.9d +0*tsince;
       ktr = 1;
       ;//   sgp4fix for kepler iteration
       ;//   the following iteration needs better limits on corrections
       coseo1=tem5
       sineo1=tem5
       w=where(finite(tsince),count)
       while (count gt 0 && (ktr le 10) ) do begin
           sineo1[w]=sin(eo1[w]);
           coseo1[w]=cos(eo1[w]);
           tem5[w]   = 1.0d - coseo1[w] * axnl[w] - sineo1[w] * aynl[w];
           tem5[w]   = (u[w] - aynl[w] * coseo1[w] + axnl[w] * sineo1[w] - eo1[w]) / tem5[w];
           w2=where(tem5 ge 0.95d,count)
           if count gt 0 then tem5[w2]=0.95d
           w2=where(tem5 le -0.95d,count)
           if count gt 0 then tem5[w2]=-0.95d
           eo1[w]    = eo1[w] + tem5[w];
           ktr++;
           w=where(abs(tem5) ge 1.0e-12,count)
       end

       ;/* ------------- short period preliminary quantities ----------- */
       ecose = axnl*coseo1 + aynl*sineo1;
       esine = axnl*sineo1 - aynl*coseo1;
       el2   = axnl*axnl + aynl*aynl;
       pl    = am*(1.0d -el2);
       w=where(pl lt 0.0d,count,complement=nw,ncomplement=ncount)
       if count gt 0 then begin
;//           printf("# error pl %f\n", pl);
           error[w]=4;
       end
       if ncount gt 0 then begin
           rl     = am * (1.0d - ecose);
           rdotl  = sqrt(am) * esine/rl;
           rvdotl = sqrt(pl) / rl;
           betal  = sqrt(1.0d - el2);
           temp   = esine / (1.0d + betal);
           sinu   = am / rl * (sineo1 - aynl - axnl * temp);
           cosu   = am / rl * (coseo1 - axnl + aynl * temp);
           su     = atan(sinu, cosu);
           sin2u  = (cosu + cosu) * sinu;
           cos2u  = 1.0d - 2.0d * sinu * sinu;
           temp   = 1.0d / pl;
           temp1  = 0.5d * tle.msgp4.j2 * temp;
           temp2  = temp1 * temp;

           ;/* -------------- update for short period periodics ------------ */
           if (tle.msgp4.isdeep) then begin
               cosisq                 = cosip * cosip;
               con41  = 3.0d*cosisq - 1.0d;
               x1mth2 = 1.0d - cosisq;
               x7thm1 = 7.0d*cosisq - 1.0d;
           end else begin
             con41=tle.msgp4.con41
             x1mth2=tle.msgp4.x1mth2
             x7thm1=tle.msgp4.x7thm1
           end
           mrt   = rl * (1.0d - 1.5d * temp2 * betal * con41) + $
                   0.5d * temp1 * x1mth2 * cos2u;
           su    = su - 0.25d * temp2 * x7thm1 * sin2u;
           xnode = nodep + 1.5d * temp2 * cosip * sin2u;
           xinc  = xincp + 1.5d * temp2 * cosip * sinip * cos2u;
           mvt   = rdotl - nm * temp1 * x1mth2 * sin2u / tle.msgp4.xke;
           rvdot = rvdotl + nm * temp1 * (x1mth2 * cos2u + $
                   1.5d * con41) / tle.msgp4.xke;

           ;/* --------------------- orientation vectors ------------------- */
           sinsu =  sin(su);
           cossu =  cos(su);
           snod  =  sin(xnode);
           cnod  =  cos(xnode);
           sini  =  sin(xinc);
           cosi  =  cos(xinc);
           xmx   = -snod * cosi;
           xmy   =  cnod * cosi;
           ux    =  xmx * sinsu + cnod * cossu;
           uy    =  xmy * sinsu + snod * cossu;
           uz    =  sini * sinsu;
           vx    =  xmx * cossu - cnod * sinsu;
           vy    =  xmy * cossu - snod * sinsu;
           vz    =  sini * cossu;

           ;/* --------- position and velocity (in km and km/sec) ---------- */
           rx = (mrt * ux)* tle.msgp4.radiusearthkm;
           ry = (mrt * uy)* tle.msgp4.radiusearthkm;
           rz = (mrt * uz)* tle.msgp4.radiusearthkm;
           vx = (mvt * ux + rvdot * vx) * vkmpersec;
           vy = (mvt * uy + rvdot * vy) * vkmpersec;
           vz = (mvt * uz + rvdot * vz) * vkmpersec;
           r=compose_grid(rx,ry,rz)
           v=compose_grid(vx,vy,vz)
         end  ;// if pl gt 0

       ;// sgp4fix for decaying satellites
       w=where(mrt lt 1.0d,count)
       if count gt 0 then begin
;          printf("# decay condition %11.6f \n",mrt);
           error[w]=6;
         end
       tle.msgp4.error=max(error)

  end  ;/ end sgp4

pro sgp4core_dscom,tle,epoch,tc,result
       ;* -------------------------- constants ------------------------- */
       zes     =  0.01675d;
       zel     =  0.05490d;
       c1ss    =  2.9864797d-6;
       c1l     =  4.7968065d-7;
       zsinis  =  0.39785416d;
       zcosis  =  0.91744867d;
       zcosgs  =  0.1945905d;
       zsings  = -0.98088458d;
       twopi   =  2.0d * !DPI;

       ;* --------------------- local variables ------------------------ */
       ;int lsflg;
       ;double a1    , a2    , a3    , a4    , a5    , a6    , a7    ,
       ;   a8    , a9    , a10   , betasq, cc    , ctem  , stem  ,
       ;   x1    , x2    , x3    , x4    , x5    , x6    , x7    ,
       ;   x8    , xnodce, xnoi  , zcosg , zcosgl, zcosh , zcoshl,
       ;   zcosi , zcosil, zsing , zsingl, zsinh , zsinhl, zsini ,
       ;   zsinil, zx    , zy;

       result.nm     = tle.msgp4.no;
       result.em     = tle.msgp4.ecco;
       result.snodm  = sin(tle.msgp4.nodeo);
       result.cnodm  = cos(tle.msgp4.nodeo);
       result.sinomm = sin(tle.msgp4.argpo);
       result.cosomm = cos(tle.msgp4.argpo);
       result.sinim  = sin(tle.msgp4.inclo);
       result.cosim  = cos(tle.msgp4.inclo);
       result.emsq   = result.em * result.em;
       betasq = 1.0 - result.emsq;
       result.rtemsq = sqrt(betasq);

       ;* ----------------- initialize lunar solar terms --------------- */
       tle.msgp4.peo    = 0.0d;
       tle.msgp4.pinco  = 0.0d;
       tle.msgp4.plo    = 0.0d;
       tle.msgp4.pgho   = 0.0d;
       tle.msgp4.pho    = 0.0d;
       result.day    = epoch + 18261.5d + tc / 1440.0d;
       xnodce = (4.5236020d - 9.2422029d-4 * result.day) mod (twopi);
       stem   = sin(xnodce);
       ctem   = cos(xnodce);
       zcosil = 0.91375164d - 0.03568096d * ctem;
       zsinil = sqrt(1.0d - zcosil * zcosil);
       zsinhl = 0.089683511d * stem / zsinil;
       zcoshl = sqrt(1.0d - zsinhl * zsinhl);
       result.gam    = 5.8351514d + 0.0019443680d * result.day;
       zx     = 0.39785416d * stem / zsinil;
       zy     = zcoshl * ctem + 0.91744867d * zsinhl * stem;
       zx     = atan(zx, zy);
       zx     = result.gam + zx - xnodce;
       zcosgl = cos(zx);
       zsingl = sin(zx);

       ;* ------------------------- do solar terms --------------------- */
       zcosg = zcosgs;
       zsing = zsings;
       zcosi = zcosis;
       zsini = zsinis;
       zcosh = result.cnodm;
       zsinh = result.snodm;
       cc    = c1ss;
       xnoi  = 1.0d / result.nm;

       for lsflg = 1,2 do begin
         a1  =   zcosg * zcosh + zsing * zcosi * zsinh;
         a3  =  -zsing * zcosh + zcosg * zcosi * zsinh;
         a7  =  -zcosg * zsinh + zsing * zcosi * zcosh;
         a8  =   zsing * zsini;
         a9  =   zsing * zsinh + zcosg * zcosi * zcosh;
         a10 =   zcosg * zsini;
         a2  =   result.cosim * a7 + result.sinim * a8;
         a4  =   result.cosim * a9 + result.sinim * a10;
         a5  =  -result.sinim * a7 + result.cosim * a8;
         a6  =  -result.sinim * a9 + result.cosim * a10;

         x1  =  a1 * result.cosomm + a2 * result.sinomm;
         x2  =  a3 * result.cosomm + a4 * result.sinomm;
         x3  = -a1 * result.sinomm + a2 * result.cosomm;
         x4  = -a3 * result.sinomm + a4 * result.cosomm;
         x5  =  a5 * result.sinomm;
         x6  =  a6 * result.sinomm;
         x7  =  a5 * result.cosomm;
         x8  =  a6 * result.cosomm;

         result.z31 = 12.0d * x1 * x1 - 3.0d * x3 * x3;
         result.z32 = 24.0d * x1 * x2 - 6.0d * x3 * x4;
         result.z33 = 12.0d * x2 * x2 - 3.0d * x4 * x4;
         result.z1  =  3.0d *  (a1 * a1 + a2 * a2) + result.z31 * result.emsq;
         result.z2  =  6.0d *  (a1 * a3 + a2 * a4) + result.z32 * result.emsq;
         result.z3  =  3.0d *  (a3 * a3 + a4 * a4) + result.z33 * result.emsq;
         result.z11 = -6.0d * a1 * a5 + result.emsq *  (-24.0d * x1 * x7-6.0d * x3 * x5);
         result.z12 = -6.0d *  (a1 * a6 + a3 * a5) + result.emsq * $
                  (-24.0d * (x2 * x7 + x1 * x8) - 6.0d * (x3 * x6 + x4 * x5));
         result.z13 = -6.0d * a3 * a6 + result.emsq * (-24.0d * x2 * x8 - 6.0d * x4 * x6);
         result.z21 =  6.0d * a2 * a5 + result.emsq * (24.0d * x1 * x5 - 6.0d * x3 * x7);
         result.z22 =  6.0d *  (a4 * a5 + a2 * a6) + result.emsq * $
                  (24.0d * (x2 * x5 + x1 * x6) - 6.0d * (x4 * x7 + x3 * x8));
         result.z23 =  6.0d * a4 * a6 + result.emsq * (24.0d * x2 * x6 - 6.0d * x4 * x8);
         result.z1  = result.z1 + result.z1 + betasq * result.z31;
         result.z2  = result.z2 + result.z2 + betasq * result.z32;
         result.z3  = result.z3 + result.z3 + betasq * result.z33;
         result.s3  = cc * xnoi;
         result.s2  = -0.5d * result.s3 / result.rtemsq;
         result.s4  = result.s3 * result.rtemsq;
         result.s1  = -15.0d * result.em * result.s4;
         result.s5  = x1 * x3 + x2 * x4;
         result.s6  = x2 * x3 + x1 * x4;
         result.s7  = x2 * x4 - x1 * x3;

         ;/* ----------------------- do lunar terms ------------------- */
         if (lsflg eq 1) then begin
           result.ss1   = result.s1;
           result.ss2   = result.s2;
           result.ss3   = result.s3;
           result.ss4   = result.s4;
           result.ss5   = result.s5;
           result.ss6   = result.s6;
           result.ss7   = result.s7;
           result.sz1   = result.z1;
           result.sz2   = result.z2;
           result.sz3   = result.z3;
           result.sz11  = result.z11;
           result.sz12  = result.z12;
           result.sz13  = result.z13;
           result.sz21  = result.z21;
           result.sz22  = result.z22;
           result.sz23  = result.z23;
           result.sz31  = result.z31;
           result.sz32  = result.z32;
           result.sz33  = result.z33;
           zcosg = zcosgl;
           zsing = zsingl;
           zcosi = zcosil;
           zsini = zsinil;
           zcosh = zcoshl * result.cnodm + zsinhl * result.snodm;
           zsinh = result.snodm * zcoshl - result.cnodm * zsinhl;
           cc    = c1l;
         end
       end

       tle.msgp4.zmol = (4.7199672d + 0.22997150d  * result.day - result.gam) mod (twopi);
       tle.msgp4.zmos = (6.2565837d + 0.017201977d * result.day) mod (twopi);

       ;* ------------------------ do solar terms ---------------------- */
       tle.msgp4.se2  =   2.0d * result.ss1 * result.ss6;
       tle.msgp4.se3  =   2.0d * result.ss1 * result.ss7;
       tle.msgp4.si2  =   2.0d * result.ss2 * result.sz12;
       tle.msgp4.si3  =   2.0d * result.ss2 * (result.sz13 - result.sz11);
       tle.msgp4.sl2  =  -2.0d * result.ss3 * result.sz2;
       tle.msgp4.sl3  =  -2.0d * result.ss3 * (result.sz3 - result.sz1);
       tle.msgp4.sl4  =  -2.0d * result.ss3 * (-21.0d - 9.0d * result.emsq) * zes;
       tle.msgp4.sgh2 =   2.0d * result.ss4 * result.sz32;
       tle.msgp4.sgh3 =   2.0d * result.ss4 * (result.sz33 - result.sz31);
       tle.msgp4.sgh4 = -18.0d * result.ss4 * zes;
       tle.msgp4.sh2  =  -2.0d * result.ss2 * result.sz22;
       tle.msgp4.sh3  =  -2.0d * result.ss2 * (result.sz23 - result.sz21);

       ;* ------------------------ do lunar terms ---------------------- */
       tle.msgp4.ee2  =   2.0d * result.s1 * result.s6;
       tle.msgp4.e3   =   2.0d * result.s1 * result.s7;
       tle.msgp4.xi2  =   2.0d * result.s2 * result.z12;
       tle.msgp4.xi3  =   2.0d * result.s2 * (result.z13 - result.z11);
       tle.msgp4.xl2  =  -2.0d * result.s3 * result.z2;
       tle.msgp4.xl3  =  -2.0d * result.s3 * (result.z3 - result.z1);
       tle.msgp4.xl4  =  -2.0d * result.s3 * (-21.0d - 9.0d * result.emsq) * zel;
       tle.msgp4.xgh2 =   2.0d * result.s4 * result.z32;
       tle.msgp4.xgh3 =   2.0d * result.s4 * (result.z33 - result.z31);
       tle.msgp4.xgh4 = -18.0d * result.s4 * zel;
       tle.msgp4.xh2  =  -2.0d * result.s2 * result.z22;
       tle.msgp4.xh3  =  -2.0d * result.s2 * (result.z23 - result.z21);

end ; dscom

pro sgp4core_dpper,tle,t,result
       ; --------------------- local variables ------------------------ */
       twopi = 2.0 * !DPI;
       ;double alfdp, betdp, cosip, cosop, dalf, dbet, dls,
       ;     f2,    f3,    pe,    pgh,   ph,   pinc, pl ,
       ;     sel,   ses,   sghl,  sghs,  shll, shs,  sil,
       ;     sinip, sinop, sinzf, sis,   sll,  sls,  xls,
       ;     xnoh,  zf,    zm,    zel,   zes,  znl,  zns;

       ;* ---------------------- constants ----------------------------- */
       zns   = 1.19459d-5;
       zes   = 0.01675d;
       znl   = 1.5835218d-4;
       zel   = 0.05490d;

       ;* --------------- calculate time varying periodics ----------- */
       zm    = tle.msgp4.zmos + zns * t;
       ;/ be sure that the initial call has time set to zero
       zf    = zm + 2.0d * zes * sin(zm);
       sinzf = sin(zf);
       f2    =  0.5d * sinzf * sinzf - 0.25d;
       f3    = -0.5d * sinzf * cos(zf);
       ses   = tle.msgp4.se2* f2 + tle.msgp4.se3 * f3;
       sis   = tle.msgp4.si2 * f2 + tle.msgp4.si3 * f3;
       sls   = tle.msgp4.sl2 * f2 + tle.msgp4.sl3 * f3 + tle.msgp4.sl4 * sinzf;
       sghs  = tle.msgp4.sgh2 * f2 + tle.msgp4.sgh3 * f3 + tle.msgp4.sgh4 * sinzf;
       shs   = tle.msgp4.sh2 * f2 + tle.msgp4.sh3 * f3;
       zm    = tle.msgp4.zmol + znl * t;
       zf    = zm + 2.0d * zel * sin(zm);
       sinzf = sin(zf);
       f2    =  0.5d * sinzf * sinzf - 0.25d;
       f3    = -0.5d * sinzf * cos(zf);
       sel   = tle.msgp4.ee2 * f2 + tle.msgp4.e3 * f3;
       sil   = tle.msgp4.xi2 * f2 + tle.msgp4.xi3 * f3;
       sll   = tle.msgp4.xl2 * f2 + tle.msgp4.xl3 * f3 + tle.msgp4.xl4 * sinzf;
       sghl  = tle.msgp4.xgh2 * f2 + tle.msgp4.xgh3 * f3 + tle.msgp4.xgh4 * sinzf;
       shll  = tle.msgp4.xh2 * f2 + tle.msgp4.xh3 * f3;
       pe    = ses + sel;
       pinc  = sis + sil;
       pl    = sls + sll;
       pgh   = sghs + sghl;
       ph    = shs + shll;

         ;//  0.2 rad = 11.45916 deg
         ;//  sgp4fix for lyddane choice
         ;//  add next three lines to set up use of original inclination per strn3 ver

         pe    = pe - tle.msgp4.peo;
         pinc  = pinc - tle.msgp4.pinco;
         pl    = pl - tle.msgp4.plo;
         pgh   = pgh - tle.msgp4.pgho;
         ph    = ph - tle.msgp4.pho;
         result.inclp = result.inclp + pinc;
         result.ep    = result.ep + pe;
         sinip = sin(result.inclp);
         cosip = cos(result.inclp);

         ;/* ----------------- apply periodics directly ------------ */
         ;//  sgp4fix for lyddane choice
         ;//  strn3 used original inclination - this is technically feasible
         ;//  gsfc used perturbed inclination - also technically feasible
         ;//  probably best to readjust the 0.2 limit value and limit discontinuity
         ;//  use next line for original strn3 approach and original inclination
         ;//  if (inclo >= 0.2)
         ;//  use next line for gsfc version and perturbed inclination
         cond1=result[*].inclp ge 0.2
         w1=where(cond1,count1,complement=nw1,ncomp=ncount1)
         if count1 gt 0 then begin
           ph[w1]     = ph[w1] / sinip[w1];
           pgh[w1]    = pgh[w1] - cosip[w1] * ph[w1];
           result[w1].argpp  = result[w1].argpp + pgh[w1];
           result[w1].nodep  = result[w1].nodep + ph[w1];
           result[w1].mp     = result[w1].mp + pl[w1];
         end
         if ncount1 gt 0 then begin
           sinop=sinip[nw1]*0d
           cosop=sinop
           alfdp=sinop
           betdp=sinop
           dalf=sinop
           dbet=sinop
           xls=sinop
           dls=sinop
           xnoh=sinip*0d
           ;/* ---- apply periodics with lyddane modification ---- */
           sinop  = sin(result[nw1].nodep);
           cosop  = cos(result[nw1].nodep);
           alfdp  = sinip[nw1] * sinop;
           betdp  = sinip[nw1] * cosop;
           dalf   =  ph[nw1] * cosop + pinc[nw1] * cosip[nw1] * sinop;
           dbet   = -ph[nw1] * sinop + pinc[nw1] * cosip[nw1] * cosop;
           alfdp  = alfdp + dalf;
           betdp  = betdp + dbet;
           result[nw1].nodep  = result[nw1].nodep mod twopi;
           xls    = result[nw1].mp + result[nw1].argpp + cosip[nw1] * result[nw1].nodep;
           dls    = pl[nw1] + pgh[nw1] - pinc[nw1] * result[nw1].nodep * sinip[nw1];
           xls    = xls + dls;
           xnoh[nw1]   = result[nw1].nodep;
           result[nw1].nodep  = atan(alfdp, betdp);
           w2=where(logical_and(~cond1,logical_and(abs(xnoh - result.nodep) gt !DPI,result.nodep lt xnoh)),count2)
           if count2 gt 0 then begin
             result[w2].nodep = result[w2].nodep + twopi;
           end
           w2=where(logical_and(~cond1,logical_and(abs(xnoh - result.nodep) gt !DPI,result.nodep ge xnoh)),count2)
           if count2 gt 0 then begin
             result[w2].nodep = result[w2].nodep - twopi;
           end
           result[nw1].mp    = result[nw1].mp + pl[nw1];
           result[nw1].argpp = xls - result[nw1].mp - cosip[nw1] * result[nw1].nodep;
         end

end  ;dpper


pro sgp4core_dsinit,tle,dsc_r,tc,xpidot,eccsq,result
       ;* --------------------- local variables ------------------------ */
       twopi = 2.0d * !DPI;

       aonv=0.0d;
       ;double ainv2 cosisq, eoc, f220 , f221  , f311  ,
       ;     f321  , f322  , f330  , f441  , f442  , f522  , f523  ,
       ;     f542  , f543  , g200  , g201  , g211  , g300  , g310  ,
       ;     g322  , g410  , g422  , g520  , g521  , g532  , g533  ,
       ;     ses   , sgs   , sghl  , sghs  , shs   , shll  , sis   ,
       ;     sini2 , sls   , temp  , temp1 , theta , xno2  , q22   ,
       ;     q31   , q33   , root22, root44, root54, rptim , root32,
       ;     root52, x2o3  , znl   , emo   , zns   , emsqo, emsq, dndt;
       emsq=dsc_r.emsq;
       q22    = 1.7891679d-6;
       q31    = 2.1460748d-6;
       q33    = 2.2123015d-7;
       root22 = 1.7891679d-6;
       root44 = 7.3636953d-9;
       root54 = 2.1765803d-9;
       rptim  = 4.37526908801129966d-3; // this equates to 7.29211514668855e-5 rad/sec
       root32 = 3.7393792d-7;
       root52 = 1.1428639d-7;
       x2o3   = 2.0d / 3.0d;
       znl    = 1.5835218d-4;
       zns    = 1.19459d-5;

       ;// sgp4fix identify constants and allow alternate values

       ;/* -------------------- deep space initialization ------------ */
       tle.msgp4.irez = 0;
       if ((result.nm lt 0.0052359877d) && (result.nm gt 0.0034906585d)) then tle.msgp4.irez = 1;
       if ((result.nm ge 8.26d-3) && (result.nm le 9.24d-3) && (result.em ge 0.5d)) then tle.msgp4.irez = 2;

       ;/* ------------------------ do solar terms ------------------- */
       ses  =  dsc_r.ss1 * zns * dsc_r.ss5;
       sis  =  dsc_r.ss2 * zns * (dsc_r.sz11 + dsc_r.sz13);
       sls  = -zns * dsc_r.ss3 * (dsc_r.sz1 + dsc_r.sz3 - 14.0d - 6.0d * emsq);
       sghs =  dsc_r.ss4 * zns * (dsc_r.sz31 + dsc_r.sz33 - 6.0d);
       shs  = -zns * dsc_r.ss2 * (dsc_r.sz21 + dsc_r.sz23);
       ; sgp4fix for 180 deg incl
       if ((result.inclm lt 5.2359877d-2) || (result.inclm gt !DPI - 5.2359877d-2)) then shs = 0.0d;
       if (dsc_r.sinim ne 0.0d) then shs = shs / dsc_r.sinim;
       sgs  = sghs - dsc_r.cosim * shs;

       ;* ------------------------- do lunar terms ------------------ */
       tle.msgp4.dedt = ses + dsc_r.s1 * znl * dsc_r.s5;
       tle.msgp4.didt = sis + dsc_r.s2 * znl * (dsc_r.z11 + dsc_r.z13);
       tle.msgp4.dmdt = sls - znl * dsc_r.s3 * (dsc_r.z1 + dsc_r.z3 - 14.0 - 6.0 * emsq);
       sghl = dsc_r.s4 * znl * (dsc_r.z31 + dsc_r.z33 - 6.0);
       shll = -znl * dsc_r.s2 * (dsc_r.z21 + dsc_r.z23);
       ;/ sgp4fix for 180 deg incl
       if ((result.inclm lt 5.2359877e-2) || (result.inclm gt !DPI - 5.2359877e-2)) then shll = 0.0;
       tle.msgp4.domdt = sgs + sghl;
       tle.msgp4.dnodt = shs;
       if (dsc_r.sinim ne 0.0d) then begin
         tle.msgp4.domdt = tle.msgp4.domdt - dsc_r.cosim / dsc_r.sinim * shll;
         tle.msgp4.dnodt = tle.msgp4.dnodt + shll / dsc_r.sinim;
       end

       ;* ----------- calculate deep space resonance effects -------- */
       dndt   = 0.0d;
       theta  = (tle.msgp4.gsto + tc * rptim) mod (twopi);

       ;* -------------- initialize the resonance terms ------------- */
       if (tle.msgp4.irez ne 0) then begin
           aonv = pow(result.nm / tle.msgp4.xke, x2o3);

           ;* ---------- geopotential resonance for 12 hour orbits ------ */
           if (tle.msgp4.irez eq 2) then begin
               cosisq = dsc_r.cosim * dsc_r.cosim;
               emo    = result.em;
               result.em     = tle.msgp4.ecco;
               emsqo  = emsq;
               emsq   = eccsq;
               eoc    = result.em * emsq;
               g201   = -0.306d - (result.em - 0.64d) * 0.440d;

               if (result.em le 0.65d) then begin
                   g211 =    3.616d  -  13.2470d * result.em +  16.2900d * emsq;
                   g310 =  -19.302d  + 117.3900d * result.em - 228.4190d * emsq +  156.5910d * eoc;
                   g322 =  -18.9068d + 109.7927d * result.em - 214.6334d * emsq +  146.5816d * eoc;
                   g410 =  -41.122d  + 242.6940d * result.em - 471.0940d * emsq +  313.9530d * eoc;
                   g422 = -146.407d  + 841.8800d * result.em - 1629.014d * emsq + 1083.4350d * eoc;
                   g520 = -532.114d  + 3017.977d * result.em - 5740.032d * emsq + 3708.2760d * eoc;
               end else begin
                   g211 =   -72.099d +   331.819d * result.em -   508.738d * emsq +   266.724d * eoc;
                   g310 =  -346.844d +  1582.851d * result.em -  2415.925d * emsq +  1246.113d * eoc;
                   g322 =  -342.585d +  1554.908d * result.em -  2366.899d * emsq +  1215.972d * eoc;
                   g410 = -1052.797d +  4758.686d * result.em -  7193.992d * emsq +  3651.957d * eoc;
                   g422 = -3581.690d + 16178.110d * result.em - 24462.770d * emsq + 12422.520d * eoc;
                   if (result.em gt 0.715d) then begin
                       g520 =-5149.66d + 29936.92d * result.em - 54087.36d * emsq + 31324.56d * eoc;
                   end else begin
                       g520 = 1464.74d -  4664.75d * result.em +  3763.64d * emsq;
                   end
               end
               if (result.em lt 0.7d) then begin
                   g533 = -919.22770d + 4988.6100d * result.em - 9064.7700d * emsq + 5542.21d  * eoc;
                   g521 = -822.71072d + 4568.6173d * result.em - 8491.4146d * emsq + 5337.524d * eoc;
                   g532 = -853.66600d + 4690.2500d * result.em - 8624.7700d * emsq + 5341.4d   * eoc;
               end else begin
                   g533 =-37995.780d + 161616.52d * result.em - 229838.20d * emsq + 109377.94d * eoc;
                   g521 =-51752.104d + 218913.95d * result.em - 309468.16d * emsq + 146349.42d * eoc;
                   g532 =-40023.880d + 170470.89d * result.em - 242699.48d * emsq + 115605.82d * eoc;
               end

               sini2=  dsc_r.sinim * dsc_r.sinim;
               f220 =  0.75d * (1.0d + 2.0d * dsc_r.cosim+cosisq);
               f221 =  1.5d * sini2;
               f321 =  1.875d * dsc_r.sinim  *  (1.0 - 2.0 * dsc_r.cosim - 3.0 * cosisq);
               f322 = -1.875d * dsc_r.sinim  *  (1.0 + 2.0 * dsc_r.cosim - 3.0 * cosisq);
               f441 = 35.0d * sini2 * f220;
               f442 = 39.3750d * sini2 * sini2;
               f522 =  9.84375d * dsc_r.sinim * (sini2 * (1.0d - 2.0d * dsc_r.cosim- 5.0d * cosisq) + $
                       0.33333333d * (-2.0d + 4.0d * dsc_r.cosim + 6.0d * cosisq) );
               f523 = dsc_r.sinim * (4.92187512d * sini2 * (-2.0d - 4.0d * dsc_r.cosim + $
                      10.0d * cosisq) + 6.56250012d * (1.0d +2.0d * dsc_r.cosim - 3.0d * cosisq));
               f542 = 29.53125d * dsc_r.sinim * (2.0d - 8.0d * dsc_r.cosim+cosisq * $
                      (-12.0d + 8.0d * dsc_r.cosim + 10.0d * cosisq));
               f543 = 29.53125d * dsc_r.sinim * (-2.0d - 8.0d * dsc_r.cosim+cosisq * $
                      (12.0 + 8.0d * dsc_r.cosim - 10.0d * cosisq));
               xno2  =  result.nm * result.nm;
               ainv2 =  aonv * aonv;
               temp1 =  3.0d * xno2 * ainv2;
               temp  =  temp1 * root22;
               tle.msgp4.d2201 =  temp * f220 * g201;
               tle.msgp4.d2211 =  temp * f221 * g211;
               temp1 =  temp1 * aonv;
               temp  =  temp1 * root32;
               tle.msgp4.d3210 =  temp * f321 * g310;
               tle.msgp4.d3222 =  temp * f322 * g322;
               temp1 =  temp1 * aonv;
               temp  =  2.0d * temp1 * root44;
               tle.msgp4.d4410 =  temp * f441 * g410;
               tle.msgp4.d4422 =  temp * f442 * g422;
               temp1 =  temp1 * aonv;
               temp  =  temp1 * root52;
               tle.msgp4.d5220 =  temp * f522 * g520;
               tle.msgp4.d5232 =  temp * f523 * g532;
               temp  =  2.0d * temp1 * root54;
               tle.msgp4.d5421 =  temp * f542 * g521;
               tle.msgp4.d5433 =  temp * f543 * g533;
               tle.msgp4.xlamo =  (tle.msgp4.mo + tle.msgp4.nodeo + tle.msgp4.nodeo-theta - theta) mod (twopi);
               tle.msgp4.xfact =  tle.msgp4.mdot + tle.msgp4.dmdt + 2.0d * (tle.msgp4.nodedot + tle.msgp4.dnodt - rptim) - tle.msgp4.no;
               result.em    = emo;
               emsq  = emsqo;
           end

           ;* ---------------- synchronous resonance terms -------------- */
           if (tle.msgp4.irez eq 1) then begin
               g200  = 1.0d + emsq * (-2.5d + 0.8125d * emsq);
               g310  = 1.0d + 2.0d * emsq;
               g300  = 1.0d + emsq * (-6.0d + 6.60937d * emsq);
               f220  = 0.75d * (1.0d + dsc_r.cosim) * (1.0d + dsc_r.cosim);
               f311  = 0.9375d * dsc_r.sinim * dsc_r.sinim * (1.0d + 3.0d * dsc_r.cosim) - 0.75d * (1.0d + dsc_r.cosim);
               f330  = 1.0d + dsc_r.cosim;
               f330  = 1.875d * f330 * f330 * f330;
               tle.msgp4.del1  = 3.0d * result.nm * result.nm * aonv * aonv;
               tle.msgp4.del2  = 2.0d * tle.msgp4.del1 * f220 * g200 * q22;
               tle.msgp4.del3  = 3.0d * tle.msgp4.del1 * f330 * g300 * q33 * aonv;
               tle.msgp4.del1  = tle.msgp4.del1 * f311 * g310 * q31 * aonv;
               tle.msgp4.xlamo = (tle.msgp4.mo + tle.msgp4.nodeo + tle.msgp4.argpo - theta) mod (twopi);
               tle.msgp4.xfact = tle.msgp4.mdot + xpidot - rptim + tle.msgp4.dmdt + tle.msgp4.domdt + tle.msgp4.dnodt - tle.msgp4.no;
           end

           ;* ------------ for sgp4, initialize the integrator ---------- */
           result.nm    = tle.msgp4.no + dndt;
         end

end ;/ end dsinit

pro sgp4core_dspace,tle,t,result
     twopi = 2.0d * !DPI;
     ;int iretn , iret;
     ;double delt, theta, x2li, x2omi, xl, xldot , xnddt, xndt, xomi;
     ;double atime,xni,xli;
     ft    = 0.0d;

     fasx2 = 0.13130908d;
     fasx4 = 2.8843198d;
     fasx6 = 0.37448087d;
     g22   = 5.7686396d;
     g32   = 0.95240898d;
     g44   = 1.8014998d;
     g52   = 1.0508330d;
     g54   = 4.4108898d;
     rptim = 4.37526908801129966d-3; // this equates to 7.29211514668855e-5 rad/sec
     stepp =    720.0d;
     stepn =   -720.0d;
     step2 = 259200.0d;

     ;* ----------- calculate deep space resonance effects ----------- */
     result.dndt   = 0.0d;
     theta  = (tle.msgp4.gsto + t * rptim) mod (twopi);
     result.em     = result.em + tle.msgp4.dedt * t;

     result.inclm  = result.inclm + tle.msgp4.didt * t;
     result.argpm  = result.argpm + tle.msgp4.domdt * t;
     result.nodem  = result.nodem + tle.msgp4.dnodt * t;
     result.mm     = result.mm + tle.msgp4.dmdt * t;

     ;//   sgp4fix for negative inclinations
     ;//   the following if statement should be commented out
     ;//  if (inclm < 0.0)
     ;// {
     ;//    inclm = -inclm;
     ;//    argpm = argpm - PI;
     ;//    nodem = nodem + PI;
     ;//  }

     ;/* - update resonances : numerical (euler-maclaurin) integration - */
     ;/* ------------------------- epoch restart ----------------------  */
     ;//   sgp4fix for propagator problems
     ;//   the following integration works for negative time steps and periods
     ;//   the specific changes are unknown because the original code was so convoluted

     ft    = 0.0d;
     atime = 0.0d; //atime not used above this point, so overwritten
     if (tle.msgp4.irez ne 0) then begin
         if (t ge 0.0d) then begin
           delt = stepp;
         end else begin
           delt = stepn;
         end
         atime  = 0.0d;
         xni    = tle.msgp4.no;      //xni overwritten in this branch, not used above this point
         xli    = tle.msgp4.xlamo;   //xli overwriiten in this branch, not used above this point
         iretn = 381; // added for do loop
         iret  =   0; // added for loop
         while iretn eq 381 do begin
           if ((abs(t) lt abs(atime)) || (iret eq 351)) then begin
             if (t ge 0.0) then begin
               delt = stepn;
             end else begin
               delt = stepp;
             end
             iret  = 351;
             iretn = 381;
           end else begin
             if (t gt 0.0d) then begin ;// error if prev if has atime:=0.0 and t:=0.0 (ge)
               delt = stepp;
             end else begin
               delt = stepn;
             end
             if (abs(t - atime) ge stepp) then begin
               iret  = 0;
               iretn = 381;
             end else begin
               ft    = t - atime;
               iretn = 0;
             end
           end

           ;/* ------------------- dot terms calculated ------------- */
           ;/* ----------- near - synchronous resonance terms ------- */
           if (tle.msgp4.irez ne 2) then begin
             xndt  = tle.msgp4.del1 * sin(xli - fasx2) + tle.msgp4.del2 * sin(2.0d * (xli - fasx4)) + $
                        tle.msgp4.del3 * sin(3.0d * (xli - fasx6));
             xldot = xni + tle.msgp4.xfact;
             xnddt = tle.msgp4.del1 * cos(xli - fasx2) + $
                         2.0d * tle.msgp4.del2 * cos(2.0d * (xli - fasx4)) + $
                         3.0d * tle.msgp4.del3 * cos(3.0d * (xli - fasx6));
             xnddt = xnddt * xldot;
           end else begin
             ;/* --------- near - half-day resonance terms -------- */
             xomi  = tle.msgp4.argpo + tle.msgp4.argpdot * atime;
             x2omi = xomi + xomi;
             x2li  = xli + xli;
             xndt  = tle.msgp4.d2201 * sin(x2omi + xli - g22) + tle.msgp4.d2211 * sin(xli - g22) + $
                       tle.msgp4.d3210 * sin(xomi + xli - g32)  + tle.msgp4.d3222 * sin(-xomi + xli - g32)+ $
                       tle.msgp4.d4410 * sin(x2omi + x2li - g44)+ tle.msgp4.d4422 * sin(x2li - g44) + $
                       tle.msgp4.d5220 * sin(xomi + xli - g52)  + tle.msgp4.d5232 * sin(-xomi + xli - g52)+ $
                       tle.msgp4.d5421 * sin(xomi + x2li - g54) + tle.msgp4.d5433 * sin(-xomi + x2li - g54);
             xldot = xni + tle.msgp4.xfact;
             xnddt = tle.msgp4.d2201 * cos(x2omi + xli - g22) + tle.msgp4.d2211 * cos(xli - g22) + $
                       tle.msgp4.d3210 * cos(xomi + xli - g32) + tle.msgp4.d3222 * cos(-xomi + xli - g32) + $
                       tle.msgp4.d5220 * cos(xomi + xli - g52) + tle.msgp4.d5232 * cos(-xomi + xli - g52) + $
                       2.0d * (tle.msgp4.d4410 * cos(x2omi + x2li - g44) + $
                       tle.msgp4.d4422 * cos(x2li - g44) +tle.msgp4. d5421 * cos(xomi + x2li - g54) + $
                       tle.msgp4.d5433 * cos(-xomi + x2li - g54));
             xnddt = xnddt * xldot;
           end

           ;  /* ----------------------- integrator ------------------- */
           if (iretn eq 381) then begin
             xli   = xli + xldot * delt + xndt * step2;
             xni   = xni + xndt * delt + xnddt * step2;
             atime = atime + delt;
           end
         end

         result.nm = xni + xndt * ft + xnddt * ft * ft * 0.5d;
         xl = xli + xldot * ft + xndt * ft * ft * 0.5d;
         if (tle.msgp4.irez ne 1) then begin
           result.mm   = xl - 2.0d * result.nodem + 2.0d * theta;
           result.dndt = result.nm - tle.msgp4.no;
         end else begin
           result.mm   = xl - result.nodem - result.argpm + theta;
           result.dndt = result.nm - tle.msgp4.no;
         end
         result.nm = tle.msgp4.no + result.dndt;
       end
  end  ;// end dspace

pro sgp4core__define
  sgp4={sgp4core, init:0B, $
        error:0L, $
        jdsatepoch:0d, $
        isdeep:0b, $
    ; Main gravity constants
        radiusearthkm:0d,$
        mu:0d,   $
        xke:0d,  $
        tumin:0d,$
        j2:0d,   $
        j3:0d,   $
        j4:0d,   $
        j3oj2:0d, $

    ; Near Earth
        isimp:0L, $
        aycof:0d  , con41:0d  , cc1:0d    , cc4:0d      , cc5:0d    , d2:0d      , d3:0d   , d4:0d    ,$
        delmo:0d  , eta:0d    , argpdot:0d, omgcof:0d   , sinmao:0d , t2cof:0d, t3cof:0d ,$
        t4cof:0d  , t5cof:0d  , x1mth2:0d , x7thm1:0d   , mdot:0d   , nodedot:0d , xlcof:0d, xmcof:0d ,$
        nodecf:0d, $

    ; Deep Space
        irez:0L, $
        d2201:0d  , d2211:0d  , d3210:0d  , d3222:0d    , d4410:0d  , d4422:0d   , d5220:0d , d5232:0d , $
        d5421:0d  , d5433:0d  , dedt:0d   , del1:0d     , del2:0d   , del3:0d    , didt:0d  , dmdt:0d  , $
        dnodt:0d  , domdt:0d  , e3:0d     , ee2:0d      , peo:0d    , pgho:0d    , pho:0d   , pinco:0d , $
        plo:0d    , se2:0d    , se3:0d    , sgh2:0d     , sgh3:0d   , sgh4:0d    , sh2:0d   , sh3:0d   , $
        si2:0d    , si3:0d    , sl2:0d    , sl3:0d      , sl4:0d    , gsto:0d    , xfact:0d , xgh2:0d  , $
        xgh3:0d   , xgh4:0d   , xh2:0d    , xh3:0d      , xi2:0d    , xi3:0d     , xl2:0d   , xl3:0d   , $
        xl4:0d    , xlamo:0d  , zmol:0d   , zmos:0d,      $

        a:0d      , $
        bstar:0d  , rcse:0d   , inclo:0d  , nodeo:0d    , ecco:0d             , argpo:0d , mo:0d    , $
        no:0d $

      }
end