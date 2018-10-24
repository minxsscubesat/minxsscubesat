from collections import namedtuple
import pandas as pd
import seaborn as sns


class ConflictPlotter:
    def __init__(self):
        data_path = '/Users/jmason86/Dropbox/Research/CubeSat/GMAT/MinXSS2_CSIM/'
        self.minxss_data_filename = data_path + 'lasp_minxss2_contact.txt'
        self.csim_data_filename = data_path + 'lasp_csim_contact.txt'
        self.plot_filename = '/Users/jmason86/Google Drive/CubeSat/MinXSS Server/8000 Ground Software : Mission Ops/Conflict with CSIM vs Time.png'

        self.minxss_start_times = None
        self.minxss_end_times = None
        self.csim_start_times = None
        self.csim_end_times = None
        self.conflicts = None

        self.setup_plot()

    @staticmethod
    def setup_plot():
        sns.set()
        sns.set(font_scale=1.5)

    def load_data(self):
        minxss = pd.read_fwf(self.minxss_data_filename, skiprows=3)
        csim = pd.read_fwf(self.csim_data_filename, skiprows=3)

        self.minxss_start_times = pd.DatetimeIndex(minxss['Start Time (UTC)']).to_pydatetime()
        self.minxss_end_times = pd.DatetimeIndex(minxss['Stop Time (UTC)']).to_pydatetime()

        self.csim_start_times = pd.DatetimeIndex(csim['Start Time (UTC)']).to_pydatetime()
        self.csim_end_times = pd.DatetimeIndex(csim['Stop Time (UTC)']).to_pydatetime()

    def compute_overlapping_times(self):
        datetimes = []
        overlaps = []
        loop_max_range = min(len(self.minxss_start_times), len(self.csim_start_times))
        Range = namedtuple('Range', ['start', 'end'])

        for i in range(0, loop_max_range):
            r1 = Range(start=self.minxss_start_times[i], end=self.minxss_end_times[i])
            r2 = Range(start=self.csim_start_times[i], end=self.csim_end_times[i])
            latest_start = max(r1.start, r2.start)
            earliest_end = min(r1.end, r2.end)
            delta = (earliest_end - latest_start).total_seconds()
            overlap_seconds = max(0, delta)
            datetimes.append(latest_start.strftime("%Y-%m-%d %H:%M:%S"))
            overlaps.append(overlap_seconds / 60)

        self.conflicts = pd.DataFrame(list(zip(datetimes, overlaps)))
        self.conflicts.columns = ['Datetime', 'Contact Overlap [minutes]']
        self.conflicts.index = pd.DatetimeIndex(self.conflicts['Datetime'])

    def plot(self):
        ax = self.conflicts[:'2019-03'].plot(title='MinXSS-2 | CSIM Contact Conflict at LASP', legend=False)
        ax.set_xlabel('')
        ax.set_ylabel('conflict time [minutes]')
        fig = ax.get_figure()
        fig.savefig(self.plot_filename, dpi=300)


def main():
    plotter = ConflictPlotter()
    plotter.load_data()
    plotter.compute_overlapping_times()
    plotter.plot()


if __name__ == '__main__':
    main()
