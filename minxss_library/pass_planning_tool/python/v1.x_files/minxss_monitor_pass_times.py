### Purpose:
# NOTE: To generate an exe for this script, see minxss_pass_automation_exe_gen.py
# 1) updates the Hydra auto-run script based on the pass current time/date (by copying an already-created file)
# 2) Closes and re-launches SATPC32
# 3) Closes and re-launches Hydra
# 4) Renames the script that got run from "*.prc" to "wasrun_*.prc"



#Note: Some of these packages are not needed. TODO: Trim them down....
import packaging.version #required to build, not to run
import packaging.specifiers #required to build, not to run
import six
import time
from shutil import copyfile
import os
import sys
from scipy.io.idl import readsav
import scipy.integrate
import scipy.linalg
#import scipy
from scipy.sparse.csgraph import _validation
import datetime
import jdcal
import minxss_email
import rundir_analysis
from minxss_time import now_in_jd
from subprocess import Popen
import psutil

mydir = os.path.dirname(__file__)
if(len(mydir) == 0):
    mydir = os.getcwd()

## SETTINGS ##
#See pass_config.py

class monitor():
    #is_mon_hydra, is_run_hydra_scripts, is_update_satpc_tle, computer_name
    def __init__(self, cfg):
        self.cfg = cfg
        #initialize error class
        self.email = minxss_email.email(self.cfg)
        #store a variable for whether or not we're in a pass
        self.is_in_pass = 0
        self.satpc_dir = os.getenv('SATPC32_dir','SATPC32_dir__ENV_VAR_DOES_NOT_EXIST')
        self.hydra_dir = os.getenv('Hydra_dir','Hydra_dir__ENV_VAR_DOES_NOT_EXIST')
        self.satpc_tle_dir = os.getenv('SATPC_TLE_dir', 'SATPC_TLE_dir__ENV_VAR_DOES_NOT_EXIST')
        self.hydra_scripts = os.path.join(self.hydra_dir,'Scripts')
        if( not(os.path.exists(self.hydra_dir)) or not(os.path.exists(self.satpc_dir)) or not(os.path.exists(self.satpc_tle_dir)) ):
            print("One of these locations does not exist (hydra exe, satpc exe, and/or satpc tle directories):")
            print(self.hydra_dir)
            print(self.satpc_dir)
            print(self.satpc_tle_dir)
            self.email("NoFile",self.cfg.computer_name)

        self.hydra_script_dest_file = os.path.join(self.hydra_scripts, 'script_to_run_automatically_on_hydra_boot.prc')
        self.hydra_script_src_folder = os.path.join(self.hydra_scripts, 'scripts_to_run_automatically')
        self.default_pass_script = "default_auto_script.prc"

        self.satpc32_exe = exe_management(self.satpc_dir,'SatPC32.exe')
        self.satpc32_server_exe = exe_management(self.satpc_dir,'ServerSDX.exe')
        self.hydra_exe = exe_management(self.hydra_dir,'Hydra.exe')
        self.wasrun_scriptloc = ""
        self.tle_contents = None


    def __call__(self,number):
        running_default = 0 #flag to keep track of whether we're doing the default thing

        passes_idl_file = os.path.join(os.getenv('TLE_dir', 'TLE_dir__ENV_VAR_DOES_NOT_EXIST') , 'pass_saveset')
        passes_idl_file = os.path.join(passes_idl_file,'minxss_passes_latest.sav')
        #print("Reading from IDL file: ",passes_idl_file) #enable if needed for debugging

        try:
            idl_data = readsav(passes_idl_file)
        except:
            print("File '" + passes_idl_file + "' is not an IDL .sav file!")
            self.email("NoFile",self.cfg.computer_name)

        # print(idl_data.PASSES.START_JD)
        # DURATION_MINUTES	10.349999
        # END_DATE	2016032.0851736106
        # END_JD	2457419.5851736111
        # END_TIME	7358.9999556541443
        # MAX_DATE	2016032.0815972220
        # MAX_ELEVATION	38.373653
        # MAX_JD	2457419.5815972220
        # MAX_TIME	7049.9999821186066
        # START_DATE	2016032.0779861109
        # START_JD	2457419.5779861109
        # START_TIME	6737.9999846220016
        # SUNLIGHT	0

        #pass info from pre-pass calcs (elevation, length, etc)

        #Make sure we have a script to run (otherwise send an email!)
        #don't run scripts for Jim's machine
        if(self.cfg.do_run_hydra_scripts==1):
            scriptnamelist = [f for f in os.listdir(self.hydra_script_src_folder) if os.path.isfile(os.path.join(self.hydra_script_src_folder,f))]
            scriptnamelist.sort()
            while(not(".prc" in scriptnamelist[0]) and len(scriptnamelist)>0): #skip non .prc files
                del scriptnamelist[0]

            nextscriptfilename = scriptnamelist[0];
            if("default" in nextscriptfilename or "was_run" in nextscriptfilename):
                self.email("NoPassScript",self.cfg.computer_name)
                print("No prepared next script available! Next script found: ",nextscriptfilename)


        [pass_index,minutes] = self.minutes_until_next_pass(idl_data.PASSES.START_JD.tolist())
        #store info on the incoming pass
        self.email.elevation = idl_data.PASSES.MAX_ELEVATION.tolist()[pass_index]
        self.email.length_minutes = idl_data.PASSES.DURATION_MINUTES.tolist()[pass_index]
        self.email.sunlight = idl_data.PASSES.SUNLIGHT.tolist()[pass_index]

        print("v2.0 {0}: Next pass in {1} min // El: {2} deg. // Len: {3} min. // Sun: {4}".format(self.cfg.computer_name, round(minutes,2), round(self.email.elevation,2), round(self.email.length_minutes,2), self.email.sunlight))

        if(self.cfg.enable_rapidfire_test==1):
            print("Running pass regardless of IDL, since self.cfg.enable_rapidfire_test=1")
            minutes = 1

        if(minutes < self.cfg.setup_minutes_before_pass):
            print("Pass about to start!")
            if(self.cfg.do_send_prepass_email==1):
                self.email("PassAboutToOccur",self.cfg.computer_name)

            #Figure out what the next Hydra script to run is
            if(self.cfg.do_run_hydra_scripts==1):
                scriptnamelist = [f for f in os.listdir(self.hydra_script_src_folder) if os.path.isfile(os.path.join(self.hydra_script_src_folder,f))]
                scriptnamelist.sort()
                #for f in scriptnamelist:
                #    print(f) #TODO: Delete this, just for debug
                while(not(".prc" in scriptnamelist[0]) and len(scriptnamelist)>0): #skip non .prc files
                    print("Ignoring file in scripts_to_run_automatically folder: " + scriptnamelist[0])
                    del scriptnamelist[0]

                nextscriptfilename = scriptnamelist[0];
                if("default" in nextscriptfilename or "was_run" in nextscriptfilename):
                    self.email("NoPassScript",self.cfg.computer_name)
                    hydra_script_src_file = os.path.join(self.hydra_script_src_folder, self.default_pass_script)
                    running_default = 1
                else:
                    hydra_script_src_file = os.path.join(self.hydra_script_src_folder, nextscriptfilename)
                    running_default = 0
                self.email.StoreScriptName(hydra_script_src_file)

                #Check to make sure the file exists
                if(not(os.path.exists(hydra_script_src_file))):
                    print("Hydra default script does not exist!!! Expected path:")
                    print(hydra_script_src_file)
                    self.email("NoFile",self.cfg.computer_name)
                else:
                    print("Running Hydra script: ", hydra_script_src_file)
                    #Copy the file over, then rename it to wasrun_"".prc
                    copyfile(hydra_script_src_file, self.hydra_script_dest_file)
                    wasrundest = os.path.join(self.hydra_script_src_folder, "was_run") #this is just the folder still
                    #Now create the directory if it doesn't exist
                    try:
                        os.stat(wasrundest)
                    except:
                        os.mkdir(wasrundest)
                    #add the actual file name
                    wasrundest = os.path.join(wasrundest, "was_run_" + nextscriptfilename)
                    #If we run scripts with exactly the same name, give them uniquifiers (should not generally happen except when running default case)
                    i = 2 #start at 2 for "2nd time"
                    while(os.path.exists(wasrundest)):
                        wasrundest = os.path.join(self.hydra_script_src_folder, "was_run_" + str(i) + "_" + nextscriptfilename)
                        i = i + 1

                    if(running_default == 0):
                        os.rename(hydra_script_src_file, wasrundest)
                    else:
                        #don't rename if it's the default, but we do want to track that we ran the default
                        copyfile(hydra_script_src_file, wasrundest)
                    #store the script location so it can be emailed
                    self.email.StoreScriptLocation(wasrundest)
                    self.wasrun_scriptloc = wasrundest

            if(self.cfg.do_update_satpc_tle==1):
                satpc_tle_file_dropbox = os.path.join(os.getenv('TLE_dir', 'TLE_dir__ENV_VAR_DOES_NOT_EXIST') , 'minxss.tle')
                if(os.path.exists(self.satpc_tle_dir) and os.path.exists(satpc_tle_file_dropbox)):
                    satpc_tle_file_dest = os.path.join(self.satpc_tle_dir, 'minxss.tle')
                    copyfile(satpc_tle_file_dropbox, satpc_tle_file_dest)
                    print("Copying TLE from:")
                    print(satpc_tle_file_dropbox)
                    print("TO:")
                    print(self.satpc_tle_dir)
                else:
                    print("One of these locations does not exist:")
                    print(satpc_tle_file_dropbox)
                    print(self.satpc_tle_dir)
                    self.email("NoFile",self.cfg.computer_name)

            if(self.cfg.disable_restart_programs == 0):
                #Normally we only reset SATPC32 if there's a new TLE.
                #However, if we think SATPC32 is not running, kill the process just in case it does exist so that we have a handle on it
                if(self.check_if_new_tle()==1 or self.satpc32_exe.is_running() == 0):
                    print("******************************* New TLE info (or exe not running)!! Restarting SATPC *******************************")
                    self.satpc32_exe.kill()
                    time.sleep(5)
                    self.satpc32_server_exe.kill()
                if(self.cfg.do_monitor_hydra==1):
                    time.sleep(5)
                    self.hydra_exe.kill()
                #done terminating processes, now enable them
                time.sleep(10)
                #only start satpc if it's not running
                if(self.satpc32_exe.is_running() == 0):
                    self.satpc32_exe.start()
                if(self.cfg.do_monitor_hydra==1):
                    time.sleep(5)
                    self.hydra_exe.start()

            return(1) #indicate that there was a pass
        else:
            return(0) #no pass occurred

    #restarts Hydra
    def KillHydra(self):
        print("Killing the Hydra process!")
        time.sleep(1)
        self.hydra_exe.kill()
        time.sleep(1)




    def check_if_new_tle(self):
        current_tle_data = ""
        #get the file data
        satpc_tle_file_dest = os.path.join(self.satpc_tle_dir, 'minxss.tle')
        if(os.path.exists(satpc_tle_file_dest)):
            fileHandle = open(satpc_tle_file_dest, 'r')
            current_tle_data = fileHandle.read()
            fileHandle.close()
        else:
            return 1 # if we don't have the file path we have to assume it updates every time (also there was already an email sent)

        if(self.tle_contents == None):
            self.tle_contents = current_tle_data
            return 1
        else:
            if(len(self.tle_contents) == len(current_tle_data)):
                #if the lengths match, check each character
                i = 0
                for char in self.tle_contents:
                    if(char != current_tle_data[i]):
                        self.tle_contents = current_tle_data
                        return 1
                    else:
                        i += 1
            else:
                self.tle_contents = current_tle_data
                return 1

        self.tle_contents = current_tle_data
        #if we made it here, we're good to go
        return 0


    # Takes a list of start times (in Julian date) and returns the number of minutes until the next one arrives
    # Assumes the list is sorted
    def minutes_until_next_pass(self,start_times):
        ind = 0
        now_jd = now_in_jd() # in fractional days
        #print("current time",now_jd)
        #print("current time in UTC",datetime.datetime.utcnow())
        tdiff = -1
        for start_time in start_times:
            #find the first time in the list that's in the future
            tdiff = start_time - now_jd
            if(tdiff > 0):
                #print("Next pass:",start_time)
                break
            ind += 1

        if tdiff < 0:
            self.email("NoPassTimes",self.cfg.computer_name)
            minutes = 99999 #Just a large value so that we don't do anything
            ind -= 1 #this index ends up being outside of the array size if it doesn't find a pass
        else:
            minutes = tdiff*24*60 #tdiff is in fractions of a julian day
        return [ind,minutes]

    #gets a path to the rundir for the current pass and then has it analyzed
    def PassAnalysis(self):
        rundirs_dir = os.path.join(self.hydra_dir, 'Rundirs')
        rundir_list = [f for f in os.listdir(rundirs_dir) if not(os.path.isfile(os.path.join(rundirs_dir,f)))]
        rundir_list.sort()

        #populate the path in the analysis object
        results = rundir_analysis.Rundir(os.path.join(rundirs_dir,rundir_list[-1]), os.path.basename(self.wasrun_scriptloc))

        #for debugging easily...
        #results = rundir_analysis.Rundir('C:\\Users\\Colden\\Desktop\\CU Boulder\\MinXSS\\ground_station_files\\updated rundirs\\2016_317_07_44_55', os.path.basename(self.wasrun_scriptloc))
        #results = rundir_analysis.Rundir('C:\\Users\\Colden\\Desktop\\CU Boulder\\MinXSS\\ground_station_files\\updated rundirs\\2016_317_09_22_26', os.path.basename(self.wasrun_scriptloc))

        results.Analyze()

        self.email.PassResults(results, self.cfg.computer_name)

