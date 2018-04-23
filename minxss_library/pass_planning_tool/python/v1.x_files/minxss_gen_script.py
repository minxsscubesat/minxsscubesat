import datetime
import numpy
import sys
import os
import math
import time
import re   #regular expressions
from enum import Enum
#<*************** How to use this program and what it does *******************>
#
#</***************************************************************************>


#<*************** TODO ITEMS: *******************>
#
#
#</**********************************************>

#Get the current working directory, save it to global var
mydir = os.path.dirname(__file__)
if(len(mydir) == 0):
    mydir = os.getcwd()

def test_random_stuff():
    print("*********** Starting Generate ISIS Automatic Script (TEST) *************")
    isisdir = os.path.join(mydir,"gen");
    template_filepath = os.path.join(isisdir,"auto_data_dump_template.prc");
    generate_filepath = os.path.join(isisdir,"generated_file.prc");

    vars = data_dump_vars()
    update_script(vars,template_filepath,generate_filepath)

    print("*********** Finished Running Generate ISIS Automatic Script (TEST) *************")


def update_script(vars,template_filepath,generate_filepath):
    template_file = open(template_filepath,'r')
    generate_file = open(generate_filepath,'w')

    #TODO: When there are zeros for decimation, just don't send the command

    for line in template_file:
        newline = line.replace('%hkstart%',vars.hkstart)
        newline = newline.replace('%hkstop%',vars.hkstop)
        newline = newline.replace('%hkstep%',vars.hkstep)

        newline = newline.replace('%logstart%',vars.logstart)
        newline = newline.replace('%logstop%',vars.logstop)
        newline = newline.replace('%logstep%',vars.logstep)

        newline = newline.replace('%scistart%',vars.scistart)
        newline = newline.replace('%scistop%',vars.scistop)
        newline = newline.replace('%scistep%',vars.scistep)

        newline = newline.replace('%adcsstart%',vars.adcsstart)
        newline = newline.replace('%adcsstop%',vars.adcsstop)
        newline = newline.replace('%adcsstep%',vars.adcsstep)

        newline = newline.replace('%diagstart%',vars.diagstart)
        newline = newline.replace('%diagstop%',vars.diagstop)
        newline = newline.replace('%diagstep%',vars.diagstep)

        newline = newline.replace('%ximgstart%',vars.ximgstart)
        newline = newline.replace('%ximgstop%',vars.ximgstop)
        newline = newline.replace('%ximgstep%',vars.ximgstep)

        generate_file.write(newline)

    generate_file.close()
    template_file.close()



class data_dump_vars:
    def __init__(self):
        self.hkstart = '1'
        self.hkstop = '2'
        self.hkstep = '3'

        self.logstart = '4'
        self.logstop = '5'
        self.logstep = '6'

        self.scistart = '7'
        self.scistop = '8'
        self.scistep = '9'

        self.adcsstart = '10'
        self.adcsstop = '11'
        self.adcsstep = '12'

        self.diagstart = '13'
        self.diagstop = '14'
        self.diagstep = '15'

        self.ximgstart = '16'
        self.ximgstop = '17'
        self.ximgstep = '18'


def main(script):
    test_random_stuff()

if __name__ == '__main__':
    #Note that sys.argv[0] is equal to the filename
    main(*sys.argv)
    # if(len(sys.argv) == 3):
        # main(sys.argv[1],sys.argv[2])
    # else:
        # main(sys.argv[1])