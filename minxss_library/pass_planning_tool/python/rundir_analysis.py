import os
import sys
import re #regex
import csv

class Rundir():
    def __init__(self,rundir_path,scriptname):
        self.rundir_path = rundir_path
        self.scriptname = scriptname
        self.eventlog_filepath = ""
        self.errors_array = []
        self.tlm_filepath = ""
        self.tlm_filename = "[no data downlinked]"
        self.csv_filepath = ""
        self.bytes_downlinked_data = 0
        self.csv_cmd_attempts_filename = 'cmd_attempts.csv'
        #self.csv_errors_filename = 'errors.csv' #NOTE: not used

    def Analyze(self,info,cfg):
        print("")
        print("")
        print("********************* Pass Results *********************")
        print("")

        files = os.listdir(self.rundir_path)
        #print(files)
        #figure out the tlm and eventlog filenames
        for filename in files:
            if 'EventLog_' in filename:
                self.eventlog_filepath = os.path.join(self.rundir_path, filename)
                self.csv_filepath = self.StoreInCSV(self.eventlog_filepath)
                self.errors_array = self.FindErrorLines(self.eventlog_filepath)
                #self.cmdTrySucceed_arr = self.FindcmdTrySucceed(self.eventlog_filepath)
            if 'tlm_packets_' in filename:
                self.tlm_filepath = os.path.join(self.rundir_path, filename)
                self.tlm_filename = filename
                self.bytes_downlinked_data = os.stat(self.tlm_filepath).st_size

        if(self.bytes_downlinked_data/1000 < cfg.min_expected_data and info.elevation >= cfg.elevation_to_expect_data):
            self.errors_array.append("ERROR: Expected to receive at least {0} kB of data for pass elevation {1}, but received {2} kB data!\r\n".format(cfg.min_expected_data, round(info.elevation,2), self.bytes_downlinked_data/1000))

        print("TLM filename:", self.tlm_filename, "-- Size: ", self.bytes_downlinked_data)
        print("")
        print("")
        print("********************* END of Pass Results *********************")
        print("")

    #store cmdTry and cmdSuccess counts in a CSV file, then returns the path to the csv file
    def StoreInCSV(self,filename):
        csv_filename = os.path.join(self.rundir_path, self.csv_cmd_attempts_filename)
        print('==================StoreInCSV=================')
        print(csv_filename)

        rundir_name = os.path.basename(self.rundir_path)

        with open(csv_filename, 'w',newline='') as csvfile:
            spamwriter = csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
            spamwriter.writerow(['RunDir Name','cmdTry Count','cmdSucceed Count','Script Name'])

            columncount = 0
            file = open(filename,'r')
            lines = file.readlines()
            #now we look for a group of lines. cmdTry: ##, then cmdSucceed: ##, then a line that describes what file was run
            for i in range(0,len(lines)):
                if 'cmdTry:' in lines[i]:
                    #find all the characters after "cmdTry: " (which is the number of cmdTrys)
                    m = re.search('(?<=cmdTry: )\w+', lines[i])

                    #set up the three columns we're capturing
                    cmdSucceed = ''
                    scriptname = ''

                    try:
                        cmdTry = m.group(0) #fails if it can't find the search string
                    except:
                        cmdTry = 'Could not find cmdTry count'

                    #go to the next line
                    i += 1
                    if 'cmdSucceed:' in lines[i]:
                        m = re.search('(?<=cmdSucceed: )\w+', lines[i])
                        try:
                            cmdSucceed = m.group(0)
                        except:
                            cmdSucceed = 'Could not find cmdSucceed count'

                    i += 1
                    if 'Done with script Scripts' in lines[i]:
                        m = re.search('(?<=Done with script Scripts).*', lines[i])
                        try:
                            scriptname = m.group(0)
                            scriptname = scriptname[1:] #ditch the backslash
                        except:
                            scriptname = 'Could not find scriptname'
                        if "script_to_run_automatically_on_hydra_boot.prc" in scriptname:
                            scriptname = self.scriptname

                    row = []
                    row.append(rundir_name)
                    row.append(cmdTry)
                    row.append(cmdSucceed)
                    row.append(scriptname)
                    spamwriter.writerow(row)

        return csv_filename


    def FindErrorLines(self,filename):
        lines_array = []
        with open(filename,'r') as file:
            for line in file:
                if 'error' in line.lower():
                    lines_array.append(line)
                    print(line[0:-1])
        return lines_array

    # def FindcmdTrySucceed(self,filename):
        # lines_array = []
        # with open(filename,'r') as file:
            # for line in file:
                # if 'cmdTry:' in line:
                    # print(line[0:-1])
                    # lines_array.append(line)
                # if 'cmdSucceed:' in line:
                    # print(line[0:-1])
                    # lines_array.append(line)
        # return lines_array


def main(script):
    folder = 'C:\\Users\\Colden\\Desktop\\CU Boulder\\MinXSS\\ground_station_files\\updated rundirs\\2016_317_07_44_55'
    results = Rundir(folder)
    results.Analyze()
    print("")
    print(results.eventlog_filepath)
    print("")
    print(results.errors_array)
    print("")
    print(results.tlm_filepath)
    print("")
    print(results.bytes_downlinked_data)

if __name__ == '__main__':
    main(*sys.argv)