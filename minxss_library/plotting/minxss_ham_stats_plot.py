import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import pandas as pd
import numpy as np
import os

plotly.tools.set_credentials_file(username='jmason86', api_key='wvT5wAI0l7q3uCvxT8ny')


# Make the list of files in ham_data
ham_data_path = '/Users/jmason86/Dropbox/minxss_dropbox/data/ham_data/'
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
for item in split_filenames:
    if len(item) == 6:
        callsign.append(item[3])
    else:
        callsign.append('')

df['callsign'] = callsign
df = df[df.callsign != '']
df.reset_index(drop=True, inplace=True)

# Generate the histogram
unique_callsigns = df.callsign.unique()
total_packets = []
for callsign in unique_callsigns:
    total_packets.append(df[df.callsign == callsign]['# of packets'].sum())

results = pd.DataFrame()
results['callsign'] = unique_callsigns
results['total packets'] = total_packets
results.sort_values(by=['total packets'], ascending=False, inplace=True)

# Make plot
data = [go.Bar(
    x=results['callsign'].values,
    y=results['total packets'].values
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

fig = go.Figure(data=data, layout=layout)
plot_url = py.iplot(fig, filename='MinXSS-2 Packets from Ham Operators', auto_open=False)
