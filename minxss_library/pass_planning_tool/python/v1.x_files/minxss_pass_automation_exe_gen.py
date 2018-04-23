### How to build:
# 0) Ensure the global variable define settings in this file and in "minxss_monitor_pass_times.py" are what you want
# 1) Open a command window here
# 2) Run this command:
#       pyinstaller minxss_pass_automation_exe_gen.py -F -n minxss_pass_automation --clean
# 3) *.exe goes to .\dist

######### SETTINGS #########
#See pass_config.py

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
from subprocess import Popen
import psutil

import minxss_email
import minxss_monitor_pass_times
from minxss_time import now_in_jd
import pass_config

mydir = os.path.dirname(__file__)
if(len(mydir) == 0):
    mydir = os.getcwd()

def main(script): #This is what calls the minxss_monitor_pass_times code and sets it all up
    cfg = pass_config.load_config('pass_config.ini')

    #quick way to apply settings for Jim's machine in testing
    if(cfg.is_jims_machine==1):
        cfg.do_update_satpc_tle = 1
        cfg.computer_name = "JIM_COMP" #This goes into error emails
        cfg.do_run_isis_scripts = 0

    monitor_pass = minxss_monitor_pass_times.monitor(cfg)
    while(1):
        ispass = monitor_pass(0)
        if(ispass == 1): #if this is true, then our last call initiated a pass
            print(" ")
            print("**************** Pre-pass processing completed! ****************")
            print(" ")
            print(" ")
            print(" ")
            t0 = time.time()
            #Don't do anything for a while so we don't interfere with this pass
            while time.time()-t0 < cfg.minutes_sleep_after_pass_start*60:
                time.sleep(15)
            #after the pass is over, analyze it (but not on Jim's machine)
            if(cfg.do_send_analysis_email==1):
                monitor_pass.PassAnalysis()
            #Jim's computer just kills hydra
            else:
                monitor_pass.KillHydra()
            time.sleep(10)
        else:
            time.sleep(30) #sleep for 30 seconds if there wasn't a pass

if __name__ == '__main__':
    main(*sys.argv)