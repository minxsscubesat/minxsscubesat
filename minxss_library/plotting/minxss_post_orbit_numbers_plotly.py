#!/anaconda3/bin/python

import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import pandas as pd
import numpy as np
import datetime
plotly.tools.set_credentials_file(username='jmason86', api_key='wvT5wAI0l7q3uCvxT8ny')

satellites = ['MinXSS-2', 'CSIM']

for satellite in satellites:
    # Read data
    if satellite == 'MinXSS-2':
        filename = '/Users/minxss/Dropbox/minxss_dropbox/tle/orbit_number/MINXSS2_orbit_number.dat'
    elif satellite == 'CSIM':
        filename = '/Users/minxss/Dropbox/minxss_dropbox/tle/orbit_number/CSIM_orbit_number.dat'

    df = pd.read_fwf(filename, skiprows=3)
    columns = ['Orbit #', 'YYYYDOY', 'UT second', 'Sunrise UT second', 'Sunset UT second', 'Beta Angle [º]', 'Pass minutes']
    df.columns = columns

    # Convert time to ISO and add it to the dataframe
    def sod_to_hhmmss(sod):
        # Parse seconds of day into hours, minutes, and seconds
        time = sod % (24 * 3600)
        time = time.astype(int)
        hours = time // 3600
        time %= 3600
        minutes = time // 60
        time %= 60
        seconds = time

        # Convert to string type and add leading zeros
        hours_str = hours.astype(str)
        small_hour_indices = hours < 10
        hours_str[small_hour_indices] = np.core.defchararray.zfill(hours_str[small_hour_indices], 2)

        minutes_str = minutes.astype(str)
        small_minute_indices = minutes < 10
        minutes_str[small_minute_indices] = np.core.defchararray.zfill(minutes_str[small_minute_indices], 2)

        seconds_str = seconds.astype(str)
        small_second_indices = seconds < 10
        seconds_str[small_second_indices] = np.core.defchararray.zfill(seconds_str[small_second_indices], 2)

        return np.char.array(hours_str) + ':' + np.char.array(minutes_str) + ':' + np.char.array(seconds_str)


    def yyyydoy_sod_to_datetime(yyyydoy, sod):
        parsed_date = np.modf(yyyydoy / 1000)  # Divide to get yyyy.doy

        hhmmss = sod_to_hhmmss(sod)

        return np.array([datetime.datetime(int(parsed_date[1][i]), 1, 1,
                         int(hhmmss[i][:2]),
                         int(hhmmss[i][3:5]),
                         int(hhmmss[i][6:8])) +                                      # base (yyyy-01-01 hh:mm:ss)
                         datetime.timedelta(days=int(parsed_date[0][i] * 1000) - 1)  # doy -> mm-dd
                         for i in range(len(yyyydoy))])                              # loop over input array


    df['UTC Timestamp'] = yyyydoy_sod_to_datetime(df['YYYYDOY'].values, df['UT second'].values)
    columns.insert(1, 'UTC Timestamp')
    df = df.reindex(columns=columns)

    # Make table on plotly
    trace = go.Table(
        header=dict(values=list(df.columns),
                    fill=dict(color='#C2D4FF'),
                    align=['center'] * 5),
        cells=dict(values=[df['Orbit #'], df['UTC Timestamp'], df['YYYYDOY'], df['UT second'], df['Sunrise UT second'], df['Sunset UT second'], df['Beta Angle [º]'], df['Pass minutes']],
                   align=['center']),
        columnwidth=[30, 80, 60, 50, 50, 50, 45, 40])

    layout = dict(title='{} Orbit Number'.format(satellite))

    data = [trace]
    fig = dict(data=data, layout=layout)
    url = py.iplot(fig, filename='{} Orbit Number'.format(satellite))
    print('Posted orbit numbers for {0} at {1}'.format(satellite, url.resource))