class exe_management():
    def __init__(self,dir,name):
        self.process = None
        self.exec_dir = dir
        self.exec_name = name
        self.batch_kill_cmd = 'TASKKILL /f /IM ' + self.exec_name

    def start(self):
        self.process = Popen(os.path.join(self.exec_dir,self.exec_name), cwd=self.exec_dir)
        #batch_start_cmd = "start /D \"" + self.exec_dir + "\" \"" + os.path.join(self.exec_dir,self.exec_name) + "\""
        #batch_start_cmd = "start /D \"" + self.exec_dir + "\" " + self.exec_name
        #batch_start_cmd = "start C:\\Users\\Colden\\IDLWorkspace85\\minxss_colden_20151102\\src\\pass_planning_tool\\python\\start_satpc32.bat"
        #print(batch_start_cmd)
        #os.system(batch_start_cmd)

    def is_running(self):
        #Check to see if the process identifier exists
        if(self.process == None):
            return 0
        #check to see if the process identifier exists, but the process is not running
        elif(self.process.poll() != None):
            return 0
        #if neither of the above two, then it's running
        else:
            return 1


    def kill(self):
        terminated = 0 #did we kill the process?
        if(self.process != None):
            if(self.process.poll() == None): #Will be "None" if nothing has terminated the process
                self.process.terminate() #this is the nice way to terminate the process
                terminated = 1
        if(terminated == 0): #if the "nice" way didn't work, do it the sledgehammer way
            os.system(self.batch_kill_cmd)
            print("NOTE: 'SUCCESS' means we weren't tracking the process ID, and killed it with a sledgehammer, 'ERROR' means the process wasn't running.")

def main(script): #used for testing purposes only
    m = monitor(0,1,"colden comp")
    num = 0
    while(1):
        ispass = m(num)
        ispass = 0;
        if(ispass == 1):
            time.sleep(60*30) #sleep for 30 minutes - make sure we don't interfere with the next pass
            time.sleep(60*30) #sleep for 30 minutes - make sure we don't interfere with the next pass
        else:
            time.sleep(15) #sleep for 30 seconds if there wasn't a pass
        num = num+1

if __name__ == '__main__':
    main(*sys.argv)