from tkinter import filedialog
from tkinter import *
from PIL import Image, ImageTk
import netCDF4 as nc
import data_plotter as plotter

# GUI Font definitions
LARGE_FONT = ("Verdana", 12)
NORM_FONT = ("Verdana", 10)
SMALL_FONT = ("Verdana", 8)


def loadRawDataUser():
    """
            Loads the netCDF4 file for plotting and creates the main GUI window for setting plot parameters.
            This function is called when the user presses the "Select DAXSS Level-1 netCDF file" button.

            This function also cclls the createPlotGUIWindow function to ask user for plot parameters
            :return: None
    """
    daxss_level1_file_path = filedialog.askopenfilename()
    daxsslevel1 = nc.Dataset(daxss_level1_file_path)
    level_1_var_list = list(daxsslevel1.variables)
    plotter.createPlotGUIWindow(root, daxsslevel1, level_1_var_list)


def aboutMenu():
    """
        Generates a window with information about the DAXSS Data Analysis Utility
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


# Creating Main GUI Window
root = Tk()
root.title("DAXSS Data Analysis Utility")
menu = Menu(root)
root.config(menu=menu)
menu.add_command(label="Select DAXSS Level-1 netCDF file", command=loadRawDataUser)
menu.add_command(label="About", command=aboutMenu)


bg = ImageTk.PhotoImage(Image.open("images/background.jpg").resize((1250,200), Image.ANTIALIAS))
daxss_icon = ImageTk.PhotoImage(Image.open("images/daxss_logo.PNG").resize((200,200), Image.ANTIALIAS))
inspire_icon = ImageTk.PhotoImage(Image.open("images/inspire_logo.jpg").resize((200,200), Image.ANTIALIAS))

# create a label
window_label = Label(root, image = bg)
window_label.place(x=0, y=0)

# create a canvas
my_canvas = Canvas(root, width = 1250, height = 200)
my_canvas.pack(fill = "both", expand = True)

# label to add DAXSS icon
daxss_label = Label(root, image = daxss_icon, bd = 0, width = 200, height=200)
isro_label_window = my_canvas.create_window(0, 0, anchor="nw", window = daxss_label)

# label to add INSPIRE icon
inspire_label = Label(root, image = inspire_icon, bd = 0, width = 200, height=200)
astre_label_window = my_canvas.create_window(1050, 0, anchor="nw", window = inspire_label)

# set image in canvas
my_canvas.create_image(0,0, image=bg, anchor = "nw")

# add a label project name
my_canvas.create_text(600, 100, text = "DAXSS Data Analysis Utility", font = ("Helvetica",30), fill = "#b6d0cf")

root.mainloop()