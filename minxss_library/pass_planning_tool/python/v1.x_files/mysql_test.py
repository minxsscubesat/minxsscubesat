#import os
#os.system("python_setup_batch_script.bat")


# Don't need to import IDL because we have readsav!
#from idlpy import IDL
import mysql.connector
from scipy.io.idl import readsav
import datetime
import numpy
import sys

L0C_filename = "C:\dropbox\minxss\data\minxss1_l0c_2015_245.sav"
#L0C_filename = "C:\dropbox\minxss\data\L0C\minxss1_l0c_2015_001.sav"

#<*************** TODO ITEMS: *******************>

# Where do I get "is_eclipse" data?

# I need some data that is representative of what I'll get (e.g. a 10-minute pass) -- where do I get that?

# How to deal with ADCS being in 4 different packets? (!)

# What is "TIME_OFFSET"?
# Example of "TIME": 1125189024.2930000 (GPS seconds)

# ADCS data only lives a day and a half... do we even care about the SD card offsets?
# We could just use the HK-reported write/read offsets and grab data over that range at some specified decimation

#</*************** TODO ITEMS: *******************>

#This doesn't work, not sure why
'''
arr = [0,1,2,3,4,4,3,2,1,0]
p = IDL.plot(arr,title='IDL plot yo')
p.color = 'red'
p.save('IDLplot_made_in_python.pdf')
p.close()
'''


#CDH info -- use value & 0x08 to determine is_eclipse flag

class hk_struct:
    def __init__(self):
        self.GPS_time = []
        self.HK_SD_write = []
        self.SCI_SD_write = []
        self.LOG_SD_write = []
        self.LOG_SD_read = []
        self.ADCS_SD_write = []
        self.XIMG_SD_write = []
        self.DIAG_SD_write = []
        self.is_eclipse = []
        self.UTC_rx_time = []
        self.UTC_log_time = []

class sci_struct:
    def __init__(self):
        self.GPS_time = []

class log_struct:
    def __init__(self):
        self.GPS_time = []

class adcs_struct:
    def __init__(self):
        self.GPS_time1 = []
        self.GPS_time2 = []
        self.GPS_time3 = []
        self.GPS_time4 = []

class ximg_struct:
    def __init__(self):
        self.GPS_time = []

class diag_struct:
    def __init__(self):
        self.GPS_time = []

hk = hk_struct()
sci = sci_struct()
log = log_struct()
adcs = adcs_struct()
ximg = ximg_struct()
diag = diag_struct()

print(datetime.datetime.now().time())
data = readsav(L0C_filename)
print(datetime.datetime.now().time())

try:
    hk.GPS_time = data.HK.TIME.tolist()
    hk_len = len(hk.GPS_time)
    hk.HK_SD_write = data.HK.SD_HK_WRITE_OFFSET.tolist()
    hk.SCI_SD_write = data.HK.SD_SCI_WRITE_OFFSET.tolist()
    hk.LOG_SD_write = data.HK.SD_LOG_WRITE_OFFSET.tolist()
    hk.LOG_SD_read = data.HK.SD_LOG_READ_OFFSET.tolist()
    hk.ADCS_SD_write = data.HK.SD_ADCS_WRITE_OFFSET.tolist()
    hk.XIMG_SD_write = data.HK.SD_XIMG_WRITE_OFFSET.tolist()
    hk.DIAG_SD_write = data.HK.SD_DIAG_WRITE_OFFSET.tolist()
    #hk.is_eclipse = data.is_eclipse TODO: uncomment when ready
    hk.is_eclipse = data.HK.CDH_INFO.tolist()
    hk.is_eclipse = [(cdh_info & 0x08) >> 3 for cdh_info in hk.is_eclipse]
    hk.UTC_rx_time = [0] * hk_len
    hk.UTC_log_time = [0] * hk_len #TODO: Make this real data
except:
    pass

try:
    sci.GPS_time = data.SCI.TIME
except:
    pass

try:
    log.GPS_time = data.LOG.TIME
except:
    pass

try:
    adcs.GPS_time1 = data.ADCS1.TIME
    adcs.GPS_time2 = data.ADCS1.TIME
    adcs.GPS_time3 = data.ADCS1.TIME
    adcs.GPS_time4 = data.ADCS1.TIME
