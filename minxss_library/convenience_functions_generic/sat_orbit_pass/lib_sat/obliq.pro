FUNCTION OBLIQ, T
;
;     GIVEN DYNAMICAL TIME T IN JULIAN MILLENIA SINCE J2000, RETURNS
;     THE MEAN OBLIQUITY OF THE ECLIPTIC (NEGLECTING NUTATION), IN
;     RADIANS.  (ALGORITHM OF J. LASKAR, ASTRONOMY AND ASTROPHYSICS
;     157 (1986) P. 68, AS PRESENTED BY JEAN MEEUS, "ASTRONOMICAL
;     ALGORITHMS", WILLMANN-BELL, 1991.)
;
;     B. KNAPP, 1992-05-02, 2000-09-01
;     Translated to IDL C. Jeppesen, 2009-10-08
;
;
;     CAUTION: THE ABSOLUTE VALUE OF T MUST BE LESS THAN OR EQUAL TO 10.
;
      D2R = 3.14159265358979324D0/180.D0
      U = double(T)/10.D0

      return, ( 23.43929111D0 + $
         U*( -4680.93D0 + $
         U*(    -1.55D0 + $
         U*(  1999.25D0 + $
         U*(   -51.38D0 + $
         U*(  -249.67D0 + $
         U*(   -39.05D0 + $
         U*(     7.12D0 + $
         U*(    27.87D0 + $
         U*(     5.79D0 + $
         U*      2.45D0 ) ) ) ) ) ) ) ) )/3600.D0 )*D2R

END
