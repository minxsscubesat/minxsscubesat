pro tle_struct__define
  tle_struct={tle_struct, $
    ;Line before the two lines, usually the name of the spacecraft
    line0:'', $
    ;Original form of two lines
    line1:'', $
    line2:'', $
    ; NORAD catalog number. Serial number of objects, in the order that they were detected by NORAD.
    ; This may have no relation to the launch order, since if an object breaks up, the fragments are
    ; newly detected. 5 digits, can be up to 99999, so need 32-bit number
    satnum:0ul, $
    ; NORAD security classification for these elements. All published elements are marked 'U', for
    ; unclassified. I've never seen a classified element, but I suppose they are things like 'C' for
    ; confidential, 'S' for secret, 'T' for top secret, etc.
    classification:' ',$
    ; International designation. Consists of launch year, launch serial number in the year, and
    ; fragment/payload letter for the launch. If a satellite splits/deploys payloads, all the fragments
    ; are considered to be from the same launch. One of them is designated A, and usually this is the
    ; one which keeps the NORAD catalog number of the original object, while the other(s) get letters
    ; B,C,etc. and the next available NORAD catalog number. On expendible launch vehicles, usually the
    ; primary payload gets A, secondary payloads B and so on, and the upper stage gets the next letter
    ; after the last payload. On Space Shuttles, the Orbiter gets A, while any free-flying payloads
    ; get B, C, etc. The tank doesn't get a letter as it never completes a full orbit. Pieces
    ; attached to the International Space Station used to get their own track, but not any more.
    ; So Destiny is 2001-006B, but Quest isn't tracked. Debris or jettisons from the Space Station
    ; are considered to be launched in 1998 (with Zarya, the first piece of the station) regardless of
    ; when that particular object was launched.
    intldesg:'',$
    ; Year of epoch. Stored in the TLE as a two-digit year, stored internally as a 4-digit year. Two-digit
    ; years are assumed to occur between 1950 and 2049.
    epochyr:0U, $
    ; Day of epoch. This is the number of days since the beginning of the year, in UTC,
    ; with 1 January 00:00:00UTC being exactly 1.0
    epochdays:0d, $
    ; Epoch time. Number encoding epoch time formed by composing the (epoch year)*1000+(epoch day)
    ydepoch:0d, $
    ; Epoch time. UTC Julian date encoding the epoch time
    jdepoch:0d, $
    ; Secular acceleration. This is the rate of change of the mean motion of the satellite, divided
    ; by two, in days per day. It is used with the Brouwer model, and not directly by SGP4.
    ndot:0d, $
    ; Secular acceleration rate. This is the acceleration of the mean motion of the satellite, divided
    ; by six, in days/day^2. It is used with the older Brouwer propagator, and not directly by SGP4.
    nddot:0d, $
    ; Modified ballistic coefficient. Conceptually it is the (aero cross section)/mass ratio, in m^2/kg
    ; but modified as needed to fit the observations best. This is the drag term used by SGP4. Higher numbers
    ; indicate more drag.
    bstar:0d, $
    ; Ephemeris type. Was to be used to tell which algorithm to use (MSGP4, MSGP8, something else...) but
    ; all TLES use MSGP4.
    numb:0u, $
    ; Element serial number. Usually bumped each time a new element is published, but maybe not...
    elnum:0U, $ 4 digits, so 16 bits is enough
    ; Value of the check digit as in the original parsed string
    check1:0B, $
    ; Inclination, deg. All angles relative to TEME pseudo-inertial system as documented in Vallado.
    ; All elements are their original form as in the strings, not modified as needed by MSGP4 (which
    ; does that itself)
    inclo:0d, $
    ; Right Ascension of Ascending Node, deg
    nodeo:0d, $
    ; Eccentricity, unitless
    ecco:0d,  $
    ; Argument of perigee, deg
    argpo:0d, $
    ; Mean anomaly, deg
    mo:0d,    $
    ; Mean motion, rev/day
    no:0d,    $
    ; Approximate semimajor axis, km
    ao:0d,    $
    ; Revolution number at epoch
    revnum:0UL, $ ;5 digits allotted
    ; Check digit for line 2 as in the string
    check2:0b, $
    ;Test value: start of test, in minutes from epoch
    startmfe:0d, $
    ;Test value: stop of test, in minutes from epoch
    stopmfe:0d,  $
    ;Test value: step size, in minutes
    deltamin:0d,  $
    ;SGP4 object that evaluates this tle. Blank if tle never evaluated
    msgp4:{sgp4core} $
  }

end