except:
    pass

try:
    ximg.GPS_time = data.XIMG.TIME
except:
    pass

try:
    diag.GPS_time = data.DIAG.TIME
except:
    pass

data = 0 #clear out unneeded data
print(type(hk.GPS_time[1]))
print(type(hk.HK_SD_write[1]))
print(type(hk.SCI_SD_write[1]))
print(type(hk.LOG_SD_write[1]))
print(type(hk.LOG_SD_read[1]))
print(type(hk.ADCS_SD_write[1]))
print(type(hk.XIMG_SD_write[1]))
print(type(hk.DIAG_SD_write[1]))
print(type(hk.is_eclipse[1]))
print(type(hk.UTC_rx_time[1]))
print(type(hk.UTC_log_time[1]))
#sys.exit()

'''
is_match = 0;
ind_i = -1
ind_j = -1
for i in range(hk_len):
    for j in range(i+1,hk_len):
        if hk.GPS_time[i] == hk.GPS_time[j]:
            is_match = 1
            ind_i = i
            ind_j = j
print("If 1, we have a match:", is_match, "at indices (", ind_i, ind_j, ")")
'''

ind1 = 0
ind2 = 10
print("IDL data")
print("HK offsets", hk.HK_SD_write[ind1:ind2])
print("Is eclipse", hk.is_eclipse[ind1:ind2])
print("HK time", hk.GPS_time[ind1:ind2])
print("SCI time", sci.GPS_time[ind1:ind2])
print("LOG time", log.GPS_time[ind1:ind2])
print("ADCS 1 time", adcs.GPS_time1[ind1:ind2])
print("ADCS 2 time", adcs.GPS_time2[ind1:ind2])
print("ADCS 3 time", adcs.GPS_time3[ind1:ind2])
print("ADCS 4 time", adcs.GPS_time4[ind1:ind2])
print("XIMG time", ximg.GPS_time[ind1:ind2])
print("DIAG time", diag.GPS_time[ind1:ind2])


#Things I need:
# GPS seconds
# SD card address (HK only)
# Eclipse? [HK only?]

#may need to calc: UTC date/time, received time
#populate with zeros init: Have rcvd data?

cnx = mysql.connector.connect(user='root', password='minxsscubesat', host='macl68.lasp.colorado.edu', database='minxss_sdcard_db')
cnx.get_warnings = True
cursor = cnx.cursor(named_tuple=True,buffered=True)

data = list(zip(
    hk.GPS_time,
    hk.HK_SD_write,
    hk.SCI_SD_write,
    hk.LOG_SD_write,
    hk.LOG_SD_read,
    hk.ADCS_SD_write,
    hk.XIMG_SD_write,
    hk.DIAG_SD_write,
    hk.is_eclipse,
    hk.UTC_rx_time,
    hk.UTC_log_time
    ))

query = ("""
    INSERT INTO hk
    (GPS_time, HK_SD_write, SCI_SD_write, LOG_SD_write, LOG_SD_read, ADCS_SD_write,
    XIMG_SD_write, DIAG_SD_write, is_eclipse, UTC_rx_time, UTC_log_time)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    ON DUPLICATE KEY UPDATE
        HK_SD_write = VALUES(HK_SD_write),
        SCI_SD_write = VALUES(SCI_SD_write),
        LOG_SD_write = VALUES(LOG_SD_write),
        LOG_SD_read = VALUES(LOG_SD_read),
        ADCS_SD_write = VALUES(ADCS_SD_write),
        XIMG_SD_write = VALUES(XIMG_SD_write),
        DIAG_SD_write = VALUES(DIAG_SD_write),
        is_eclipse = VALUES(is_eclipse),
        UTC_rx_time = VALUES(UTC_rx_time),
        UTC_log_time = VALUES(UTC_log_time)
    """)
print(query)

cursor.executemany(query,data)
#print(cursor_write.statement)
print('Warnings on write:', cursor.fetchwarnings() )
cnx.commit()
cursor.close()
cnx.close()

print(datetime.datetime.now().time())

# print("")
# print("SQL data")

# val = cursor.fetchall()
# print(val)
# #print(Row.val.myindex)

# for row in val:
    # print(row.my_index, row.rand_num)

# print(datetime.datetime.now().time())