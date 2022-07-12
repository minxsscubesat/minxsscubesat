from tkinter import filedialog
from tkinter import *
from PIL import Image, ImageTk
import matplotlib.pyplot as plt
import netCDF4 as nc
from astropy.io import fits
from matplotlib.dates import date2num, DateFormatter
from dateutil import parser
from datetime import datetime, timedelta
import numpy as np
from sunpy.net import Fido, attrs as a
import xarray
import daxss_data_fitter_utility as fitter
# GUI Font definitions
LARGE_FONT = ("Verdana", 12)
NORM_FONT = ("Verdana", 10)
SMALL_FONT = ("Verdana", 8)

def popupmsg(title, msg):
    popup = Tk()
    popup.wm_title(title)
    label = Label(popup, text=msg, font=NORM_FONT)
    label.pack(side="top", fill="x", pady=10)
    B1 = Button(popup, text="Okay", command = popup.destroy)
    B1.pack()
    popup.mainloop()

def printMetaDataX():
    """
        Prints the metadata of the X-axis netCDF4 variable in a new window.
        :return: None
    """
    child_window = Toplevel(root)
    child_window.geometry("900x450")
    child_window.title("X-axis Variable Meta Data")
    child_window.configure(background="#c4e0e5")
    scrollbar_y = Scrollbar(child_window, orient="vertical")
    scrollbar_y.pack(side=RIGHT, fill=Y)
    text = Text(child_window, height=50, width=110, font=("Times", 12, "bold"), yscrollcommand=scrollbar_y.set,
                   bg="#c4e0e5", bd=0)

    # create label
    Text_label = Label(child_window, text="Variable Meta Data", bg="#c4e0e5")
    Text_label.config(font=("Corier", 14))

    Text_label.pack(padx=10, pady=10)
    text.pack()

    var_array = []
    for var in daxsslevel1.variables.values():
        var_array.append(var)
    plot_variable_x = variable_x.get()
    for i in range(0, len(var_array)):
        if(var_array[i].name == plot_variable_x):
            print(var_array[i])
            text.insert(END, var_array[i])

    scrollbar_y.config(command=text.yview)

def printMetaDataY():
    """
        Prints the metadata of the Y-axis netCDF4 variable in a new window.
        :return: None
    """
    child_window = Toplevel(root)
    child_window.geometry("900x450")
    child_window.title("Y-axis Variable Meta Data")
    child_window.configure(background="#c4e0e5")
    scrollbar_y = Scrollbar(child_window, orient="vertical")
    scrollbar_y.pack(side=RIGHT, fill=Y)
    text = Text(child_window, height=50, width=110, font=("Times", 12, "bold"), yscrollcommand=scrollbar_y.set,
                   bg="#c4e0e5", bd=0)

    # create label
    Text_label = Label(child_window, text="Variable Meta Data", bg="#c4e0e5")
    Text_label.config(font=("Corier", 14))

    Text_label.pack(padx=10, pady=10)
    text.pack()

    var_array = []
    for var in daxsslevel1.variables.values():
        var_array.append(var)
    plot_variable_x = variable_y.get()
    for i in range(0, len(var_array)):
        if(var_array[i].name == plot_variable_x):
            print(var_array[i])
            text.insert(END, var_array[i])

    scrollbar_y.config(command=text.yview)

