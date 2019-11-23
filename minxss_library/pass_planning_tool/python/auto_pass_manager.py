### How to build:
# 0) Ensure the global variable define settings in this file and in "minxss_monitor_pass_times.py" are what you want
# 1) Open a command window here
# 2) Run this command:
#       pyinstaller auto_pass_manager.py -F -n auto_pass_manager_v2.0 --clean
# 3) *.exe goes to .\dist

# For settings, see pass_config.py

# Required to build, not to run
import time
from shutil import copyfile
import os
import sys
from scipy.io.idl import readsav
from subprocess import Popen
import signal

import minxss_email
import jd_utc_time
import pass_config
import rundir_analysis

from operator import attrgetter

mydir = os.path.dirname(__file__)
if len(mydir) == 0:
    mydir = os.getcwd()

test_pass_conflicts_enabled = 0


def main(script):  # This is what calls the minxss_monitor_pass_times code and sets it all up
    print("\r\n\r\n **************** Initializing Automatic Pass Manager (v2.0) ***************\r\n\r\n")
    p = PassManager()
    if p.cfg.use_satpc == 1:
        p.satpc_monitor()  # calling this twice because it creates a lot of junk in the console on startup
    print("\r\n\r\n **************** SETUP COMPLETED SUCCESSFULLY ***************\r\n\r\n")
    while 1:
        if p.cfg.use_satpc == 1:
            p.satpc_monitor()

        [minutes_before_pass, info_list] = p.get_next_pass_info()
        if minutes_before_pass <= p.cfg.setup_minutes_before_pass or p.cfg.enable_rapidfire_test == 1:
            # print a warning about ignored satellites
            if len(p.ignored_sats) > 0:
                txt = "\r\nWARNING: Ignoring the following satellites since they do not have config ini files: "
                for sat in p.ignored_sats:
                    txt += sat + ", "
                txt = txt[0:-2]
                print(txt)
            # If we have multiple adjacent passes, we should run them back-to-back.
            # Note that the sat pass manager automatically waits until the pass is complete before returning
            for pass_num in range(len(info_list)):
                if len(info_list) > 1 and pass_num < len(info_list)-1:
                    is_quick_exit = 1
                else:
                    is_quick_exit = 0
                p.sat_pass_managers[info_list[pass_num].sat_name].run_pass(info_list[pass_num], is_quick_exit)

        # check if we're less than a minute away, and if so, sleep for less
        elif minutes_before_pass-1 <= p.cfg.setup_minutes_before_pass:
            time.sleep((minutes_before_pass - p.cfg.setup_minutes_before_pass)*60)

        # otherwise, check in and print stuff out every 60 seconds
        else:
            time.sleep(60)


