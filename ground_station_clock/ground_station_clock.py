# importing whole module
from tkinter import *
from tkinter.ttk import *
from tkinter import ttk
import pandas as pd
 
# importing strftime function to
# retrieve system's time
from time import strftime
from datetime import datetime

# Globals
increment_sec = 0
df = pd.DataFrame()


def read_new_pass_times():
    global df
    print(strftime('%Y-%m-%d %H:%M:%S') + ' local time: loading new pass times')
    #pass_file = '/Users/jmason86/Dropbox/minxss_dropbox/tle/Boulder/passes_latest_BOULDER.csv'
    pass_file = '/Users/gs-ops/Dropbox/minxss_dropbox/tle/Boulder/passes_latest_BOULDER.csv'
    df_all = pd.read_csv(pass_file, skiprows=1)
    df_all.columns = ['Satellite', 'Start Time', 'End Time', 'Duration [Minutes]', 'Peak Elevation', 'Sunlight']
    df_all = df_all.iloc[:-1]
    df_all['Peak Elevation'] = df_all['Peak Elevation'].round().astype(int)
    df_all['Start Time'] = pd.to_datetime(df_all['Start Time'])
    df_all['End Time'] = pd.to_datetime(df_all['End Time'])
    df = df_all

 
# creating tkinter window
root = Tk()
root.geometry("1920x300+0+0")
root.title('Clock')
root.configure(background='black')


def time():
    global increment_sec, df
    increment_sec += 1
    if increment_sec >= 86400:
        increment_sec = 0
        read_new_pass_times()

    utc_time = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S') + ' UTC'
    local_time = strftime('%Y-%m-%d %H:%M:%S') + ' local'
    
    lbl_t_utc.config(text=utc_time)
    lbl_t_utc.after(1000, time)
    lbl_t_local.config(text=local_time)

    # Figure out when we are
    now = datetime.utcnow()
    if df[(now > df['Start Time']) & (now <= df['End Time'])].empty:
        bla = df[df['Start Time'] > now]
        df_pass = bla.iloc[0]
        countdown = df_pass['Start Time'] - now
        hours, remainder = divmod(countdown.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        aos_los = 'AOS'
        countdown_color = 'white'
    else:
        df_pass = df[(now > df['Start Time']) & (now <= df['End Time'])].iloc[0]
        countdown = df_pass['End Time'] - now
        hours, remainder = divmod(countdown.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        aos_los = 'LOS'
        countdown_color = 'green'

    # now = datetime.utcnow()
    # bla = df[df['Start Time'] > now]
    # df_pass = bla.iloc[0]
    # countdown = df_pass['Start Time'] - now
    # hours, remainder = divmod(countdown.seconds, 3600)
    # minutes, seconds = divmod(remainder, 60)
    
    if df_pass['Sunlight'] == ' YES':
        daynight = 'sun'
    else:
        daynight = 'eclipse'
    
    lbl_countdown.config(text='{:02}:{:02}:{:02} to{} {} | {}º peak elevation in {}'.format(int(hours), int(minutes), int(seconds), df_pass['Satellite'], aos_los, df_pass['Peak Elevation'], daynight))
    lbl_countdown.config(foreground=countdown_color)


lbl_t_utc = Label(root, font=('calibri', 80, 'bold'),
                  background='black',
                  foreground='red')
lbl_t_local = Label(root, font=('calibri', 60),
                    background='black',
                    foreground='red')
lbl_countdown = Label(root, font=('calibri', 40),
                      background='black',
                      foreground='white')
style = ttk.Style(root)
style.theme_use('classic')
style.configure('Tlabel', background='black', foreground='red')
style.configure('TFrame', background='black')

lbl_t_utc.pack(anchor='center')
lbl_t_local.pack(anchor='center')
lbl_countdown.pack(anchor='center')
read_new_pass_times()
time()
 
mainloop()
