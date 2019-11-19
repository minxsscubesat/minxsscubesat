import mysql.connector
import datetime
import numpy
import sys
import os
import math
import time
import minxss_db
import gpstime
from enum import Enum
#<*************** How to use this program and what it does *******************>
#
#</***************************************************************************>


#<*************** TODO ITEMS: *******************>
#
# Goes X-ray Irradiance: LONG, 10E-8, B (if there's A and B)
#
#</**********************************************>

leapseconds = 17

#Get the current working directory, save it to global var
mydir = os.path.dirname(__file__)
if(len(mydir) == 0):
    mydir = os.getcwd()

#definitions of packet boundaries (so we can handle rollovers)
#SCI: 1-14 packets per record (record = 7 sectors)     logged every 10 secs
#SD read/write offsets are by the sector, which means only every 7th sector is a record
#if many packets/record, GPS time should be close, so can probably count that way
#Note that when doing Hydra commands, "step" is in SCI records, and offset is SD offsets
sd_max = {  # all numbers are in SD sectors
    'hk': 392960, #2 packets per sector
    'sci': 6750205, # See above
    'adcs': 262144, #2 (ADCS1 and ADCS2, or ADCS3 and ADCS4, etc)
    'log': 131072, #8 packets per sector
    'diag': 131072,
    'ximg': 131072} #2

#define how many sd offsets we expect per packet (TODO: Finalize this)
offsets_per_pkt = {
    'hk': 3,
    'sci': 2,
    'adcs': 4,
    'log': .2,
    'diag': 1,
    'ximg': 1}

#if GPS_time is not input, or is -1, this function returns the SD offsets corresponding
#to the min and max times in the dataset. This data is not likely that useful for ADCS since it rolls
#over frequently
def nearby_sd_offsets(db,pkt_type,GPS_time=-1):
    cursor = db.cnx.cursor()
    firstline = "SELECT GPS_time, " + str.upper(pkt_type) + "_SD_write FROM hk"
    if(GPS_time > 0):
        query1 = firstline + "\n WHERE GPS_time <= %(t)s"
        query2 = firstline + "\n WHERE GPS_time >= %(t)s"
        data = {"t": GPS_time}
    else:
        query1 = firstline
        query2 = firstline
        data = {}

    query1 += """
        ORDER BY GPS_time DESC
        LIMIT 0, 1"""
    query2 += """
        ORDER BY GPS_time ASC
        LIMIT 0, 1"""

    cursor.execute(query1, data)
    warnings = cursor.fetchwarnings()
    if warnings != None:
        print('Warnings on query:', warnings)
    val = cursor.fetchone()
    time_lower = val[0]
    sd_offset_lower = val[1]

    cursor.execute(query2, data)
    warnings = cursor.fetchwarnings()
    if warnings != None:
        print('Warnings on query:', warnings)
    val = cursor.fetchone()
    time_higher = val[0]
    sd_offset_higher = val[1]

    #print("sd offset lower: " + str(sd_offset_lower))
    #print("sd offset higher: " + str(sd_offset_higher))
    return [time_lower,time_higher] , [sd_offset_lower,sd_offset_higher]

################################################################################
# This function interpolates between two time inputs ("times") and two offset inputs ("offsets")
# in order to estimate the SD offset at time "tmid". The last input just says whether or not
# we're rounding up or down.
# NOTE: Not using the "up_or_down" input at the moment, feel free not to input it
# TODO: round science packet to nearest 7
def packet_interp(pkt_type, tmid, times, offsets, up_or_down="down"):
    if(offsets[0] > offsets[1]): #then we have a rollover situation
        offsets[1] = sd_max[pkt_type] + offsets[1]

    if times[0] == times[1] or offsets[0] == offsets[1]:
        return offsets[0]

    times = (float(times[0]),float(times[1]))
    slope = (offsets[1] - offsets[0])/(times[1] - times[0])
    est_offset = (tmid-times[0])*slope + offsets[0]
    est_offset = round(est_offset)
    # if up_or_down == "down":
        # est_offset = int(est_offset)
    # elif up_or_down == "up":
        # est_offset = math.ceil(est_offset)
    # else:
        # raise Exception("Input 'up_or_down' must be 'up' or 'down' not '" + up_or_down + "'")

    #Handle rollovers again:
    if(est_offset > sd_max[pkt_type]):
        return est_offset - sd_max[pkt_type]
    else:
        return est_offset


