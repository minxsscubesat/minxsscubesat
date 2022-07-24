# DAXSS Data Analysis Utility

This utility provides a simple Graphical User Interface for plotting and
fitting DAXSS data. The user can select variables in the Level-1 file and 
plot parameters using the utility GUI, to create plots such as time-series
plots, energy spectrum overlay plots etc. The utility also contains
functionality to fit a particular spectra to standard models available
in XSPEC (such as vvapec). The fit parameters such as energy range, 
elements to be fit, can be selected using the menus in the utility GUI. 

## Python Project Structure
The project consists of four python files:
* **main.py** - This is the entry point to the utility, and should be run to start the GUI
* **data_plotter.py** - This contains helper functions to generate plots 
* **data_fitter.py** - This contains helper functions to perform spectral fitting
* **content_gui.py** - This contains custom classes for Graphical User Interface components

## Dependencies
Listed below are the Python Libraries required for running this utility:
* xspec: [XSPEC and PyXSPEC HEASoft Download](https://heasarc.gsfc.nasa.gov/docs/xanadu/xspec/python/html/buildinstall.html)
* tkinter
* PIL
* netCDF4
* matplotlib
* astropy
* numpy
* pandas
* pandastable
* os
* shutil

### Input Files Required
This tool requires the latest [DAXSS Level-1 netCDF4 File](https://www.dropbox.com/sh/0r40mfsphwgjghb/AADt9BFqcRf_vkunjNKf6Rjja/data/fm3/level1/daxss_solarSXR_level1_2022-02-14-mission_v2.0.0.ncdf?dl=0).
The other input files required (RMF, ARF, and feldman extended abundance values) are present in the FITS_Files folder.

### Output Files Generated
The utililty generates plots using the parameters entered by the user as interactive matplotlib figures,
which can be saved using the GUI interface. For spectral fitting the utility generates
Pulse Height Analyser (PHA) files which are stored in the FITS_Results directory in a new folder named
with the timestamp of the spectra. The utility also stores Log files from XSPEC in the
same folder. After fitting a plot of the fit is displayed as a matplotlib interactive plot that can be saved 
using the GUI. Fit results are also displayed as a pandastable that can also be saved using the GUI.

## Instructions to run
1. Run **main.py**.
2. Use the "**Select DAXSS Level-1 netCDF file**" button to select the Level-1 file.
3. Use the GUI to set the plot parameters, more instructions regarding the plot parameters are present on the window
4. Press **Plot** to generate a plot, Press **Overlay** to generate overlay plots.
5. After selecting a particular spectrum, press **Configure Fit** to show the fit parameter menu.
6. Using the FIT Parameter menu, set the various fitting parameters, , more instructions regarding the plot parameters are present on the window.
7. Press **FIT Spectra** to perform the spectral fitting. The spectral fit plot and results are displayed in the GUI.


