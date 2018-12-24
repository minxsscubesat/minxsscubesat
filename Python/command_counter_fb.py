#This script is to be run after starting HYDRA!!!
#
#The purpose of this script is to real-time tracks how many commands have been sent from HYDRA
# and which scripts have been run in the current HYDRA session on a graphic interface.
#
#Currently the script resides in C:\Users\OPS\Dropbox\minxss_dropbox\code\Python\command_counter.py
#
#If running a different version of HYDRA or a different ground station,
# change the "Path to the Rundirs Folder" to that HYDRA
#
#How to run:
#  1. Make sure HYDRA is running already! (otherwise will track the previouse HYDRA)
#  2. open a command prompt (Windows)
#  3. copy and paste this line: python C:/Users/OPS/Dropbox/minxss_dropbox/code/Python/command_counter.py
#  3. press enter
#
#Version Control:
#11/20/18 - Bennet Schwab - Initial Release of command_counter.py for MinXSS-2 commissioning from Fairbanks
#

from tkinter import *
import datetime
import os
import re
import glob

#Path to Rundirs Folder in HYDRA
os.chdir('C:/Users/OPS/Dropbox/Hydra/MinXSS/HYDRA_FM-2_Fairbanks/Rundirs')

#make array of all rundirs directories
dirs = os.listdir()

#sort all rundirs by new
dirs.sort(reverse=True)

#enter the most recent rundirs folder
os.chdir(dirs[0])

#controls the GUI display
root = Tk()

#find the log file
logfile = glob.glob("EventLog*")

w = 250 # width for the Tk root
h = 500 # height for the Tk root

# get screen width and height
ws = root.winfo_screenwidth() # width of the screen
hs = root.winfo_screenheight() # height of the screen

# calculate x and y coordinates for the Tk root window
x = 0
y = 720

# set the dimensions of the screen 
# and where it is placed
root.geometry('%dx%d+%d+%d' % (w, h, x, y))

#setup for GUI
lab = Label(root)
lab.pack()

#function to run GUI and output the live command counter and scripts sent
def output():

	#read the EventLog file
	with open(logfile[0]) as f:
	    content = f.readlines()

	#get rid of new line characters '\n'
	content = [x.strip() for x in content] 
	
	#command counter variable initially zero, scripts sent initially blank
	cmdCount = 0
	scripts = ''
	
	#read through the EventLog file and search by line for commands and scripts
	for line in content:
		
		#Each command begins with 'Sending command'
		if re.search('Sending command', line):
			#increment if we see this string
			cmdCount += 1
			
		#Each script begins with 'Starting script'
		elif re.search('Starting script', line):
			#but there are some which always run so we need to ignore these
			if re.search('engine 0', line):
				donothing = 0
			elif re.search('Auto', line):
				donothing = 0
			elif re.search('_bct', line):
				donothing = 0
			elif re.search('init.prc', line):
				donothing = 0
			elif re.search('bctReader', line):
				donothing = 0
				
			#The ones we care about are here
			else:
				#this is the case where a space is put in (not likely)
				if str(line[41]) == ' ':
					#then we start to display from one space further
					scripts = scripts+'\n'+str(line[42:])
				#otherwise, just display from there
				else:
					scripts = scripts+'\n'+str(line[41:])
		
		#I wanted to also display when new tlm files were turned over
		elif re.search('tlm_packets', line, re.IGNORECASE):\
			#don't want to display the closed tlm file
			if re.search('closing', line, re.IGNORECASE):
				donothing = 0
				
			#only display the New tlm file
			else:
				scripts = scripts+'\nNew '+str(line[43:])
				
		#Also, for commissioning there is no script for cancelling deployment retry
		#  it just happens in the wrapper, so I gave the script something to recognize
		elif re.search('Canceling deployment retry',line):
			scripts = scripts+'\ncancel_ant_deploy_retry'
			
	#OK that's all we're going to recognize
	
	
	
	#now to display what we recognized. First the command counter, then the scripts ran.
	time = 'Fairbanks Ground Station\n\nCommand Counter: '+str(cmdCount)+'\n\nScripts Ran:'+scripts
	
	#configure the text to be left justified
	lab.config(text=time, anchor=W, justify=LEFT)
	
	root.after(100, output) # run itself again after 1000 ms

# run first time
output()

# rest of main loop
root.mainloop()