class PassManagerTests:
    def __init__(self):
        self.testnum = 0

    def test_add_pass_conflicts(self, pass_manager, info_list, idl_data_old):
        # Priorities for test: MINXSS1=5, MINXSS2=4, QB50=3

        info = MyPassInfo()
        idl_data = IdlDataClass()

        info.index = 0

        print("\r\n\r\n")
        print("********** Executing pass manager test #{0} **********".format(self.testnum))
        print("\r\n\r\n")

        if self.testnum == 0:
            # test moving a pass backward enough that the order changes
            idl_data.sat_names = ['MINXSS2', 'QB50', 'MINXSS1']
            idl_data.start_jd = [float(2), float(3), float(5)]
            idl_data.end_jd = [float(8), float(11), float(10)]
            # PASS - v2.0.90
        elif self.testnum == 1 :
            # test the "move on if sorting doesn't change it
            idl_data.sat_names = ['MINXSS2', 'QB50', 'MINXSS1']
            idl_data.start_jd = [float(2), float(3), float(9)]
            idl_data.end_jd = [float(8), float(11), float(15)]
            # PASS - v2.0.90
        elif self.testnum == 2:
            # identical start times, and testing a zero-length pass
            idl_data.sat_names = ['MINXSS2', 'QB50', 'MINXSS1']
            idl_data.start_jd = [float(2), float(2), float(2)]
            idl_data.end_jd = [float(6), float(5), float(4)]
            # PASS - v2.0.90
        elif self.testnum == 3:
            # mix up the order
            idl_data.sat_names = ['QB50', 'MINXSS1', 'MINXSS2']
            idl_data.start_jd = [float(2), float(3), float(5)]
            idl_data.end_jd = [float(8), float(11), float(10)]
            # PASS - v2.0.90
        elif self.testnum == 4:
            # mix up the order
            idl_data.sat_names = ['MINXSS1', 'QB50', 'MINXSS2']
            idl_data.start_jd = [float(2), float(3), float(5)]
            idl_data.end_jd = [float(8), float(11), float(10)]
            # PASS - v2.0.90
        elif self.testnum == 5:
            # mix up the order
            idl_data.sat_names = ['MINXSS1', 'MINXSS2', 'QB50']
            idl_data.start_jd = [float(2), float(3), float(5)]
            idl_data.end_jd = [float(8), float(11), float(10)]
            # PASS - v2.0.90
        else:
            print("INVALID TEST NUMBER")
            sys.exit()

        self.testnum += 1

        print("idl_data.start_jd init", idl_data.start_jd)
        for i in range(len(idl_data.start_jd)):
            idl_data.start_jd[i] = jd_utc_time.secs_to_jd(idl_data.start_jd[i]*10)
            idl_data.start_jd[i] += jd_utc_time.now_in_jd()
            idl_data.end_jd[i] = jd_utc_time.secs_to_jd(idl_data.end_jd[i]*10)
            idl_data.end_jd[i] += jd_utc_time.now_in_jd()
        print("idl_data.start_jd", idl_data.start_jd)

        info.priority = pass_manager.sat_cfgs[idl_data.sat_names[0]].priority
        info.sat_name = idl_data.sat_names[0]
        info.start_jd = idl_data.start_jd[0]
        info.start_jd_adjusted = info.start_jd
        info.end_jd = idl_data.end_jd[0]
        info.end_jd_adjusted = info.end_jd

        idl_data.elevation = []
        idl_data.length_minutes = []
        idl_data.sunlight = []
        idl_data.station_names = []
        for i in range(len(idl_data.sat_names)):
            idl_data.elevation.append(idl_data_old.elevation[i])
            idl_data.length_minutes.append(jd_utc_time.jd_to_minutes(idl_data.end_jd[i]) - jd_utc_time.jd_to_minutes(idl_data.start_jd[i]))
            idl_data.sunlight.append(idl_data_old.sunlight[i])
            idl_data.station_names.append(idl_data_old.station_names[i])

        info_list[0] = info
        #self.add_pass_conflicts(info_list,idl_data)

        return [idl_data,info_list]


