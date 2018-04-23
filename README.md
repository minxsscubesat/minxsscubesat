# minxsscubesat
Code for ground-based analysis of MinXSS CubeSat and related instrument data

This is a series of 4K pictures taken by ESA astronaut Tim Peake from the International Space Station of the MinXSS CubeSat being deployed into orbit.

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/hA4id5vAJRQ/0.jpg)](https://www.youtube.com/watch?v=hA4id5vAJRQ)

MinXSS observes soft x-rays from the sun. Specifically, it measures the intensity of the soft x-ray solar spectrum from 0.4 keV (30 Å) to 30 keV (0.4 Å), with resolution of ~0.15 keV. More details can be found on the [MinXSS homepage](http://lasp.colorado.edu/home/minxss/) and in the [published literature](http://lasp.colorado.edu/home/minxss/science/publications/).

# Repository Structure
1. [aia_code](aia_code): This is some code for analyzing data ancillary to MinXSS. The [Atmospheric Imaging Assembly (AIA)](http://aia.lmsal.com/) is a multi-channel, 4K solar imager onboard the Solar Dynamics Observatory. There are much better tools than what's provided here for interfacing with those data built into [sunpy](https://github.com/sunpy/sunpy).
2. [minxss_library](minxss_library): This is the main folder of code for MinXSS.
    1. [analysis](minxss_library/analysis): This contains code from a variety of team members for analyzing the data and producing some quick plots to help solve problems in the moment.
    2. [convenience_functions_generic](minxss_library/convenience_functions_generic): This contains a ton of code for handling common programming tasks. There is a pretty extensive library for time conversions that pulls heavily from [solarsoft](http://www.lmsal.com/solarsoft/) but also includes many easier-to-use wrappers.
    3. [convenience_functions_minxss](minxss_library/convenience_functions_minxss): This contains some helper code specific to MinXSS, e.g., time and unit conversions, finding files.
    4. [pass_planning_tool](minxss_library/pass_planning_tool): This is the tool we use to figure out when our CubeSats will be coming into view of our ground stations and what to do when they do. 
    5. [plotting](minxss_library/plotting): Code to produce a variety of MinXSS data plots, both scientific and engineering. 
    6. [processing_special](minxss_library/processing_special): This contains some code to do some uncommon but sometimes necessary processing. Things like one time fixes to the data.
    7. [processing_standard](minxss_library/processing_standard): This is the code that routinely takes raw telemetry from the spacecraft up through each level of data product.
    8. [real_time](minxss_library/real_time): This is code for displaying sub-selections of the MinXSS data in real time. 
3. [surf_analysis](surf_analysis): This is code used to analyze calibration data taken at the National Institute of Standards and Technology (NIST) Synchrotron Ultraviolet Radiation Facility (SURF). MinXSS-1 and -2 calibrated here, as well as most UV and X-ray instruments built at the Laboratory for Atmospheric and Space Physics. This codebase isn't comprehensive to all of those, but covers MinXSS and instruments that have flown on the extreme ultraviolet variability experiment (EVE) sounding rocket.
