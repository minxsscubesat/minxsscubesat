from xspec import *
import matplotlib.pyplot as plt


def fitModel(filename, selected_model, e_low, e_high, useNe, useMg, useSi, useS, useCa, useFe):
    # Clearing Old Data + Models
    print('**-' + e_low + ' ' + e_high + '-**')
    AllData.clear()
    AllModels.clear()

    # Setting Feldman Abundances
    Xset.abund = 'file FITS_Files/feld_extd'
    logFile = Xset.openLog("Log_Files/"+filename[-39:-4]+"_Log.txt")
    #Xset.chatter = 5
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
    plt.savefig('Plot_Files/'+ filename[-39:-4] + "_Fit_Plot.png")
    plt.show()

def main():
    print("Fitting")
    fitModel("FITS_Files/PHA_Files/minxss_fm3_PHA_2022-03-15T23-20-41Z.pha")

if __name__ == "__main__":
    main()