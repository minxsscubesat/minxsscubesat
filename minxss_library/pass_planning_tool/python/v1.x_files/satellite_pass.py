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