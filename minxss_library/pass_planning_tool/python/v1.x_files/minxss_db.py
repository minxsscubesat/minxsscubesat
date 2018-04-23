import mysql.connector
import datetime
import numpy
import sys
import os
#<*************** How to use this program and what it does *******************>
#
# Import this module if you want access the mySQL database. Edit it if you want
# to add more features for accessing the mySQL database
#
#</***************************************************************************>

#Get the current working directory, save it to global var
mydir = os.path.dirname(__file__)
if(len(mydir) == 0):
    mydir = os.getcwd()
#print("directory = " + mydir)

class sd_db_table:
    def __init__(self):
        self.len = 0
        self.exists = False
        self.GPS_time = []
        self.UTC_log_time = []
    def populate(self,data):
        self.GPS_time.extend( data.TIME.tolist() ) #Append data to existing data
        self.len = len(self.GPS_time) #update the length variable
        self.UTC_log_time = [0] * self.len # TODO: Fix this
    def write_to_db(self,cnx,table_name):
        data = list(zip(
            self.GPS_time,
            self.UTC_log_time
            ))
        query = "INSERT INTO " + table_name
        query += ("""
            (GPS_time, UTC_log_time)
            VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE
                UTC_log_time = VALUES(UTC_log_time)
            """)
        cursor = cnx.cursor(named_tuple=True,buffered=True)
        cursor.executemany(query,data)
        warnings = cursor.fetchwarnings()
        if warnings != None:
            print('Warnings on write to ' + table_name + ':', warnings)
        cnx.commit()
        cursor.close()


class hk_table(sd_db_table):
    def __init__(self):
        sd_db_table.__init__(self)
        self.HK_SD_write = []
        self.SCI_SD_write = []
        self.LOG_SD_write = []
        self.LOG_SD_read = []
        self.ADCS_SD_write = []
        self.XIMG_SD_write = []
        self.DIAG_SD_write = []
        self.is_eclipse = []
        self.UTC_rx_time = []
    def populate(self,data): #takes in IDL data and turns it into a form consumable by the python-mySQL interface
        sd_db_table.populate(self,data)
        self.HK_SD_write.extend( data.SD_HK_WRITE_OFFSET.tolist() )
        self.SCI_SD_write.extend( data.SD_SCI_WRITE_OFFSET.tolist() )
        self.LOG_SD_write.extend( data.SD_LOG_WRITE_OFFSET.tolist() )
        self.LOG_SD_read.extend( data.SD_LOG_READ_OFFSET.tolist() )
        self.ADCS_SD_write.extend( data.SD_ADCS_WRITE_OFFSET.tolist() )
        self.XIMG_SD_write.extend( data.SD_XIMG_WRITE_OFFSET.tolist() )
        self.DIAG_SD_write.extend( data.SD_DIAG_WRITE_OFFSET.tolist() )
        #self.is_eclipse = data.is_eclipse TODO: uncomment when ready
        self.is_eclipse.extend( (cdh_info & 0x08) >> 3 for cdh_info in data.CDH_INFO.tolist() )
        self.UTC_rx_time = [0] * self.len
    def write_to_db(self,cnx,table_name):
        data = list(zip(
            self.GPS_time,
            self.HK_SD_write,
            self.SCI_SD_write,
            self.LOG_SD_write,
            self.LOG_SD_read,
            self.ADCS_SD_write,
            self.XIMG_SD_write,
            self.DIAG_SD_write,
            self.is_eclipse,
            self.UTC_rx_time,
            self.UTC_log_time
            ))
        query = "INSERT INTO " + table_name
        query += ("""
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
        cursor = cnx.cursor(named_tuple=True,buffered=True)
        cursor.executemany(query,data)
        #print(cursor_write.statement)
        warnings = cursor.fetchwarnings()
        if warnings != None:
            print('Warnings on write to ' + table_name + ':', warnings)
        cnx.commit()
        cursor.close()


#class sci_table(sd_db_table):
#Not needed, inherits everything from sd_db_table

#class log_table(sd_db_table):
#Not needed, inherits everything from sd_db_table

class adcs_table(sd_db_table):
    def __init__(self):
        sd_db_table.__init__(self)
        self.packet_type = []
    def populate(self,data,packet_num):
        sd_db_table.populate(self,data)
        self.packet_type.extend( [packet_num] * len(data.TIME.tolist()) ) #Fill in packet type for all this data
    def write_to_db(self,cnx,table_name):
        data = list(zip(
            self.GPS_time,
            self.packet_type,
            self.UTC_log_time
            ))
        query = "INSERT INTO " + table_name
        query += ("""
            (GPS_time, packet_type, UTC_log_time)
            VALUES (%s, %s, %s)
            ON DUPLICATE KEY UPDATE
                packet_type = VALUES(packet_type),
                UTC_log_time = VALUES(UTC_log_time)
            """)
        cursor = cnx.cursor(named_tuple=True,buffered=True)
        cursor.executemany(query,data)
        warnings = cursor.fetchwarnings()
        if warnings != None:
            print('Warnings on write to ' + table_name + ':', warnings)
        cnx.commit()
        cursor.close()

class minxss_db:
    def __init__(self):
        self.cnx = mysql.connector.connect(user='root', password='minxsscubesat', host='macl68.lasp.colorado.edu', database='minxss_sdcard_db')
        self.cnx.get_warnings = True

    def close(self):
        self.cnx.close()

    def delete_tables(self):
        self.__execute_query_from_file(os.path.join(mydir,"sql\\drop_tables.sql"),True)

    def create_tables(self):
        self.__execute_query_from_file(os.path.join(mydir,"sql\\create_table_hk.sql"),False)
        self.__execute_query_from_file(os.path.join(mydir,"sql\\create_table_sci.sql"),False)
        self.__execute_query_from_file(os.path.join(mydir,"sql\\create_table_adcs.sql"),False)
        self.__execute_query_from_file(os.path.join(mydir,"sql\\create_table_log.sql"),False)

    def __execute_query_from_file(self,filename,is_multi):
        with open(filename, 'r') as content_file:
            query_string = content_file.read()
        cursor = self.cnx.cursor()
        if(is_multi):
            for result in cursor.execute(query_string, multi=True):
                warnings = cursor.fetchwarnings()
                if warnings != None:
                    print('Warnings on write:', warnings)
        else:
            cursor.execute(query_string)
            warnings = cursor.fetchwarnings()
            if warnings != None:
                print('Warnings on write:', warnings)

        self.cnx.commit()
        cursor.close()


#class ximg_table(sd_db_table):
#Not needed, inherits everything from sd_db_table

#class diag_table(sd_db_table):
#Not needed, inherits everything from sd_db_table
