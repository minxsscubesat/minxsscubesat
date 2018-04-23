import datetime
import jdcal

def now_in_jd():
    now_utc = datetime.datetime.utcnow()
    now_jd = jdcal.gcal2jd(now_utc.year, now_utc.month, now_utc.day)
    now_jd = now_jd[0] + now_jd[1]
    now_jd = now_jd + now_utc.hour/24 + now_utc.minute/24/60 + now_utc.second/24/60/60
    return(now_jd)