class PassManager:
    def __init__(self):
        # testing
        if test_pass_conflicts_enabled == 1:
            self.tester = PassManagerTests()

        # create the generic config ini file
        self.cfg = pass_config.GenericConfig('pass_config.ini')
        # for the overall config, the email list for error and no error are the same
        self.email = minxss_email.email(self.cfg.email_list, self.cfg.email_list, "[No_Specific_Satellite]", self.cfg)

        # NOTE: This error message should probably be elsewhere... (in pass_config.py)
        if len(self.cfg.sat_ini_files) == 0:
            print("ERROR: Please define a satellite INI file in pass_config.ini, or else this program doesn't do anything!")
            sys.exit()

        # create the satellite-specific config files, email modules, and pass managers
        self.sat_cfgs = {}
        self.sat_emails = {}
        self.sat_pass_managers = {}
        for satellite_ini_file in self.cfg.sat_ini_files:
            tmp_sat_cfg = pass_config.SatelliteConfig(satellite_ini_file)
            # add to the dictionaries
            self.sat_cfgs[tmp_sat_cfg.sat_name] = tmp_sat_cfg
            self.sat_emails[tmp_sat_cfg.sat_name] = minxss_email.email(tmp_sat_cfg.email_list_info, tmp_sat_cfg.email_list_full, tmp_sat_cfg.sat_name, self.cfg)
            self.sat_pass_managers[tmp_sat_cfg.sat_name] = SatellitePassManager(tmp_sat_cfg, self.sat_emails[tmp_sat_cfg.sat_name], self.cfg)
            # make sure any instance of hydra that may have been left open is now closed
            self.sat_pass_managers[tmp_sat_cfg.sat_name].kill_hydra()

        # SATPC variables
        self.tle_contents = None
        if self.cfg.use_satpc == 1:
            self.satpc32_exe = ExeManagement(self.cfg.satpc_dir, self.cfg.satpc_exe_name, 1)
            self.satpc32_server_exe = ExeManagement(self.cfg.satpc_dir, self.cfg.satpc_server_exe_name, 0)
            self.satpc_tle_name = 'satellites_' + self.cfg.station_name + '.tle'

        # a list of satelites we're ignoring
        self.ignored_sats = []

    def satpc_monitor(self):
        if self.cfg.use_satpc == 1:
            if self.cfg.do_update_satpc_tle == 1:
                satpc_tle_file_dropbox = os.path.join(self.cfg.idl_tle_dir, self.cfg.station_name)
                satpc_tle_file_dropbox = os.path.join(satpc_tle_file_dropbox, self.satpc_tle_name)

                if os.path.exists(self.cfg.satpc_tle_dir) and os.path.exists(satpc_tle_file_dropbox):
                    satpc_tle_file_dest = os.path.join(self.cfg.satpc_tle_dir, self.satpc_tle_name)
                    copyfile(satpc_tle_file_dropbox, satpc_tle_file_dest)
                    # print("\r\n=====================================")
                    # print("Found new SATPC32 TLE! Copying from:")
                    # print(satpc_tle_file_dropbox)
                    # print("TO:")
                    # print(self.cfg.satpc_tle_dir)
                    # print("=====================================\r\n")
                else:
                    print("One of these locations does not exist:")
                    print(satpc_tle_file_dropbox)
                    print(self.cfg.satpc_tle_dir)
                    self.email("NoFile")

            if self.cfg.disable_restart_programs == 0:
                # Normally we only reset SATPC32 if there's a new TLE.
                # However, if we think SATPC32 is not running, kill the process just in case it does exist so that we have a handle on it
                if self.check_if_new_tle() == 1 or self.satpc32_exe.is_running() == 0:
                    print("**************** New TLE info (or exe not running)!! Restarting SATPC ****************")
                    self.satpc32_exe.kill()
                    time.sleep(5)
                    self.satpc32_server_exe.kill()
                    time.sleep(10)
                    self.satpc32_exe.start()

    def check_if_new_tle(self):
        if self.cfg.use_satpc == 1:
            current_tle_data = ""
            # get the file data
            satpc_tle_file_dest = os.path.join(self.cfg.satpc_tle_dir, self.satpc_tle_name)
            if os.path.exists(satpc_tle_file_dest):
                fileHandle = open(satpc_tle_file_dest, 'r')
                current_tle_data = fileHandle.read()
                fileHandle.close()
            else:
                print("ERROR: No SATPC TLE file at {0}".format(satpc_tle_file_dest))
                self.email("NoFile")
                return 1  # if we don't have the file path we have to assume it updates every time

            if self.tle_contents is None:
                self.tle_contents = current_tle_data
                return 1
            else:
                if len(self.tle_contents) == len(current_tle_data):
                    # if the lengths match, check each character
                    i = 0
                    for char in self.tle_contents:
                        if char != current_tle_data[i]:
                            self.tle_contents = current_tle_data
                            return 1
                        else:
                            i += 1
                else:
                    self.tle_contents = current_tle_data
                    return 1

            self.tle_contents = current_tle_data
        # if we made it here, we're good to go
        return 0

    # returns a struct with info on the next pass (how long until, is in sun, max el, length)
    def get_next_pass_info(self):
        # get the right IDL pass file. Folder structure is:
        # STATION1
        #   passes_latest_STATION1.sav
        # STATION2
        #   passes_latest_STATION2.sav
        # [etc]
        passes_idl_file = os.path.join(self.cfg.idl_tle_dir, self.cfg.station_name)
        passes_idl_file = os.path.join(passes_idl_file,'passes_latest_' + self.cfg.station_name.upper() + '.sav')

        # print("Reading from IDL file: ",passes_idl_file) #enable if needed for debugging

        try:
            idl_data_raw = readsav(passes_idl_file)
        except:
            print("File '" + passes_idl_file + "' is not an IDL .sav file!")
            self.email("NoFile")

        #print(idl_data_raw.PASSES.SATELLITE_NAME)
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
        # SUNLIGHT	0 [0=none, 1=sun]
        # DIR_EW    (passing east [0] or passing west [1] of the station)
        # DIR_NS   (passing North [0] or passing South [1] of the station)
        # SATELLITE_NAME    b'MINXSS1'
        # STATION_NAME      b'BOULDER'

        idl_data = IdlDataClass()
        idl_data.elevation = idl_data_raw.PASSES.MAX_ELEVATION.tolist()
        idl_data.length_minutes = idl_data_raw.PASSES.DURATION_MINUTES.tolist()
        idl_data.sunlight = idl_data_raw.PASSES.SUNLIGHT.tolist()
        idl_data.sat_names = idl_data_raw.PASSES.SATELLITE_NAME.tolist()
        for i in range(len(idl_data.sat_names)):
            idl_data.sat_names[i] = str(idl_data.sat_names[i])
            idl_data.sat_names[i] = idl_data.sat_names[i][2:-1]  # Filter out weird b' at start and ' at end of text string
        idl_data.station_names = idl_data_raw.PASSES.STATION_NAME.tolist()
        for i in range(len(idl_data.station_names)):
            idl_data.station_names[i] = str(idl_data.station_names[i])
            idl_data.station_names[i] = idl_data.station_names[i][2:-1]  # Filter out weird b' at start and ' at end of text string
        idl_data.start_jd = idl_data_raw.PASSES.START_JD.tolist()
        idl_data.end_jd = idl_data_raw.PASSES.END_JD.tolist()

        #print(idl_data.start_jd)
        #print(jd_utc_time.now_in_jd())

        # pass info from pre-pass calcs (elevation, length, etc)
        info_list = []
        info_list.append(MyPassInfo())
        if test_pass_conflicts_enabled == 0:
            [pass_index, minutes] = self.minutes_until_next_pass(idl_data.start_jd, idl_data.sat_names)
        else:
            minutes = 0
            pass_index = 0
            [idl_data, info_list] = self.tester.test_add_pass_conflicts(self, info_list, idl_data)

        if pass_index >= 0:
            self.store_pass_info(info_list[0], idl_data, pass_index)
            info_list = self.add_pass_conflicts(info_list, idl_data)
            print_pass_info(info_list[0], minutes, 1)

        return [minutes, info_list]

    def add_pass_conflicts(self, info_list, idl_data):
        starts = idl_data.start_jd.copy()
        sat_names = idl_data.sat_names.copy()

        #============ First we get a list of conflicting satellites ============#
        i = info_list[0].index+1  # first compare to the next pass
        endcompare = info_list[0].end_jd_adjusted

        # adjust for testing
        if self.cfg.enable_rapidfire_test == 1:
            starts[i] = starts[i-1] + .0001
            starts[i+1] = starts[i-1] + .0002
            starts[i+2] = starts[i-1] + .0003
        while i < len(starts):
            # make sure this isn't a satellite we're supposed to ignore
            if sat_names[i] in self.sat_cfgs:
                # if maximum pass end time (+ the setup minutes) ends after the next starts, add the "interrupting" satellite to the list
                if endcompare + jd_utc_time.secs_to_jd(self.cfg.setup_minutes_before_pass/60) > starts[i]:
                    info_list.append(MyPassInfo())
                    self.store_pass_info(info_list[-1], idl_data, i)
                    # update the maximum end time of our list
                    endcompare = max(endcompare, info_list[-1].end_jd_adjusted)
                else:
                    break
            else:
                # we skip this satellite since we're not supposed to monitor it
                self.ignored_sats.append(sat_names[i])
            i += 1

        # sort the list by priority as well as start time (handles start
        # note sure how to reverse sort one item but not the other
        for info in info_list:
            info.priority = -info.priority
        info_list = sorted(info_list, key=attrgetter('start_jd_adjusted', 'priority'))
        for info in info_list:
            info.priority = -info.priority

        #============ Now go through the list of satellites we have and modify their start/end times based on priorities ============#
        #Note: We're not worried about what happens if a satellite's start time goes beyond its end time.
        #This will cause the satellite_pass_manager to send a warning email about the pass being skipped
        for active_sat in range(len(info_list)-1):
            # for this satellite, go through all following satellites
            i = active_sat+1
            j = 0
            while j < len(info_list)+100:
                # check for overlap
                if info_list[active_sat].end_jd_adjusted > info_list[i].start_jd_adjusted:
                    # check priorities
                    if info_list[i].priority > info_list[active_sat].priority:
                        print("Next sat {0} is higher than {1}".format(i, active_sat))
                        # if the next is higher, set the previous to end before the next begins
                        info_list[active_sat].end_jd_adjusted = info_list[i].start_jd_adjusted - jd_utc_time.secs_to_jd(self.cfg.buffer_seconds_transition_high_priority)
                        info_list[active_sat].is_shortened = 1
                        break  # we're done evaluating this current satellite, since it has a defined start/end time now
                    else:
                        if info_list[i].priority == info_list[active_sat].priority:
                            print("WARNING: Satellites {0} and {1} have the same priority of {2}! Defaulting to prioritizing the first satellite to get a pass".format(info_list[i].sat_name,info_list[active_sat].sat_name, info_list[i].priority))
                        # if the next is lower (or equal), set the next to start when the previous finishes
                        info_list[i].start_jd_adjusted = info_list[active_sat].end_jd_adjusted
                        info_list[i].is_shortened = 1
                        # ensure info_list stays sorted by start time (and then by index in case there are identical start times).
                        # This should automatically cause this satellite to move on if sorting doesn't change things.

                        #print("===============")
                        #for info in info_list:
                        #    print(info.sat_name)
                        #print("to")

                        for info in info_list:
                            info.priority = -info.priority
                        info_list = sorted(info_list, key=attrgetter('start_jd_adjusted','priority'))
                        for info in info_list:
                            info.priority = -info.priority

                        #for info in info_list:
                        #    print(info.sat_name)
                else:
                    # if there was no overlap, we move on to the next satellite to have a pass start, looking for its overlaps.
                    break
                j += 1
                if j >= len(info_list) + 100:
                    print("CODING ERROR: Avoided infinite loop in function 'add_pass_conflicts'. Contact developer!")

        #debug prints
        #for sat in info_list:
        #    print("Sat {0}, priority {1} pass: {2}-{3}, adjusted to {4}-{5}".format(sat.sat_name, sat.priority, sat.start_jd, sat.end_jd, sat.start_jd_adjusted, sat.end_jd_adjusted))

        #============ Finally, print out a message on the console if there's a conflict ============#
        if len(info_list) > 1:
            warning_str = "WARNING: Upcoming conflict between sats: "
            for info in info_list:
                warning_str += info.sat_name + ", "
            print(warning_str[0:-2])  # cuts off the extra ", "
        return info_list

    def store_pass_info(self, info, idl_data, pass_index):
        # store info on the incoming pass
        info.elevation = idl_data.elevation[pass_index]
        info.length_minutes = idl_data.length_minutes[pass_index]
        info.sunlight = idl_data.sunlight[pass_index]
        info.sat_name = str(idl_data.sat_names[pass_index])
        info.station_name = idl_data.station_names[pass_index]
        info.index = pass_index
        info.start_jd = idl_data.start_jd[pass_index]
        info.start_jd_adjusted = info.start_jd
        info.end_jd = idl_data.end_jd[pass_index]
        info.end_jd_adjusted = info.end_jd
        if info.sat_name in self.sat_cfgs:
            info.priority = self.sat_cfgs[info.sat_name].priority

    # Takes a list of start times (in Julian date) and returns the number of minutes until the next one arrives
    # Assumes the list is sorted.
    # Ignores satellites that aren't in the list of used satellites (configurable by INI file)
    def minutes_until_next_pass(self, start_times, sat_names):
        ind = 0
        now_jd = jd_utc_time.now_in_jd()  # in fractional days
        #print("current time",now_jd)
        #print("current time in UTC",datetime.datetime.utcnow())
        passfound = 0
        for start_time in start_times:
            # find the first time in the list that's in the future or recent past
            tdiff = start_time - now_jd
            acceptable_minutes_from_pass_start = self.cfg.buffer_seconds_after_pass_end / 60 + 1  # if the pass 1 minute ago + our buffer period, we can probably start it
            acceptable_minutes_from_pass_start = min(8, acceptable_minutes_from_pass_start)  # don't run passes older than ~8 minutes, otherwise we could could run the same pass twice!
            if tdiff*24*60 > -acceptable_minutes_from_pass_start:
                if sat_names[ind] in self.sat_cfgs:
                    passfound = 1
                    break
                else:
                    # we skip this satellite since we're not supposed to monitor it
                    self.ignored_sats.append(sat_names[ind])
            ind += 1

        if passfound == 0:
            self.email("NoPassTimes")
            minutes = 99999  # Just a large value so that we don't do anything
            ind = -1  # indicates an error to the calling function
        else:
            minutes = tdiff * 24 * 60  # tdiff is in fractions of a julian day
        return [ind, minutes]


