from tkinter import *
from astropy.io import fits
import numpy as np
from xspec import *
import matplotlib.pyplot as plt
from pandastable import Table, TableModel
import pandas as pd
import content_gui as gui
import os
import shutil


def configureFIT(loaded_root, daxsslevel1, y_dim_1):
    """
            Generate FITS Files and creates menu to enter FIT parameters
            :return: None
    """
    global root
    root = loaded_root
    generateFITSFile(daxsslevel1, y_dim_1)
    # GUI for configuring Fit Parameters
    global second_frame
    second_frame = Frame(root)
    second_frame.pack(fill=BOTH, expand=1)

    gui.customLabel(second_frame, "FIT Parameter Menu", 0, 0, 9, 1, color_bg='#58F', color_fg = 'black')

    textlabel = Label(second_frame,
                      text="Instructions for Fitting:\n"
                           "1. Enter Fit Model and Energy Range\n"
                           "2. For Model Elements 0=> Dont Use, 1=> Use\n"
                           "3. Press FIT SPECTRA\n"
                           "4. Plot and Log File will be generated and\nsaved in root directory\n",
                      font=("Helvetica", 12), bg="lightblue", borderwidth=2, relief="ridge",
                      justify="left", fg="black")
    textlabel.grid(row=1, column=0, rowspan=5, columnspan=2, sticky='nesw')

    global fit_model, e_lim_low, e_lim_high, useNe, useMg, useSi, useS, useCa, useFe

    gui.customLabel(second_frame, "DAXSS Spectum ON: " + filename_fits[-24:-4], 1, 2, 2, 1)
    gui.customLabel(second_frame, "Select Model", 2, 2, 1, 1)

    models_array = ['vvapec']
    fit_model = StringVar(root)
    fit_model.set('vvapec')  # default value
    gui.customOptionMenu(second_frame, fit_model, models_array, 2, 3, 1, 1)

    e_lim_low = StringVar()
    gui.customLabel(second_frame, "Lower Limit (keV)", 3, 2, 1, 1)
    gui.customEntry(second_frame, e_lim_low, 3, 3, 1, 1)

    e_lim_high = StringVar()
    gui.customLabel(second_frame, "Upper Limit (keV)", 4, 2, 1, 1)
    gui.customEntry(second_frame, e_lim_high, 4, 3, 1, 1)

    useNe = StringVar()
    gui.customLabel(second_frame, "Fit Ne", 5, 2, 1, 1)
    gui.customEntry(second_frame, useNe, 5, 3, 1, 1)

    useMg = StringVar()
    gui.customLabel(second_frame, "Fit Mg", 1, 4, 1, 1)
    gui.customEntry(second_frame, useMg, 1, 5, 1, 1)

    useSi = StringVar()
    gui.customLabel(second_frame, "Fit Si", 2, 4, 1, 1)
    gui.customEntry(second_frame, useSi, 2, 5, 1, 1)

    useS = StringVar()
    gui.customLabel(second_frame, "Fit S", 3, 4, 1, 1)
    gui.customEntry(second_frame, useS, 3, 5, 1, 1)

    useCa = StringVar()
    gui.customLabel(second_frame, "Fit Ca", 4, 4, 1, 1)
    gui.customEntry(second_frame, useCa, 4, 5, 1, 1)

    useFe = StringVar()
    gui.customLabel(second_frame, "Fit Fe", 5, 4, 1, 1)
    gui.customEntry(second_frame, useFe, 5, 5, 1, 1)

    # Generate Fits File
    gui.customButton(second_frame, "FIT\nSpectra", callFit, 1, 6, 1, 5, 6, font=("Helvetica", 12), color_bg='#58F')
    mainloop()

def generateFITSFile(daxsslevel1, y_dim_1):
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

    global parent_dir, filename_fits, log_filename
    parent_dir = "FIT_Results/"+"minxss_fm3_"+''.join(time_ISO_String).replace(':', '-')

    if os.path.exists(parent_dir):
        shutil.rmtree(parent_dir)
    os.makedirs(parent_dir)

    filename_fits = parent_dir+'/'+'PHA_'+''.join(time_ISO_String).replace(':', '-')+'.pha'
    hdul.writeto(filename_fits, overwrite=True)

    log_filename = parent_dir+'/'+'Log_'+''.join(time_ISO_String).replace(':', '-')+'.txt'

def callFit():

    #Perform Fit and Plot
    fitModel(filename_fits, str(fit_model.get()), str(e_lim_low.get()), str(e_lim_high.get()),
                    int(str(useNe.get())),
                    int(str(useMg.get())),
                    int(str(useSi.get())),
                    int(str(useS.get())),
                    int(str(useCa.get())),
                    int(str(useFe.get())))


