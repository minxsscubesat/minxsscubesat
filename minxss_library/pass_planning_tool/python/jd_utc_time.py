import datetime
import jdcal

manual_test = 0
t_offset = 0

def now_in_jd():
    now_utc = datetime.datetime.utcnow()
    now_jd = jdcal.gcal2jd(now_utc.year, now_utc.month, now_utc.day) #TODO
    now_jd = now_jd[0] + now_jd[1]
    now_jd = now_jd + now_utc.hour/24 + now_utc.minute/24/60 + now_utc.second/24/60/60

    now_jd -= t_offset
    return(now_jd)

def secs_to_jd(s):
    return s/24/60/60

def jd_to_minutes(a):
    return a*24*60


if(manual_test == 1):
    now_jd = now_in_jd()
    target_time = 2457847.497488426 + secs_to_jd(60)
    t_offset = now_jd - target_time
    print("\r\n\r\n**********WARNING: ENABLING TIME OFFSET OF {0} (in JD). Only recommended for testing purposes!**********\r\n\r\n".format(t_offset))