# creating a struct (not sure if this is "pythonic" or not)
class MyPassInfo:
    def __init__(self):
        self.elevation = 0
        self.length_minutes = 0
        self.sunlight = 0
        self.sat_name = ""
        self.station_name = ""
        self.start_jd = 0
        self.start_jd_adjusted = 0
        self.end_jd = 0
        self.end_jd_adjusted = 0
        self.index = 0
        self.priority = 0
        self.is_shortened = 0


class IdlDataClass:
    def __init__(self):
        self.elevation = []
        self.length_minutes = []
        self.sunlight = []
        self.sat_names = []
        self.station_names = []
        self.start_jd = []
        self.end_jd = []


# prints out pass information - use "is_prepass" to define whether the pass has started or not
def print_pass_info(info, minutes, is_prepass):
    txt = "v2.1 {0}: ".format(info.station_name)
    if is_prepass == 1:
        txt += "Next Pass [{0}] in {1} min ".format(info.sat_name, round(minutes, 2))
    else:
        txt += "ACTIVE PASS [{0}] {1} min left ".format(info.sat_name, round(minutes, 2))
    txt += "// El: {0} deg. // Len: {1} min. // Sun: {2}".format(round(info.elevation, 2), round(info.length_minutes, 2), info.sunlight)
    print(txt)