def loadRawDataUser():
    """
            Loads the netCDF4 file for plotting and creates the main GUI window for setting plot parameters.
            This function is called when the user presses the "Select DAXSS Level-1 netCDF file" button.
            :return: None
    """
    global daxsslevel1
    global level_1_var_list

    daxss_level1_file_path = filedialog.askopenfilename()
    daxsslevel1 = nc.Dataset(daxss_level1_file_path)
    level_1_var_list = list(daxsslevel1.variables)

    # Code for Scrolling
    main_frame = Frame(root)
    main_frame.pack(fill=BOTH, expand=1)

    main_canvas = Canvas(main_frame)
    main_canvas.pack(side=LEFT, fill=BOTH, expand=1)

    my_scrollbar = Scrollbar(main_frame, orient=VERTICAL, command=main_canvas.yview)
    my_scrollbar.pack(side=RIGHT, fill=Y)

    main_canvas.configure(yscrollcommand=my_scrollbar.set)
    main_canvas.bind('<Configure>', lambda e: main_canvas.configure(scrollregion=main_canvas.bbox("all")))

    global second_frame
    second_frame = Frame(main_canvas)
    main_canvas.create_window((0, 0), window=second_frame, anchor='nw')

    label_width = 20
    label_height = 10
    border_width = 2
    label_relief = "ridge"

    # Select x-axis plotting variable
    # X-axis Variable
    lx = Label(second_frame, fg='black', text="X Axis Variable: ", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    lx.grid(row=0, column=2,sticky='nesw')
    global variable_x
    variable_x = StringVar(root)
    variable_x.set("----")  # default value
    w_x = OptionMenu(second_frame, variable_x, *level_1_var_list)
    w_x.config(width=20)
    w_x.config(height=1)
    w_x.config(bg='lightblue')
    w_x.config(font=("Helvetica", 10))
    w_x.grid(row=0, column=3,sticky='nesw')

    # Show X-Meta Data Button
    button = Button(second_frame, width=20, height=1, text="Show X-Variable Metadata",
                    command=printMetaDataX, font=("Helvetica", 10),
                    bg="lightblue")
    button.grid(row=1, column=3, columnspan=1,sticky='nesw')

    l3 = Label(second_frame, fg='black', text="X Scale Type", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l3.grid(row=2, column=2)

    scales_array = ['linear', 'log', 'symlog', 'logit', 'functionlog']
    global x_scale
    x_scale = StringVar(root)
    x_scale.set("----")  # default value
    w_x = OptionMenu(second_frame, x_scale, *scales_array)
    w_x.config(width=20)
    w_x.config(height=1)
    w_x.config(bg='lightblue')
    w_x.config(font=("Helvetica", 10))
    w_x.grid(row=2, column=3, sticky='nesw')

    global x_lim_low
    x_lim_low = StringVar()
    l4 = Label(second_frame, fg='black', text="X Limit Lower", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=3, column=2)
    e4 = Entry(second_frame, fg='blue', textvariable=x_lim_low, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=3, column=3)

    global x_lim_upper
    x_lim_upper = StringVar()
    l5 = Label(second_frame, fg='black', text="X Limit Upper", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l5.grid(row=4, column=2)
    e6 = Entry(second_frame, fg='blue', textvariable=x_lim_upper, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e6.grid(row=4, column=3)


    global x_lable
    x_lable = StringVar()
    l8 = Label(second_frame, fg='black', text="X Axis Label", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l8.grid(row=5, column=2)
    e9 = Entry(second_frame, fg='blue', textvariable=x_lable, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e9.grid(row=5, column=3)

    global x_dim_1
    x_dim_1 = StringVar()
    l81 = Label(second_frame, fg='black', text="X Dimension-1", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l81.grid(row=6, column=2)
    e91 = Entry(second_frame, fg='blue', textvariable=x_dim_1, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e91.grid(row=6, column=3)

    global x_dim_2
    x_dim_2 = StringVar()
    l811 = Label(second_frame, fg='black', text="X Dimension-2", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l811.grid(row=7, column=2)
    e911 = Entry(second_frame, fg='blue', textvariable=x_dim_2, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e911.grid(row=7, column=3)


    # Select y-axis plotting variable
    # Y-axis Variable
    ly = Label(second_frame, fg='black', text="Y Axis Variable: ", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    ly.grid(row=0, column=5,sticky='nesw')
    global variable_y
    variable_y = StringVar(root)
    variable_y.set("---")  # default value
    w_y = OptionMenu(second_frame, variable_y, *level_1_var_list)
    w_y.config(width=20)
    w_y.config(height=1)
    w_y.config(bg='lightblue')
    w_y.config(font=("Helvetica", 10))
    w_y.grid(row=0, column=6,sticky='nesw')

    # Show Y-Meta Data Button
    button = Button(second_frame, width=20, height=1, text="Show Y-Variable Metadata",
                    command=printMetaDataY, font=("Helvetica", 10),
                    bg="lightblue")
    button.grid(row=1, column=6, columnspan=1,sticky='nesw')

    #Plot Parameters Entry Labels

    l3 = Label(second_frame, fg='black', text="Y Scale Type", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l3.grid(row=2, column=5)
    global y_scale
    y_scale = StringVar(root)
    y_scale.set("----")  # default value
    w_x = OptionMenu(second_frame, y_scale, *scales_array)
    w_x.config(width=20)
    w_x.config(height=1)
    w_x.config(bg='lightblue')
    w_x.config(font=("Helvetica", 10))
    w_x.grid(row=2, column=6, sticky='nesw')

    global y_lim_low
    y_lim_low = StringVar()
    l1 = Label(second_frame, fg='black', text="Y Limit Lower", font=('Arial', 12, 'bold'), width=label_width,
                borderwidth=border_width, relief=label_relief, bg="lightblue")
    l1.grid(row=3, column=5)
    e1 = Entry(second_frame, fg='blue', textvariable=y_lim_low, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e1.grid(row=3, column=6)

    global y_lim_upper
    y_lim_upper = StringVar()
    l2 = Label(second_frame, fg='black', text="Y Limit Upper", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l2.grid(row=4, column=5)
    e2 = Entry(second_frame, fg='blue', textvariable=y_lim_upper, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e2.grid(row=4, column=6)

    global y_lable
    y_lable = StringVar()
    l7 = Label(second_frame, fg='black', text="Y Axis Label", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l7.grid(row=5, column=5)
    e8 = Entry(second_frame, fg='blue', textvariable=y_lable, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e8.grid(row=5, column=6)

    global y_dim_1
    y_dim_1 = StringVar()
    l81 = Label(second_frame, fg='black', text="Y Dimension-1", font=('Arial', 12, 'bold'), width=label_width,
                borderwidth=border_width, relief=label_relief, bg="lightblue")
    l81.grid(row=6, column=5)
    e91 = Entry(second_frame, fg='blue', textvariable=y_dim_1, font=('Arial', 12, 'bold'), width=label_width,
                borderwidth=border_width, relief=label_relief)
    e91.grid(row=6, column=6)

    global y_dim_2
    y_dim_2 = StringVar()
    l811 = Label(second_frame, fg='black', text="Y Dimension-2", font=('Arial', 12, 'bold'), width=label_width,
                 borderwidth=border_width, relief=label_relief, bg="lightblue")
    l811.grid(row=7, column=5)
    e911 = Entry(second_frame, fg='blue', textvariable=y_dim_2, font=('Arial', 12, 'bold'), width=label_width,
                 borderwidth=border_width, relief=label_relief)
    e911.grid(row=7, column=6)

    l7 = Label(second_frame, fg='black', text="Plot Type", font=('Arial', 12, 'bold'), width=15,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l7.grid(row=5, column=0, sticky='nesw')

    global plot_type
    plot_type_array = ['line','scatter']
    plot_type = StringVar(root)
    plot_type.set("----")  # default value
    w_x = OptionMenu(second_frame, plot_type, *plot_type_array)
    w_x.config(width=20)
    w_x.config(height=1)
    w_x.config(bg='lightblue')
    w_x.config(font=("Helvetica", 10))
    w_x.grid(row=5, column=1, sticky='nesw')

    lc = Label(second_frame, fg='black', text="Plot Color", font=('Arial', 12, 'bold'), width=15,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    lc.grid(row=6, column=0, sticky='nesw')

    global plot_color
    plot_color = StringVar(root)
    plot_color_array = ['black', 'blue','red','green','yellow','cyan','magenta']
    plot_color.set("----")  # default value
    w_x = OptionMenu(second_frame, plot_color, *plot_color_array)
    w_x.config(width=20)
    w_x.config(height=1)
    w_x.config(bg='lightblue')
    w_x.config(font=("Helvetica", 10))
    w_x.grid(row=6, column=1, sticky='nesw')

    global plot_legend
    plot_legend = StringVar()
    lc = Label(second_frame, fg='black', text="Plot Legend", font=('Arial', 12, 'bold'), width=15,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    lc.grid(row=7, column=0, sticky='nesw')
    ec = Entry(second_frame, fg='blue', textvariable=plot_legend, font=('Arial', 12, 'bold'), width=15,
               borderwidth=border_width, relief=label_relief)
    ec.grid(row=7, column=1, sticky='nesw')

    textlabel = Label(second_frame,
                      text="Instructions for Plotting:\n"
                           "1. Select Plot Parameters\n"
                           "2. If netCDF variable as only 1 Dimension,\n"
                           "enter 'NA' in Dimension-2\n"
                           "3. Enter ':' in Dimension for entire array \n"
                           "Press Plot Button to generate Plot",
                      font=("Helvetica", 12), bg="lightblue",borderwidth=border_width, relief=label_relief, justify="left", fg="black")

    textlabel.grid(row=0, column=0, rowspan=5, columnspan=2,sticky='nesw')

    # Plot Button
    button = Button(second_frame, width=6, height=2, text="PLOT", command=normalPlot, font=("Helvetica", 12),
                    bg='#58F')
    button.grid(row=0, column=8, rowspan=4, sticky='nesw')

    button = Button(second_frame, width=6, height=2, text="Overlay", command=overlayPlot, font=("Helvetica", 12),
                    bg='#58F')
    button.grid(row=3, column=8, rowspan=3, sticky='nesw')

    # Multiscale plot
    #button_2 = Button(second_frame, width=6, height=2, text="PLOT\n(multi Scale)", command=generateMultiScalePlot,
    #                  font=("Helvetica", 8),
    #                  bg='#58F')
    #button_2.grid(row=2, column=8, rowspan=2, sticky='nesw')

    # Plot vs Array Index Button
    #button_2 = Button(second_frame, width=6, height=2, text="PLOT\n(vs Index)", command=generatePlotArrayIndex, font=("Helvetica", 8),
    #                bg='#58F')
    #button_2.grid(row=4, column=8, rowspan=2, sticky='nesw')

    # Generate Fits File
    button_2 = Button(second_frame, width=6, height=2, text="CONFIGURE\nFIT", command=generateFITSFile,
                      font=("Helvetica", 8),bg='#58F')
    button_2.grid(row=6, column=8, rowspan=3, sticky='nesw')
    mainloop()

overFlag = 0
def overlayPlot():
    global overlayFlag
    overlayFlag = 1
    generatePlot()

def normalPlot():
    global overlayFlag
    overlayFlag = 0
    generatePlot()

def generatePlot():
    """
        Generates a plot of the Y-variable vs the X-variable, with the parameters set by the user.
        This function is called when the user presses the Plot button.
        :return: None
    """
    if overlayFlag == 0:
        fig, ax = plt.subplots()

    # Plotting Spectrum
    # X-axis plot parameters

    plot_variable_x = variable_x.get()

    if (x_dim_2.get() == 'NA'):
        if(x_dim_1.get() == ':'):
            x_plot = daxsslevel1[plot_variable_x][:]
        else:
            x_plot = daxsslevel1[plot_variable_x][int(x_dim_1.get())]
    else:
        if (x_dim_2.get() == ':'):
            x_plot = daxsslevel1[plot_variable_x][int(x_dim_1.get()), :]
        else:
            x_plot = daxsslevel1[plot_variable_x][int(x_dim_1.get()), int(x_dim_2.get())]

    plt.xlim([float(x_lim_low.get()), float(x_lim_upper.get())])
    plt.xscale(str(x_scale.get()))
    plt.xlabel(str(x_lable.get()))

    #Y axis plot parameters
    plot_variable_y = variable_y.get()
    if (y_dim_2.get() == 'NA'):
        if(y_dim_1.get() == ':'):
            y_plot = daxsslevel1[plot_variable_y][:]
        else:
            y_plot = daxsslevel1[plot_variable_y][int(y_dim_1.get())]
    else:
        if (y_dim_2.get() == ':'):
            y_plot = daxsslevel1[plot_variable_y][int(y_dim_1.get()), :]
        else:
            y_plot = daxsslevel1[plot_variable_y][int(y_dim_1.get()), int(y_dim_2.get())]


    plt.ylim([float(y_lim_low.get()), float(y_lim_upper.get())])
    plt.yscale(str(y_scale.get()))
    plt.ylabel(str(y_lable.get()))

    color_code_array = [['black','k'], ['blue','b'],['red','r'],['green','g'],['yellow','y'],['cyan','c'],['magenta','m']]
    chosen_plot_color = 'k'
    plot_color_selected = str(plot_color.get())
    for i in range(len(color_code_array)):
        if(color_code_array[i][0] == plot_color_selected):
            chosen_plot_color = color_code_array[i][1]
            break
    if(plot_type.get()=="line"):
        plt.plot(x_plot, y_plot, color=chosen_plot_color, label=str(plot_legend.get()))
    elif (plot_type.get() == "scatter"):
        scatter = plt.scatter(x_plot, y_plot, color=chosen_plot_color, label=str(plot_legend.get()))
    #plt.suptitle('DAXSS Plot')
    plt.legend()

    if (plot_type.get() == "scatter"):
        annotation = ax.annotate(
            text = '',
            xy = (0,0),
            xytext = (15,15),
            textcoords = 'offset points',
            bbox={'boxstyle':'round','fc':'w'},
            arrowprops={'arrowstyle':'->'},
        )
        annotation.set_visible(False)

        def motion_hover(event):
            annotation_visibility = annotation.get_visible()
            if event.inaxes == ax:
                is_contained, annotation_index = scatter.contains(event)
                if(is_contained):
                    data_point_location = scatter.get_offsets()[annotation_index['ind'][0]]
                    annotation.xy = data_point_location
                    xy_label = '({0:.0f},{1:.4f}, {2:.4f})'.format(annotation_index['ind'][0],data_point_location[0], data_point_location[1])
                    annotation.set_text(xy_label)
                    annotation.set_visible(True)
                    fig.canvas.draw_idle()
                else:
                    if annotation_visibility:
                        annotation.set_visible(False)
                        fig.canvas.draw_idle()

        fig.canvas.mpl_connect('motion_notify_event',motion_hover)

    plt.show()

def generatePlotArrayIndex():
    """
        Generates a plot of the Y-variable vs its array index, with the parameters set by the user.
        This function is called when the user presses the Plot (vs index) button.
        :return: None
    """
    plt.figure()
    # Y axis plot parameters
    plot_variable_y = variable_y.get()
    if (y_dim_2.get() == 'NA'):
        if (y_dim_1.get() == ':'):
            y_plot = daxsslevel1[plot_variable_y][:]
        else:
            y_plot = daxsslevel1[plot_variable_y][int(y_dim_1.get())]
    else:
        if (y_dim_2.get() == ':'):
            y_plot = daxsslevel1[plot_variable_y][int(y_dim_1.get()), :]
        else:
            y_plot = daxsslevel1[plot_variable_y][int(y_dim_1.get()), int(y_dim_2.get())]

    plt.ylim([float(y_lim_low.get()), float(y_lim_upper.get())])
    plt.yscale(str(y_scale.get()))
    plt.ylabel(str(y_lable.get()))
    plt.xlabel('DAXSS Level-1 Measurement Index')
    color_code_array = [['black', 'k'], ['blue', 'b'], ['red', 'r'], ['green', 'g'], ['yellow', 'y'], ['cyan', 'c'],
                        ['magenta', 'm']]

    chosen_plot_color = 'k'
    plot_color_selected = str(plot_color.get())
    for i in range(len(color_code_array)):
        if (color_code_array[i][0] == plot_color_selected):
            chosen_plot_color = color_code_array[i][1]
            break

    x_plot=[]
    for i in range(0,len(y_plot)):
        x_plot.append(i)
    if (plot_type.get() == "line"):
        plt.plot(x_plot, y_plot, color=chosen_plot_color, label=str(plot_legend.get()))
    elif (plot_type.get() == "scatter"):
        plt.scatter(x_plot, y_plot, color=chosen_plot_color, label=str(plot_legend.get()))
    # plt.suptitle('DAXSS Plot')
    plt.legend()
    plt.show()

def generateMultiScalePlot():
    plt.figure()
    plt.rcParams["figure.figsize"] = [7.00, 3.50]
    plt.rcParams["figure.autolayout"] = True

    time_ISO = daxsslevel1['TIME_ISO'][:]
    daxss_datetime_obj_array = []
    for time_index in range(len(time_ISO)):
        time_ISO_String = []
        for var_index in range(0, 20):
            time_str = time_ISO[time_index][var_index].decode("utf-8")
            time_ISO_String.append(time_str)
        daxss_datetime_obj_array.append(parser.parse(''.join(time_ISO_String)))

    daxss_time = date2num(daxss_datetime_obj_array)
    daxss_x123_slow_cps = daxsslevel1['X123_SLOW_CPS'][:]

    # Path to Level-1 File
    #goes_file_path = 'netCDF_Files/GOES/goes_combined.nc'
    goes_file_path = 'netCDF_Files/GOES/Data_Since_Feb_2022/sci_xrsf-l2-flx1s_g16_d20220315_v2-1-0.nc'
    # Import File as a netCDF Dataset
    goes_data = nc.Dataset(goes_file_path)

    goes_time_array = goes_data['time'][:]
    base_date = datetime(2000, 1, 1, 12, 0, 0)
    goes_datetime_obj_array = []
    for i in range(len(goes_time_array)):
        curr_time = base_date + timedelta(seconds=goes_time_array[i])
        goes_datetime_obj_array.append(curr_time)

    goes_time = date2num(goes_datetime_obj_array)
    goes_flux_data = goes_data['xrsb_flux'][:]

    fig, ax1 = plt.subplots()

    ax1.plot_date(daxss_time, daxss_x123_slow_cps, 'o--', color='red', label="DAXSS Slow Counts")
    ax1.set_ylabel("DAXSS Slow Counts (Counts/sec)", color="red", fontsize=12)
    ax2 = ax1.twinx()
    ax2.plot_date(goes_time, goes_flux_data, 'o:', color='blue', label="GOES XRS-B Flux")
    ax2.set_ylabel("GOES XRS-B Flux (W/m^2)", color="blue", fontsize=12)

    ax1.xaxis.set_major_formatter(DateFormatter('%Y-%m-%d-%H-%M'))
    ax1.tick_params(rotation=45)
    plt.show()

def generateFITSFile():
    """
            Generate FITS Files and Fits to Model
            :return: None
    """
    # Creating the FITS file for DAXSS
    # Primary HDU - Header
    hdr_dummy = fits.Header()
    hdr_data = fits.Header()
    hdr_dummy['MISSION'] = "InspireSat-1"
    hdr_dummy['TELESCOP'] = "InspireSat-1"
    hdr_dummy['INSTRUME'] = "DAXSS"
    hdr_dummy['ORIGIN'] = "LASP"
    hdr_dummy['CREATOR'] = "DAXSSPlotterUtility_v1"
    hdr_dummy['CONTENT'] = "Type-I PHA file"

    #Data Header
    hdr_data['MISSION'] = "InspireSat-1"
    hdr_data['TELESCOP'] = "InspireSat-1"
    hdr_data['INSTRUME'] = "DAXSS"
    hdr_data['ORIGIN'] = "LASP"
    hdr_data['CREATOR'] = "DAXSSPlotterUtility_v1"
    hdr_data['CONTENT'] = "SPECTRUM"
    hdr_data['HDUCLASS'] = "OGIP"
    hdr_data['LONGSTRN'] = "OGIP 1.0"
    hdr_data['HDUCLAS1'] = "SPECTRUM"
    hdr_data['HDUVERS1'] = "1.2.1"
    hdr_data['HDUVERS'] = "1.2.1"

    hdr_data['AREASCAL'] = "1"
    hdr_data['BACKSCAL'] = "1"
    hdr_data['CORRSCAL'] = "1"
    hdr_data['BACKFILE'] = "none"

    hdr_data['RESPFILE'] = "FITS_Files/minxss_fm3_RMF.fits"
    hdr_data['ANCRFILE'] = "FITS_Files/minxss_fm3_ARF.fits"

    hdr_data['CHANTYPE'] = "PHA"
    hdr_data['POISSERR'] = "F"

    hdr_data['CORRFILE'] = "none"
    hdr_data['EXTNAME']  = 'SPECTRUM'
    hdr_data['FILTER']   = "Be/Kapton"
    hdr_data['EXPOSURE'] = "9"
    hdr_data['DETCHANS'] = "1000"
    hdr_data['GROUPING'] = "0"

    channel_number_array = []
    #quality_array = []
    systematic_error_array = []
    for i in range(1,1001,1):
        channel_number_array.append(np.int32(i))
        #quality_array.append(np.int16(1) - np.int16(daxsslevel1['VALID_FLAG'][y_dim_1.get(),i+5]))
        systematic_error_array.append(np.float32(daxsslevel1['SPECTRUM_CPS_ACCURACY'][y_dim_1.get(), i+5]/daxsslevel1['SPECTRUM_CPS'][y_dim_1.get(),i+5]))

    c1 = channel_number_array
    c2 = daxsslevel1['SPECTRUM_CPS'][y_dim_1.get(),6:1006]
    c3 = daxsslevel1['SPECTRUM_CPS_PRECISION'][y_dim_1.get(), 6:1006] # Precision = Statitical Error
    c4 = systematic_error_array  # Accuracy = Systematic Error
    #c5 = quality_array

    # Creating and Storing the FITS File
    time_ISO_String = []
    for var_index in range(0, 20):
        time_str = daxsslevel1['TIME_ISO'][int(y_dim_1.get())][var_index].decode("utf-8")
        time_ISO_String.append(time_str)

    hdr_dummy['FILENAME'] = 'minxss_fm3_PHA_'+''.join(time_ISO_String).replace(':', '-')+'.pha'
    hdr_dummy['DATE'] = ''.join(time_ISO_String).replace(':', '-')

    hdr_data['FILENAME'] = hdr_dummy['FILENAME']
    hdr_data['DATE'] =  hdr_dummy['DATE']

    # Data
    hdu_data = fits.BinTableHDU.from_columns(
            [fits.Column(name='CHANNEL', format='J', array=c1),
             fits.Column(name='RATE', format='E', array=c2),
             fits.Column(name='STAT_ERR', format='E', array=c3),
             fits.Column(name='SYS_ERR', format='E', array=c4)],header=hdr_data)
             #fits.Column(name='QUALITY', format='J', array=c5)],
    dummy_primary = fits.PrimaryHDU(header=hdr_dummy)
    hdul = fits.HDUList([dummy_primary, hdu_data])

    global filename_fits
    filename_fits = 'FITS_Files/PHA_Files/minxss_fm3_PHA_'+''.join(time_ISO_String).replace(':', '-')+'.pha'
    hdul.writeto(filename_fits, overwrite=True)

    # GUI for configuring Fit Parameters
    main_frame = Frame(root)
    main_frame.pack(fill=BOTH, expand=1)

    main_canvas = Canvas(main_frame)
    main_canvas.pack(side=LEFT, fill=BOTH, expand=1)

    my_scrollbar = Scrollbar(main_frame, orient=VERTICAL, command=main_canvas.yview)
    my_scrollbar.pack(side=RIGHT, fill=Y)

    main_canvas.configure(yscrollcommand=my_scrollbar.set)
    main_canvas.bind('<Configure>', lambda e: main_canvas.configure(scrollregion=main_canvas.bbox("all")))

    global second_frame
    second_frame = Frame(main_canvas)
    main_canvas.create_window((0, 0), window=second_frame, anchor='nw')

    label_width = 20
    label_height = 10
    border_width = 2
    label_relief = "ridge"

    textlabel = Label(second_frame,
                      text="Instructions for Fitting:\n"
                           "1. Enter Fit Model and Energy Range\n"
                           "2. For Model Elements 0=> Dont Use, 1=> Use\n"
                           "3. Press FIT SPECTRA\n"
                           "4. Plot and Log File will be generated and\nsaved in root directory\n",
                      font=("Helvetica", 12), bg="lightblue", borderwidth=border_width, relief=label_relief,
                      justify="left", fg="black")
    textlabel.grid(row=0, column=0, rowspan=5, columnspan=2, sticky='nesw')

    global fit_model, e_lim_low, e_lim_high, useNe, useMg, useSi, useS, useCa, useFe

    # Selected DAXSS Spectrum
    lx = Label(second_frame, fg='black', text="DAXSS Spectum ON: " + filename_fits[-24:-4], font=('Arial', 12, 'bold'),
               width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    lx.grid(row=0, column=2, columnspan=2, sticky='nesw')

    l3 = Label(second_frame, fg='black', text="Select Model", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l3.grid(row=1, column=2)

    scales_array = ['apec', 'vapec', 'vvapec']
    fit_model = StringVar(root)
    fit_model.set('vvapec')  # default value
    w_x = OptionMenu(second_frame, fit_model, *scales_array)
    w_x.config(width=20)
    w_x.config(height=1)
    w_x.config(bg='lightblue')
    w_x.config(font=("Helvetica", 10))
    w_x.grid(row=1, column=3)

    e_lim_low = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit Limit Low", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=2, column=2)
    e4 = Entry(second_frame, fg='blue', textvariable=e_lim_low, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=2, column=3)

    e_lim_high = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit Limit High", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=3, column=2)
    e4 = Entry(second_frame, fg='blue', textvariable=e_lim_high, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=3, column=3)

    useNe = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit Ne", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=4, column=2)
    e4 = Entry(second_frame, fg='blue', textvariable=useNe, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=4, column=3)

    useMg = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit Mg", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=0, column=4)
    e4 = Entry(second_frame, fg='blue', textvariable=useMg, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=0, column=5)

    useSi = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit Si", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=1, column=4)
    e4 = Entry(second_frame, fg='blue', textvariable=useSi, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=1, column=5)

    useS = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit S", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=2, column=4)
    e4 = Entry(second_frame, fg='blue', textvariable=useS, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=2, column=5)

    useCa = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit Ca", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=3, column=4)
    e4 = Entry(second_frame, fg='blue', textvariable=useCa, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=3, column=5)

    useFe = StringVar()
    l4 = Label(second_frame, fg='black', text="Fit Fe", font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief, bg="lightblue")
    l4.grid(row=4, column=4)
    e4 = Entry(second_frame, fg='blue', textvariable=useFe, font=('Arial', 12, 'bold'), width=label_width,
               borderwidth=border_width, relief=label_relief)
    e4.grid(row=4, column=5)


    # Generate Fits File
    button_2 = Button(second_frame, width=8, height=2, text="FIT\nSPECTRA", command=callFit,
                      font=("Helvetica", 8), bg='#58F')
    button_2.grid(row=0, column=6, rowspan=5,sticky='nesw')


    mainloop()

def callFit():
    fitter.fitModel(filename_fits, str(fit_model.get()), str(e_lim_low.get()), str(e_lim_high.get()),
                    int(str(useNe.get())),
                    int(str(useMg.get())),
                    int(str(useSi.get())),
                    int(str(useS.get())),
                    int(str(useCa.get())),
                    int(str(useFe.get())))


def downloadData():
    # Searching for GOES XRS Data
    #results = Fido.search(a.Time("2022-02-28 00:00", "2022-06-13 00:00"), a.Instrument("XRS"),
    #                      a.goes.SatelliteNumber(16))
    #print(results)

    #downloaded_files = Fido.fetch(results, path='netCDF_Files/GOES/Data_Since_Feb_2022/{file}')
    ds = xarray.open_mfdataset('netCDF_Files/GOES/Data_Since_Feb_2022/sci_xrsf-l2-flx1s_g16_*.nc',combine='nested', concat_dim="time")
    ds.to_netcdf('netCDF_Files/GOES/goes_combined.nc')
    popupmsg("Files Downloaded", "Success! GOES Files Downloaded")

def aboutMenu():
    """
        Generates a window with information about the DAXSS Data Plotter Utility
        :return: None
    """
    child1_window=Toplevel(root)
    child1_window.geometry("800x600")
    child1_window.title("About: DAXSS Data Analysis Utility")
    child1_window.configure(background = "#004e92")
    child1_label2 = Label(child1_window, text="The Dual-zone Aperture X-ray Solar Spectrometer (DAXSS) is an "
                                              "instrument on-board the INSPIRESat-1 small satellite,\n"
                                              "launched on 14th February 2022. This tool can generate plots from "
                                              "the DAXSS Level-1 netCDF file.\n"
                                              "The tool can also be used to plot data from any other netCDF file.",
                                              font = ("Times",12), bg = "#004e92", justify = "center", fg = "white")
    child1_label2.pack(padx=10, pady=20)
    child1_label4 = Label(child1_window, text="\nThe main features of this tool are:", font = ("Times",12,"bold"),
                                              bg = "#004e92", justify = "right", fg = "white")
    child1_label4.pack()
    child1_label6 = Label(child1_window, text="1. A netCDF file can be selected using the 'Select DAXSS Level-1 netCDF"
                                              " file' button in the menu bar\n"
                                              "2. Various plot parameters can be set using the GUI of the tool\n"
                                              "3. The 'Plot' Button generates a plot of the selected Y-variable "
                                              "vs X-variable\n"
                                              "4. The 'Plot (vs Index)' Button generates a plot of the selected "
                                              "Y-variable vs its Array Index\n"
                                              "5. Multiple Y-Variables can be plotted in the same window, "
                                              "by pressing the plot button each time after selecting a new variable\n"
                                              "\n", font = ("Times",12), bg = "#004e92", justify = "left", fg = "white")
    child1_label6.pack(padx=10, pady=10)
    child1_label7 = Label(child1_window, text="DAXSS/MinXSS PI: Dr. Thomas N. Woods\nDAXSS Analysis Utility created"
                                              " by Anant Kumar T K\n"
                                              "For more information visit: https://lasp.colorado.edu/home/minxss/\n"
                                              "DAXSS Data Plotter Utility: "
                                              "https://github.com/anant-infinity/DAXSS_Data_Analysis",
                                              font = ("Times",12), bg = "#004e92", justify = "center", fg = "white")
    child1_label7.pack(padx=10, pady=10)



root = Tk()
root.title("DAXSS Data Analysis Utility")
menu = Menu(root)
root.config(menu=menu)
menu.add_command(label="Select DAXSS Level-1 netCDF file", command=loadRawDataUser)
menu.add_command(label="About", command=aboutMenu)
#menu.add_command(label="Download GOES Data", command=downloadData)


bg = ImageTk.PhotoImage(Image.open("daxss_plotter_utility_images/background.jpg").resize((1200,200), Image.ANTIALIAS))
daxss_icon = ImageTk.PhotoImage(Image.open("daxss_plotter_utility_images/daxss_logo.PNG").resize((200,200), Image.ANTIALIAS))
inspire_icon = ImageTk.PhotoImage(Image.open("daxss_plotter_utility_images/inspire_logo.jpg").resize((200,200), Image.ANTIALIAS))

# create a label
window_label = Label(root, image = bg)
window_label.place(x=0, y=0)

# create a canvas
my_canvas = Canvas(root, width = 1280, height = 200)
my_canvas.pack(fill = "both", expand = True)

# label to add DAXSS icon
daxss_label = Label(root, image = daxss_icon, bd = 0, width = 240, height=200)
isro_label_window = my_canvas.create_window(0, 0, anchor="nw", window = daxss_label)

# label to add INSPIRE icon
inspire_label = Label(root, image = inspire_icon, bd = 0, width = 240, height=200)
astre_label_window = my_canvas.create_window(1040, 0, anchor="nw", window = inspire_label)

# set image in canvas
my_canvas.create_image(0,0, image=bg, anchor = "nw")

# add a label project name
my_canvas.create_text(600, 100, text = "DAXSS Data Analysis Utility", font = ("Helvetica",30), fill = "#b6d0cf")

root.mainloop()