def fitModel(filename, selected_model, e_low, e_high, useNe, useMg, useSi, useS, useCa, useFe):
    # Clearing Old Data + Models
    print('**-' + e_low + ' ' + e_high + '-**')
    AllData.clear()
    AllModels.clear()

    # Setting Feldman Abundances
    Xset.abund = 'file FITS_Files/feld_extd'

    logFile = Xset.openLog(log_filename)
    #Xset.show()
    # Loading the DAXSS spectrum
    spec = Spectrum(filename)

    spec.ignore('**-'+e_low+' '+e_high+'-**')

    # define the model
    m1 = Model(selected_model)
    # Free some parameters that are frozen (Mg, Si, and S)

    m1.vvapec.Ne.frozen = 1 - useNe
    m1.vvapec.Mg.frozen = 1 - useMg
    m1.vvapec.Si.frozen = 1 - useSi
    m1.vvapec.S.frozen = 1 - useS
    m1.vvapec.Ca.frozen= 1 - useCa
    m1.vvapec.Fe.frozen = 1 - useFe

    # do the fit
    Fit.nIterations = 100
    Fit.perform()

    result_array = []
    result_array.append(["Red Chi Squared"] + [Fit.statistic / Fit.dof] + ['-'])
    result_array.append([m1.vvapec.kT.name] + [m1.vvapec.kT.values[0]] + [m1.vvapec.kT.sigma])
    result_array.append([m1.vvapec.norm.name] + [m1.vvapec.norm.values[0]] + [m1.vvapec.norm.sigma])
    result_array.append([m1.vvapec.Ne.name] + [m1.vvapec.Ne.values[0]] + [m1.vvapec.Ne.sigma])
    result_array.append([m1.vvapec.Mg.name] + [m1.vvapec.Mg.values[0]] + [m1.vvapec.Mg.sigma])
    result_array.append([m1.vvapec.Si.name] + [m1.vvapec.Si.values[0]] + [m1.vvapec.Si.sigma])
    result_array.append([m1.vvapec.S.name] + [m1.vvapec.S.values[0]] + [m1.vvapec.S.sigma])
    result_array.append([m1.vvapec.Ca.name] + [m1.vvapec.Ca.values[0]] + [m1.vvapec.Ca.sigma])
    result_array.append([m1.vvapec.Fe.name] + [m1.vvapec.Fe.values[0]] + [m1.vvapec.Fe.sigma])


    #Show Fit Results
    showFitResults(result_array)

    # plot data, model and del-chi
    # Plot.device = '/xw'
    Plot.xAxis = 'keV'
    Plot('ld', 'delc')
    ene = Plot.x(plotGroup=1, plotWindow=1)
    eneErr = Plot.xErr(plotGroup=1, plotWindow=1)
    spec = Plot.y(plotGroup=1, plotWindow=1)
    specErr = Plot.yErr(plotGroup=1, plotWindow=1)

    fitmodel = Plot.model(plotGroup=1, plotWindow=1)

    delchi = Plot.y(plotGroup=1, plotWindow=2)
    delchiErr = Plot.yErr(plotGroup=1, plotWindow=2)

    fig0 = plt.figure(num=None, figsize=(6, 4), facecolor='w', edgecolor='k')

    ax0 = fig0.add_axes([0.15, 0.4, 0.8, 0.55])
    ax0.xaxis.set_visible(False)
    plt.errorbar(ene, spec, xerr=eneErr, yerr=specErr, fmt='.', ms=0.5, capsize=1.0, lw=0.8, label='Data')
    plt.step(ene, fitmodel, where='mid', label='Model')
    plt.yscale("log")
    #plt.xscale("log")
    plt.xlim([float(e_low), float(e_high)])
    # plt.ylim([1, 1e6])
    plt.legend()
    plt.ylabel('Rate (counts s$^{-1}$ keV$^{-1}$)')

    ax1 = fig0.add_axes([0.15, 0.15, 0.8, 0.25])
    plt.axhline(0, linestyle='dashed', color='black')
    plt.errorbar(ene, delchi, xerr=eneErr, yerr=delchiErr, fmt='.', ms=0.1, capsize=1.0, lw=0.8)
    plt.xlim([float(e_low), float(e_high)])
    plt.ylabel('$\Delta \chi$')
    plt.xlabel('Energy (keV)')
    #plt.xscale("log")
    plt.show()
    plt.close()


def showFitResults(result_array):
    """
            Prints the FIT Results in a new window.
            :return: None
    """

    child_window = Toplevel(root)
    child_window.geometry("900x450")
    child_window.title("Model FIT Results")
    child_window.configure(background="#c4e0e5")
    df_column_names = ['Param Name', 'Param Value', 'Param Error']
    df = pd.DataFrame(result_array, columns=df_column_names)
    pt = Table(child_window, dataframe = df, showtoolbar=True, showstatusbar=True)
    pt.show()