# ******** packet_count *******
# In: db, which is a database connection of class minxss_db
# In: pkt_type, which can be: "hk", "log", "sci", "adcs", "ximg" or "diag"
# In: OPTIONAL: t0 (initial time) and t1 (final time)
# If the optional inputs are not included, the query will return a count of ALL packets in that database
# Returns the number of packets we have in between those times
# Also returns an estimate of the number of SD offsets exist between those two times (exact for HK)
def packet_count(db, pkt_type, t0=-1, t1=-1):
    cursor = db.cnx.cursor() #(named_tuple=True,buffered=True)

    if(t0 > 0 and t1 > 0):
        limited_range = 1
    else:
        limited_range = 0

    query = "SELECT COUNT(*) FROM " + pkt_type
    if(limited_range):
        query += "\n WHERE GPS_time >= %(t0)s AND GPS_time <= %(t1)s"
        data = {
            "t0":str(t0),
            "t1":str(t1)
            }
    else:
        data = {}

    cursor.execute(query, data)
    warnings = cursor.fetchwarnings()
    if warnings != None:
        print('Warnings on query:', warnings)
    val = cursor.fetchone()
    if(len(val)>0):
        pkt_count = val[0]
    else:
        pkt_count = 0

    cursor.close()


    t0_times, t0_offsets = nearby_sd_offsets(db,pkt_type,t0)
    t1_times, t1_offsets = nearby_sd_offsets(db,pkt_type,t1)
    if(limited_range):
        offset_est0 = packet_interp(pkt_type, t0, t0_times, t0_offsets)
        offset_est1 = packet_interp(pkt_type, t1, t1_times, t1_offsets)
    else:
        offset_est0 = t0_offsets[0]
        offset_est1 = t1_offsets[1]

    # print (offset_est1, t1_times, t1_offsets, t1)
    # print (offset_est0, t0_times, t0_offsets, t0)

    offset_count = offset_est1 - offset_est0
    if(offset_count < 0):
        offset_count += sd_max[pkt_type]

    return pkt_count, offset_count

def test_random_stuff():
    print("*********** Starting MinXSS Data Report Script (TEST) *************")
    min_time = 1104157619.05
    max_time = 1125411077.049
    t0 = 1125189024.293
    t1 = 1125189267.392 #10 HK packets
    t1 = 1125194280.697 #100 HK packets
    #t0 -=30
    #t1 +=30
    t0 = 1124897638.7670000 - 40
    t1 = t0 + 60*60*24*2

    db = minxss_db.minxss_db()

    #def UTCFromGps(gpsWeek, SOW, 17):
    #return (year, month, day, hh, mm, ss + secFract)

    t0_utc = gpstime.UTCFromGps(t0, leapseconds)
    gps_secs_back_t0 = gpstime.gpsFromUTC(t0_utc[0],t0_utc[1],t0_utc[2],t0_utc[3],t0_utc[4],t0_utc[5], leapseconds)
    print("t0: ", t0)
    print("t0: ", t0_utc)
    print("t0: ", gps_secs_back_t0)
    t1_utc = gpstime.UTCFromGps(t1, leapseconds)
    gps_secs_back_t1= gpstime.gpsFromUTC(t1_utc[0],t1_utc[1],t1_utc[2],t1_utc[3],t1_utc[4],t1_utc[5], leapseconds)
    print("t1: ", t1)
    print("t1: ", t1_utc)
    print("t1: ", gps_secs_back_t1)

    pkt_count,offset_count = packet_count(db,"hk",t0,t1)
    print("HK pkt/offset Count: " + str(pkt_count) + " / " + str(offset_count))
    if(pkt_count > 0 and offset_count > 0):
        print("Density: " + str(pkt_count/offset_count) + " -- reversed: " + str(offset_count/pkt_count))

    pkt_count,offset_count = packet_count(db,"sci", t0,t1)
    print("SCI pkt/offset Count: " + str(pkt_count) + " / " + str(offset_count))
    if(pkt_count > 0 and offset_count > 0):
        print("Density: " + str(pkt_count/offset_count) + " -- reversed: " + str(offset_count/pkt_count))

    pkt_count,offset_count = packet_count(db,"log", t0,t1)
    print("LOG pkt/offset Count: " + str(pkt_count) + " / " + str(offset_count))
    if(pkt_count > 0 and offset_count > 0):
        print("Density: " + str(pkt_count/offset_count) + " -- reversed: " + str(offset_count/pkt_count))

    pkt_count,offset_count = packet_count(db,"adcs", t0,t1)
    print("ADCS pkt/offset Count: " + str(pkt_count) + " / " + str(offset_count))
    if(pkt_count > 0 and offset_count > 0):
        print("Density: " + str(pkt_count/offset_count) + " -- reversed: " + str(offset_count/pkt_count))

#t0_utc and t1_utc should be a tuple of (yr, mon, day, hr, min, sec)
def plot_data_density(pkt_type, t0_utc, t1_utc, tstep_minutes):
    #convert time inputs to GPS seconds
    gps_secs_back_t0 = gpstime.gpsFromUTC(t0_utc[0],t0_utc[1],t0_utc[2],t0_utc[3],t0_utc[4],t0_utc[5], leapseconds)
    gps_secs_back_t1= gpstime.gpsFromUTC(t1_utc[0],t1_utc[1],t1_utc[2],t1_utc[3],t1_utc[4],t1_utc[5], leapseconds)



def main(script):
    test_random_stuff()

if __name__ == '__main__':
    #Note that sys.argv[0] is equal to the filename
    main(*sys.argv)
    # if(len(sys.argv) == 3):
        # main(sys.argv[1],sys.argv[2])
    # else:
        # main(sys.argv[1])