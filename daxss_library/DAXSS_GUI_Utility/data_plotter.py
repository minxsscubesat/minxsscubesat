import matplotlib.pyplot as plt
import content_gui as gui
import data_fitter as fitter
from tkinter import *

def createPlotGUIWindow(root_loaded, daxsslevel1_loaded, level_1_var_list):

    global second_frame, root, daxsslevel1
    daxsslevel1 = daxsslevel1_loaded
    root = root_loaded
    second_frame = Frame(root)
    second_frame.pack(fill=BOTH, expand=1)

    gui.customLabel(second_frame, "Plot Parameter Menu", 0, 0, 9, 1, color_bg='#58F', color_fg = 'black')

    gui.customLabel(second_frame, "X Axis Variable: ", 1, 2, 1, 1)
    global variable_x
    variable_x = StringVar(root)
    variable_x.set("----")  # default value
    gui.customOptionMenu(second_frame,variable_x, level_1_var_list, 1, 3, 1, 1)
    # Show X-Meta Data Button
    gui.customButton(second_frame, "Show X-Variable Metadata", printMetaDataX, 2, 3, 1, 1)

    gui.customLabel(second_frame, "X Scale Type", 3, 2, 1, 1)
    scales_array = ['linear', 'log', 'symlog', 'logit', 'functionlog']
    global x_scale
    x_scale = StringVar(root)
    x_scale.set("----")  # default value
    gui.customOptionMenu(second_frame, x_scale, scales_array, 3, 3, 1, 1)

    global x_lim_low
    x_lim_low = StringVar()
    gui.customLabel(second_frame, "X Limit Lower", 4, 2, 1, 1)
    gui.customEntry(second_frame, x_lim_low, 4, 3, 1, 1)

    global x_lim_upper
    x_lim_upper = StringVar()
    gui.customLabel(second_frame, "X Limit Upper", 5, 2, 1, 1)
    gui.customEntry(second_frame, x_lim_upper, 5, 3, 1, 1)

    global x_lable
    x_lable = StringVar()
    gui.customLabel(second_frame, "X Axis Label", 6, 2, 1, 1)
    gui.customEntry(second_frame, x_lable, 6, 3, 1, 1)

    global x_dim_1
    x_dim_1 = StringVar()
    gui.customLabel(second_frame, "X Dimension-1", 7, 2, 1, 1)
    gui.customEntry(second_frame, x_dim_1, 7, 3, 1, 1)

    global x_dim_2
    x_dim_2 = StringVar()
    gui.customLabel(second_frame, "X Dimension-2", 8, 2, 1, 1)
    gui.customEntry(second_frame, x_dim_2, 8, 3, 1, 1)

    gui.customLabel(second_frame, "Y Axis Variable: ", 1, 5, 1, 1)
    global variable_y
    variable_y = StringVar(root)
    variable_y.set("---")  # default value

    gui.customOptionMenu(second_frame, variable_y, level_1_var_list, 1, 6, 1, 1)
    gui.customButton(second_frame, "Show Y-Variable Metadata", printMetaDataY, 2, 6, 1, 1)
    gui.customLabel(second_frame, "Y Scale Type", 3, 5, 1, 1)

    global y_scale
    y_scale = StringVar(root)
    y_scale.set("----")  # default value
    gui.customOptionMenu(second_frame, y_scale, scales_array, 3, 6, 1, 1)

    global y_lim_low
    y_lim_low = StringVar()
    gui.customLabel(second_frame, "Y Limit Lower", 4, 5, 1, 1)
    gui.customEntry(second_frame, y_lim_low, 4, 6, 1, 1)

    global y_lim_upper
    y_lim_upper = StringVar()
    gui.customLabel(second_frame, "Y Limit Upper", 5, 5, 1, 1)
    gui.customEntry(second_frame, y_lim_upper, 5, 6, 1, 1)

    global y_lable
    y_lable = StringVar()
    gui.customLabel(second_frame, "Y Axis Label", 6, 5, 1, 1)
    gui.customEntry(second_frame, y_lable, 6, 6, 1, 1)

    global y_dim_1
    y_dim_1 = StringVar()
    gui.customLabel(second_frame, "Y Dimension-1", 7, 5, 1, 1)
    gui.customEntry(second_frame, y_dim_1, 7, 6, 1, 1)

    global y_dim_2
    y_dim_2 = StringVar()
    gui.customLabel(second_frame, "Y Dimension-2", 8, 5, 1, 1)
    gui.customEntry(second_frame, y_dim_2, 8, 6, 1, 1)

    gui.customLabel(second_frame, "Plot Type", 6, 0, 1, 1, 15)
    global plot_type
    plot_type_array = ['line','scatter']
    plot_type = StringVar(root)
    plot_type.set("----")  # default value
    gui.customOptionMenu(second_frame, plot_type, plot_type_array, 6, 1, 1, 1)

    gui.customLabel(second_frame, "Plot Color", 7, 0, 1, 1, 15)
    global plot_color
    plot_color = StringVar(root)
    plot_color_array = ['black', 'blue','red','green','yellow','cyan','magenta']
    plot_color.set("----")  # default value
    gui.customOptionMenu(second_frame, plot_color, plot_color_array, 7, 1, 1, 1)

    global plot_legend
    plot_legend = StringVar()
    gui.customLabel(second_frame, "Plot Legend", 8, 0, 1, 1, 15)
    gui.customEntry(second_frame, plot_legend, 8, 1, 1, 1, 15)

    textlabel = Label(second_frame,
                     text="Instructions for Plotting:\n"
                          "1. Select Plot Parameters\n"
                          "2. If netCDF variable as only 1 Dimension,\n"
                         "enter 'NA' in Dimension-2\n"
                          "3. Enter ':' in Dimension for entire array \n"
                          "Press Plot Button to generate Plot",
                     font=("Helvetica", 12), bg="lightblue",borderwidth=2, relief="ridge", justify="left", fg="black")

    textlabel.grid(row=1, column=0, rowspan=5, columnspan=2,sticky='nesw')


    # Plot Button
    gui.customButton(second_frame, "Plot", normalPlot, 1, 8, 1, 4, 6,font=("Helvetica", 12),color_bg='#58F')
    gui.customButton(second_frame, "Overlay", overlayPlot, 4, 8, 1, 3, 6, font=("Helvetica", 12), color_bg='#58F')
    gui.customButton(second_frame, "Configure\nFIT", displayFITMenu, 7, 8, 1, 3, 6, font=("Helvetica", 10), color_bg='#58F')
    mainloop()


def displayFITMenu():

    fitter.configureFIT(root, daxsslevel1, y_dim_1)


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


overlayFlag = 0


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
    plt.close()
