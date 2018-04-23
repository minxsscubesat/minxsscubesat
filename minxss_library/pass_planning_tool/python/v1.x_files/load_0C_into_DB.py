from scipy.io.idl import readsav
import minxss_db
import datetime
import numpy
import sys
import os
#<*************** How to use this program and what it does *******************>
# This program loads all L0C IDL .sav files from an input directory and writes them to the mySQL database.
#
# First, make sure you have Anaconda (Python 3.4) installed, with the mysql python connector driver. See:
# https://docs.google.com/a/colorado.edu/document/d/1mbyMm2yNy1-JC3QFmhnVnUwmzUlb8AxMP_1QRdGZ1yI/edit?usp=sharing
#
# If calling from the command line, use a command like:
# python load_0C_into_DB.py "C:\dropbox\path\to\folder\containing\IDL\files"
#
# If calling from the python interpreter, make sure this folder is included in your PYTHONPATH. Then, run these commands:
# import load_0C_into_DB
# load_0C_into_DB.main("C:\dropbox\path\to\folder\containing\IDL\files")
#
# NOTE: If you want to delete and re-create the mySQL database, add an argument "restart" to your function call. Depending
# on which environment you're calling from, you would use one of these commands. WARNING: This is irreversable. Don't use
# this command lightly.
# python load_0C_into_DB.py "C:\dropbox\path\to\folder\containing\IDL\files" "restart"
# load_0C_into_DB.main("C:\dropbox\path\to\folder\containing\IDL\files","restart")
#
#
#</***************************************************************************>


#<*************** TODO ITEMS: *******************>
#
# Add 46 character text field to LOG message to store the text for it as well
#
# Where do I get "is_eclipse" data?
#
# I need some data that is representative of what I'll get (e.g. a 10-minute pass) -- where do I get that?
#
# How to deal with ADCS being in 4 different packets? (!)
#
# What is "TIME_OFFSET"?
# Example of "TIME": 1125189024.2930000 (GPS seconds)
#
# ADCS data only lives a day and a half... do we even care about the SD card offsets?
# We could just use the HK-reported write/read offsets and grab data over that range at some specified decimation
#
#</**********************************************>

#Get the current working directory, save it to global var
mydir = os.path.dirname(__file__)
if(len(mydir) == 0):
    mydir = os.getcwd()
#print("directory = " + mydir)


#This script takes in a data directory on your computer and loads all IDL .sav files from it into the database
#Set the second argument equal to "restart" if you want to delete/re-create the tables
def main(data_dir,is_restart=""):
    db = minxss_db.minxss_db()

    if(is_restart == "restart"):
        print("Deleting and re-creating mySQL database tables")
        db.delete_tables()
        db.create_tables()

    #data_dir = "C:\dropbox\minxss\data\L0C"

    print("Using data directory: " + data_dir)

    filenames = os.listdir(data_dir)
    for L0C_file in filenames:

        #L0C_filename = "C:\dropbox\minxss\data\minxss1_l0c_2015_245.sav"
        #L0C_filename = "C:\dropbox\minxss\data\L0C\minxss1_l0c_2015_001.sav"
        #sys.exit()

        print("Reading IDL .sav file '" + L0C_file + "' at time", datetime.datetime.now().time() )
        filepath = data_dir + "\\" + L0C_file
        try:
            data = readsav(filepath)
            print("Done reading IDL .sav file at time", datetime.datetime.now().time())
        except:
            print("File '" + L0C_file + "' is not an IDL .sav file!")
            continue #go to the next iteration of the for loop

        hk = minxss_db.hk_table()
        sci = minxss_db.sd_db_table()
        log = minxss_db.sd_db_table()
        adcs = minxss_db.adcs_table()
        ximg = minxss_db.sd_db_table()
        diag = minxss_db.sd_db_table()

        try:
            hk.populate(data.HK)
            hk.exists = True
        except:
            print("No HK data in this file")

        try:
            sci.populate(data.SCI)
            sci.exists = True
        except:
            print("No SCI data in this file")

        try:
            log.populate(data.LOG)
            log.exists = True
        except:
            print("No LOG data in this file")

        try:
            adcs.populate(data.ADCS1,1)
            adcs.exists = True
        except:
            print("No ADCS1 data in this file")

        try:
            adcs.populate(data.ADCS2,2)
            adcs.exists = True
        except:
            print("No ADCS2 data in this file")

        try:
            adcs.populate(data.ADCS3,3)
            adcs.exists = True
        except:
            print("No ADCS3 data in this file")

        try:
            adcs.populate(data.ADCS4,4)
            adcs.exists = True
        except:
            print("No ADCS4 data in this file")

        data = 0 #clear out unneeded data

        if(hk.exists): hk.write_to_db(db.cnx,"hk")
        if(sci.exists): sci.write_to_db(db.cnx,"sci")
        if(log.exists): log.write_to_db(db.cnx,"log")
        if(adcs.exists): adcs.write_to_db(db.cnx,"adcs")
        print("Done writing to mySQL DB at time", datetime.datetime.now().time())

    db.close()



if __name__ == '__main__':
    #Note that sys.argv[0] is equal to the filename
    if(len(sys.argv) == 3):
        main(sys.argv[1],sys.argv[2])
    else:
        main(sys.argv[1])