class SatellitePassManager:
    # is_mon_hydra, is_run_hydra_scripts, is_update_satpc_tle, computer_name
    def __init__(self, cfg, email_module, global_cfg):
        self.cfg = cfg
        self.global_cfg = global_cfg
        # initialize error class
        self.email = email_module
        # store a variable for whether or not we're in a pass
        self.is_in_pass = 0
        self.hydra_scripts = os.path.join(self.cfg.hydra_dir, 'Scripts')
        if not os.path.exists(self.cfg.hydra_dir):
            print("One of these locations does not exist (hydra exe):")
            print(self.cfg.hydra_dir)
            self.email("NoFile")

        self.hydra_script_dest_file = os.path.join(self.hydra_scripts, 'script_to_run_automatically_on_hydra_boot.prc')
        self.hydra_script_src_folder = os.path.join(self.hydra_scripts, 'scripts_to_run_automatically')
        self.default_pass_script = "default_auto_script.prc"
        if not os.path.exists(os.path.join(self.hydra_script_src_folder, self.default_pass_script)):
            print("\r\nERROR: Initial configuration failed!")
            print("You should have a 'scripts_to_run_automatically' folder in your Hydra/Scripts directory")
            print("That directory should have a file 'default_auto_script.prc'")
            print("This file is what will run if there are no scripts available to run.")
            print("This is the file the program is looking for that doesn't exist:")
            print(os.path.join(self.hydra_script_src_folder,self.default_pass_script))
            print("\r\n")
            sys.exit()

        self.hydra_exe = ExeManagement(self.cfg.hydra_dir, self.cfg.hydra_exe_name, 1)
        self.sdr_exe = ExeManagement(self.cfg.sdr_dir, self.cfg.sdr_script_starter_name, 1)
        self.script_exe = ExeManagement(self.cfg.script_dir, self.cfg.pre_pass_script, 1)
        self.wasrun_scriptloc = ""

    def run_pass(self, info, is_quick_exit):
        print("\r\n\r\n======================== Prepping for a {0} pass! ========================\r\n".format(info.sat_name))
        if self.cfg.do_send_prepass_email == 1:
            self.email("PassAboutToOccur")

        # Figure out what the next Hydra script to run is
        if self.cfg.do_run_hydra_scripts == 1:
            scriptnamelist = [f for f in os.listdir(self.hydra_script_src_folder) if os.path.isfile(os.path.join(self.hydra_script_src_folder, f))]
            scriptnamelist.sort()
            while not(".prc" in scriptnamelist[0]) and len(scriptnamelist) > 0:  # skip non .prc files
                print("Ignoring file in scripts_to_run_automatically folder: " + scriptnamelist[0])
                del scriptnamelist[0]

            nextscriptfilename = scriptnamelist[0]
            if "default" in nextscriptfilename or "was_run" in nextscriptfilename:
                self.email("NoPassScript")
                hydra_script_src_file = os.path.join(self.hydra_script_src_folder, self.default_pass_script)
                running_default = 1
            else:
                hydra_script_src_file = os.path.join(self.hydra_script_src_folder, nextscriptfilename)
                running_default = 0
            self.email.StoreScriptName(hydra_script_src_file)

            # Check to make sure the file exists
            if not(os.path.exists(hydra_script_src_file)):
                print("Hydra default script does not exist!!! Expected path:")
                print(hydra_script_src_file)
                self.email("NoFile")
            else:
                print("Running Hydra script: ", hydra_script_src_file)
                # Copy the file over, then rename it to wasrun_"".prc
                copyfile(hydra_script_src_file, self.hydra_script_dest_file)
                wasrundest_folder = os.path.join(self.hydra_script_src_folder, "was_run")  # this is just the folder still
                # Now create the directory if it doesn't exist
                try:
                    os.stat(wasrundest_folder)
                except:
                    os.mkdir(wasrundest_folder)
                # add the actual file name
                wasrundest_file = os.path.join(wasrundest_folder, "was_run_" + nextscriptfilename)
                # If we run scripts with exactly the same name, give them uniquifiers (should not generally happen except when running default case)
                i = 2  # start at 2 for "2nd time"
                while os.path.exists(wasrundest_file):
                    wasrundest_file = os.path.join(wasrundest_folder, "was_run_" + str(i) + "_" + nextscriptfilename)
                    i = i + 1

                if running_default == 0:
                    os.rename(hydra_script_src_file, wasrundest_file)
                else:
                    # don't rename if it's the default, but we do want to track that we ran the default
                    copyfile(hydra_script_src_file, wasrundest_file)
                # store the script location so it can be emailed
                self.email.StoreScriptLocation(wasrundest_file)
                self.wasrun_scriptloc = wasrundest_file

        if self.global_cfg.disable_restart_programs == 0:
            if self.cfg.do_run_pre_pass_script == 1:
                self.script_exe.start()
            if self.cfg.do_monitor_sdr == 1:
                self.sdr_exe.start()  # TODO: Need to make sure that this is done before Hydra opens up
            if self.cfg.do_monitor_hydra == 1:
                self.hydra_exe.start()

        self.sleep_until_pass_is_done(info)

        if is_quick_exit == 0:
            time.sleep(self.global_cfg.buffer_seconds_after_pass_end)

        if self.global_cfg.disable_restart_programs == 0:
            if self.cfg.do_monitor_hydra == 1:
                self.hydra_exe.kill()
                time.sleep(10)  # give Hydra time to shut down
            if self.cfg.do_monitor_sdr == 1:
                self.sdr_exe.kill()
                time.sleep(10)  # give the SDR and ruby bridges time to shut down
            if self.cfg.do_run_pre_pass_script == 1:
                self.script_exe.kill()

        self.pass_analysis(info)

        print("\r\n**********************  Done with {0} pass! **********************\r\n\r\n".format(info.sat_name))

    def sleep_until_pass_is_done(self, info):
        while 1:
            t = jd_utc_time.now_in_jd()
            # check to see if pass has started yet
            if t < info.start_jd_adjusted:
                minutes = (info.start_jd_adjusted-t)*24*60
                print_pass_info(info, minutes, 1)
            # if it has started, we must not be done waiting yet
            else:
                minutes = (info.end_jd_adjusted-t)*24*60
                print_pass_info(info, minutes, 0)

            # print a message every 60 seconds, but check for pass completion every second
            for i in range(0,60):
                time.sleep(1)
                if jd_utc_time.now_in_jd() > info.end_jd_adjusted:
                    return
                if self.global_cfg.enable_rapidfire_test == 1:
                    time.sleep(10)
                    return

    # restarts Hydra
    def kill_hydra(self):
        print("Killing the Hydra process!")
        time.sleep(1)
        self.hydra_exe.kill()
        time.sleep(1)

    # gets a path to the rundir for the current pass and then has it analyzed
    def pass_analysis(self, info):
        rundirs_dir = os.path.join(self.cfg.hydra_dir, 'Rundirs')
        rundir_list = [f for f in os.listdir(rundirs_dir) if not(os.path.isfile(os.path.join(rundirs_dir,f)))]
        rundir_list.sort()

        # populate the path in the analysis object
        results = rundir_analysis.Rundir(os.path.join(rundirs_dir,rundir_list[-1]), os.path.basename(self.wasrun_scriptloc))

        #for debugging easily...
        #results = rundir_analysis.Rundir('C:\\Users\\Colden\\Desktop\\CU Boulder\\MinXSS\\ground_station_files\\updated rundirs\\2016_317_07_44_55', os.path.basename(self.wasrun_scriptloc))
        #results = rundir_analysis.Rundir('C:\\Users\\Colden\\Desktop\\CU Boulder\\MinXSS\\ground_station_files\\updated rundirs\\2016_317_09_22_26', os.path.basename(self.wasrun_scriptloc))

        results.Analyze(info, self.cfg)

        self.email.PassResults(results, info)


