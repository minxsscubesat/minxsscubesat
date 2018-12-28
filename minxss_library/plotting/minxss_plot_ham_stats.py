#!/anaconda3/bin/python

import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import pandas as pd
import numpy as np
import os

plotly.tools.set_credentials_file(username='jmason86', api_key='wvT5wAI0l7q3uCvxT8ny')
mapbox_access_token = 'pk.eyJ1Ijoiam1hc29uODYiLCJhIjoiY2pxNXNwNWxtMjg0bzQ5bno1N2t6azJ4OCJ9.u79V06CZcZNlt3tAdkp5XA'

# Make the list of files in ham_data
ham_data_path = '/Users/minxss/Dropbox/minxss_dropbox/data/ham_data/'
os.chdir(ham_data_path)
os.system("ls -l 20{18,19,20,21,22}-* > ham_stats.txt")
filename = ham_data_path + 'ham_stats.txt'

# Load and filter the data
df = pd.read_fwf(filename, colspecs='infer')
df.columns = ['', '', '', '', 'filesize', '', '', '', 'filename']
df = df[['filename', 'filesize']]
df = df[df.filesize != 0]
test_uploads = df['filename'].str.contains('JPM')
df = df[~test_uploads]

# Get the number of packets
df['# of packets'] = np.floor(df['filesize'].values / 272)

# Get the callsigns
filenames = df['filename'].values
split_filenames = [item.split('_') for item in filenames]

callsign = []
latitude = []
longitude = []
for item in split_filenames:
    if len(item) == 6:
        callsign.append(item[3])
        latitude.append(item[4])
        longitude.append(item[5][:-4])
    else:
        callsign.append('')
        latitude.append('')
        longitude.append('')

df['callsign'] = callsign
df['latitude'] = latitude
df['longitude'] = longitude
df = df[df.callsign != '']
df.reset_index(drop=True, inplace=True)

# Generate the histogram
unique_callsigns = df['callsign'].str.upper().unique()
total_packets = []
unique_latitudes = []
unique_longitudes = []
for callsign in unique_callsigns:
    total_packets.append(df[df.callsign == callsign]['# of packets'].sum())
    unique_latitudes.append(df[df.callsign == callsign]['latitude'].iloc[0])
    unique_longitudes.append(df[df.callsign == callsign]['longitude'].iloc[0])

df_unique = pd.DataFrame()
df_unique['callsign'] = unique_callsigns
df_unique['latitude'] = unique_latitudes
df_unique['longitude'] = unique_longitudes
df_unique['total packets'] = total_packets
df_unique.sort_values(by=['total packets'], ascending=False, inplace=True)

# Make histogram
data = [go.Bar(
    x=df_unique['callsign'].values,
    y=df_unique['total packets'].values
)]

layout = go.Layout(
    title='MinXSS-2 Packets from Ham Operators',
    width=700,
    height=400,
    font=dict(size=16),
    yaxis=dict(title='# of packets'),
    xaxis=dict(title='callsign'),
    margin=go.layout.Margin(
        l=75,
        r=50,
        b=75,
        t=100,
        pad=4
    )
)

# fig = go.Figure(data=data, layout=layout)
# plot_url = py.iplot(fig, filename='MinXSS-2 Packets from Ham Operators', auto_open=False)
# print('Histogram updated at {}'.format(plot_url.resource))

# Make map
scale = 5000.
sizeref = 2. * max(df_unique['total packets']/scale) / (25 ** 2)
data = [
    go.Scattermapbox(
        lat=df_unique['latitude'].values.tolist(),
        lon=df_unique['longitude'].values.tolist(),
        mode='markers',
        marker=dict(
            size=(df_unique['total packets'].values / scale).tolist(),
            sizeref=sizeref,
            sizemode='area'
        ),
    )
]
layout = go.Layout(
    title='Where MinXSS Ham Beacons Have Been Received',
    width=800,
    height=500,
    font=dict(size=16),
    autosize=True,
    hovermode='closest',
    mapbox=dict(
        accesstoken=mapbox_access_token,
        bearing=0,
        center=dict(
            lat=40.0150,
            lon=-105.2705
        ),
        pitch=0,
        zoom=0.4
    ),
)

fig = dict(data=data, layout=layout)
map_url = py.iplot(fig, filename='Map MinXSS-2 Packets from Ham Operators', auto_open=False)
print('Map updated at {}'.format(map_url.resource))

# Make leaderboard
trace = go.Table(
    header=dict(values=['Callsign', 'Total Packets'],
                fill=dict(color='#1e90ff'),
                font=dict(color='white', size=16),
                align=['left'] * 5),
    cells=dict(values=[df_unique['callsign'], df_unique['total packets']],
               fill=dict(color='#F5F8FF'),
               font=dict(size=14),
               align=['left'] * 5))
layout = dict(width=800,
              title='MinXSS Ham Beacon Leaderboard',
              font=dict(size=16))

data = [trace]
fig = dict(data=data, layout=layout)
leaderboard_url = py.iplot(fig, filename='MinXSS-2 Packets Ham Leaderboard', auto_open=False)
print('Leaderboard updated at {}'.format(leaderboard_url.resource))
