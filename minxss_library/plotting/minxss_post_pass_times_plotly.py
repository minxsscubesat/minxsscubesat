#!/anaconda3/bin/python

import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import pandas as pd
import numpy as np
plotly.tools.set_credentials_file(username='jmason86', api_key='wvT5wAI0l7q3uCvxT8ny')

ground_stations = ['Boulder', 'Fairbanks']

for ground_station in ground_stations:
    # Read data
    if ground_station == 'Boulder':
        filename = '/Users/minxss/Dropbox/minxss_dropbox/tle/Boulder/passes_latest_BOULDER.csv'
    elif ground_station == 'Fairbanks':
        filename = '/Users/minxss/Dropbox/minxss_dropbox/tle/Fairbanks/passes_latest_FAIRBANKS.csv'

    df = pd.read_csv(filename, header=[1])

    # Make table on plotly
    row_color = []
    for peak_el in df[' Peak Elevation'].values:
        if peak_el < 15:
            row_color.append(['#D3D3D3' for x in range(6)])
        elif peak_el >= 15 and peak_el < 30:
            row_color.append(['#90ED8F' for x in range(6)])
        else:
            row_color.append(['#05FF00' for x in range(6)])
    row_color = np.array(row_color).T.tolist()

    trace = go.Table(
        header=dict(values=list(df.columns),
                    fill=dict(color='#C2D4FF'),
                    align=['center'] * 5),
        cells=dict(values=[df[' Satellite'], df[' Start Time'], df[' End Time'], df[' Duration Minutes'], df[' Peak Elevation'], df[' In Sunlight']],
                   fill=dict(color=row_color),
                   align=['center']),
        columnwidth = [60, 125, 125, 60, 60, 80])

    layout = dict(title='Satellite Passes at {}'.format(ground_station))

    data = [trace]
    fig = dict(data=data, layout=layout)
    url = py.iplot(fig, filename='{} Passes'.format(ground_station))
    print('Posted passes for {0} at {1}'.format(ground_station, url.resource))

