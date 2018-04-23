import mysql.connector
from scipy.io.idl import readsav
import datetime
import sys

cnx = mysql.connector.connect(user='root', password='minxsscubesat', host='macl68.lasp.colorado.edu', database='minxss_sdcard_db')

cursor_write = cnx.cursor()
cursor_read = cnx.cursor(named_tuple=True,buffered=True)
cnx.get_warnings = True

with open("./sql/drop_tables.sql", 'r') as content_file:
    query_string = content_file.read()

print(query_string)


for result in cursor_write.execute(query_string, multi=True):
    print("results rx")

print(cursor_write.statement)
print('Warnings on write:', cursor_write.fetchwarnings() )
cnx.commit()
cursor_write.close()


cnx.close()


'''
cursor_read.execute("SELECT * FROM test")
print('Warnings on read:', cursor_read.fetchwarnings() )
val = cursor_read.fetchall()
cursor_read.close()
print(val)

for row in val:
    print(row.a, row.b)
'''

'''
query = 'INSERT INTO `minxss_sdcard_db`.`hk`'
query += '(`GPS_time`, `HK_SD_write`, `SCI_SD_write`, `LOG_SD_write`, `LOG_SD_read`, '
query += '`ADCS_SD_write`, `XIMG_SD_write`, `DIAG_SD_write`, `is_eclipse`, `UTC_rx_time`, `UTC_log_time`)'
query += ' VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
'''