# Tracks executables that need to be launched and killed.
# If the exe is not launchable, set is_launchable to 0. (Example: SATPC32's ServerSDX)
class ExeManagement:
    def __init__(self, dir, name, is_launchable):
        self.process = None
        self.exec_dir = dir
        self.exec_name = name
        self.exec_full_path = os.path.join(self.exec_dir, self.exec_name)
        self.batch_kill_cmd = 'TASKKILL /f /IM ' + self.exec_name

        if is_launchable:
            if not(os.path.exists(self.exec_full_path)):
                print("\r\nERROR: Initial configuration failed!")
                print("Executable path does not exist! Check your .ini files. See:")
                print(self.exec_full_path)
                sys.exit()

    def start(self):
        self.process = Popen(self.exec_full_path, cwd=self.exec_dir, preexec_fn=os.setsid)

    def is_running(self):
        # Check to see if the process identifier exists
        if self.process is None:
            return 0
        # check to see if the process identifier exists, but the process is not running
        elif self.process.poll() is not None:
            return 0
        # if neither of the above two, then it's running
        else:
            return 1

    def kill(self):
        terminated = 0  # did we kill the process?
        if self.process is not None:
            if self.process.poll() is None:  # Will be "None" if nothing has terminated the process
                self.process.terminate()  # this is the nice way to terminate the process
                terminated = 1
        if terminated == 0:  # if the "nice" way didn't work, do it the sledgehammer way
            if os.name == 'posix':  # It's Unix (Linux or macOS)
                os.killpg(self.process.pid, signal.SIGINT)
            else:  # It's Windows
                os.system(self.batch_kill_cmd)

            print("NOTE: 'SUCCESS' = we killed an exe we weren't tracking, 'ERROR' = it wasn't running or was closed normally.")


if __name__ == '__main__':
    main(*sys.argv)
