;
;	files2018.pro
;
;	Define files for SURF calibrations of rocket XRS-X123-SPS in March 2018
;
;	.run files2018.pro to setup list of Hydra and SURF files
;
;	then those files can be used for calls to read_hydra_rxrs.pro, plot_rxrs_hydra.pro, rxrs_center.pro, etc.
;
;	Expect pair of fileNNN and surfNNN  where NNN is number for SURF calibration experiment
;

dir_code = "~/Dropbox/minxss_dropbox/code/surf_analysis/"
dir_data_hydra = "~/Dropbox/minxss_dropbox/data/calibration/rocket_x123_xrs_picosim/hydra_telemetry_files/"
dir_data_surf = "~/Dropbox/minxss_dropbox/data/calibration/rocket_x123_xrs_picosim/surfer_files/"

; CENTER XRS-B2 coarse Y scan on 2018-03-26 at 8 PM EDT
file1 = dir_data_hydra + 'tlm_packets_2018_085_20_24_46'
surf1 = dir_data_surf  + 'SURF_032718_002017.txt'

; CENTER XRS-B2 X coarse scan on 2018-03-27 at 09:45:20
file2 = dir_data_hydra + 'tlm_packets_2018_086_09_38_47'
surf2 = dir_data_surf  + 'SURF_032718_133905.txt'

; CENTER XRS-B2 Y fine scan on 2018-03-27 at 10:10:48
file3 = dir_data_hydra + 'tlm_packets_2018_086_10_10_48'
surf3 = dir_data_surf  + 'SURF_032718_141050.txt'

; CENTER XRS-B2 X fine scan on 2018-03-27 at 10:37:53
file4 = dir_data_hydra + 'tlm_packets_2018_086_10_37_53'
surf4 = dir_data_surf  + 'SURF_032718_143805.txt'

; CENTER XRS-B2 yaw fine scan on 2018-03-27 at 11:12:20
file5 = dir_data_hydra + 'tlm_packets_2018_086_11_20_06'
surf5 = dir_data_surf  + 'SURF_032718_152007.txt'

; CENTER XRS-B2 pitch fine scan on 2018-03-27 at 12:11:59
file6 = dir_data_hydra + 'tlm_packets_2018_086_12_07_14'
surf6 = dir_data_surf  + 'SURF_032718_160716.txt'

; CENTER XRS-B2 pitch repeat fine scan on 2018-03-27
file7 = dir_data_hydra + 'tlm_packets_2018_086_12_26_46'
surf7 = dir_data_surf  + 'SURF_032718_162645.txt'

; CENTER XRS-B2 pitch repeat 2 fine scan on 2018-03-27 at
file8 = dir_data_hydra + 'tlm_packets_2018_086_12_34_16'
surf8 = dir_data_surf  + 'SURF_032718_163418.txt'

; CENTER X123 X coarse scan on 2018-03-27 at 13:22:52
file9 = dir_data_hydra + 'tlm_packets_2018_086_13_22_52'
surf9 = dir_data_surf  + 'SURF_032718_172254.txt'

; CENTER X123 Y coarse scan on 2018-03-27 at 13:35:53
file10 = dir_data_hydra + 'tlm_packets_2018_086_13_42_08'
surf10 = dir_data_surf  + 'SURF_032718_174210.txt'

; CENTER X123 X fine scan on 2018-03-27 at 14:09
file11 = dir_data_hydra + 'tlm_packets_2018_086_14_09_40'
surf11 = dir_data_surf  + 'SURF_032718_180950.txt'

; CENTER X123 Y fine scan on 2018-03-27 at 15:03
file12 = dir_data_hydra + 'tlm_packets_2018_086_15_03_08'
surf12 = dir_data_surf  + 'SURF_032718_190313.txt'

;  CAN NOT DO WIDE ENOUGH Yaw or Pitch SCAN FOR X123 Centering
;   (it is +/- 4 degrees, SURF limit is +/- 3 degrees)

; CENTER SPS X coarse scan on 2018-03-27 at 16:30 at 285MeV full fuzz
file13 = dir_data_hydra + 'tlm_packets_2018_086_16_30_27'
surf13 = dir_data_surf  + 'SURF_032718_203037.txt'

; CENTER SPS Y coarse scan on 2018-03-27 at 17:00
file14 = dir_data_hydra + 'tlm_packets_2018_086_17_00_20'
surf14 = dir_data_surf  + 'SURF_032718_210048.txt'

; CENTER SPS X fine scan on 2018-03-27 at 17:19 at 380MeV 0.6-mm fuzz
file15 = dir_data_hydra + 'tlm_packets_2018_086_17_19_56'
surf15 = dir_data_surf  + 'SURF_032718_211956.txt'

; CENTER SPS Y fine scan on 2018-03-27 at 17:34 at 380MeV 0.6-mm fuzz
file16 = dir_data_hydra + 'tlm_packets_2018_086_17_34_00'
surf16 = dir_data_surf  + 'SURF_032718_213410.txt'

; CENTER SPS Y fine scan on 2018-03-27 at 18:08 at 380MeV 0.6-mm fuzz with CHANGE in BL-2 Slit Height
file17 = dir_data_hydra + 'tlm_packets_2018_086_18_08_42'
surf17 = dir_data_surf  + 'SURF_032718_220852.txt'

; CENTER SPS Y fine scan on 2018-03-27 at 18:19 at 380MeV 0.6-mm fuzz with CHANGE in BL-2 Slit Height
;  wider scan over Y to cover both edges
file18 = dir_data_hydra + 'tlm_packets_2018_086_18_19_57'
surf18 = dir_data_surf  + 'SURF_032718_222005.txt'

; Centerpoint on SPS on 2018-03-28 at 09:13 at 380MeV 0.6-mm fuzz
file19 = dir_data_hydra + 'tlm_packets_2018_087_09_13_47'
surf19 = dir_data_surf  + 'SURF_032818_131402.txt'

; Centerpoint on XRS-A2 on 2018-03-28 at 10:11 at 380MeV full fuzz (User mistake)
file20 = dir_data_hydra + 'tlm_packets_2018_087_10_11_35'
surf20 = dir_data_surf  + 'SURF_032818_141203.txt'

; Centerpoint on XRS-A1 on 2018-03-28 at 10:23 at 380MeV no fuzz
file21 = dir_data_hydra + 'tlm_packets_2018_087_10_23_49'
surf21 = dir_data_surf  + 'SURF_032818_142441.txt'

; Centerpoint on XRS-B2 on 2018-03-28 at 10:41 at 380MeV no fuzz
file22 = dir_data_hydra + 'tlm_packets_2018_087_10_41_09'
surf22 = dir_data_surf  + 'SURF_032818_144114.txt'

; Centerpoint on XRS-B1 on 2018-03-28 at 10:56 at 380MeV no fuzz
file23 = dir_data_hydra + 'tlm_packets_2018_087_10_59_10'
surf23 = dir_data_surf  + 'SURF_032818_145918.txt'

; Centerpoint on X123 on 2018-03-28 at 11:25 at 380MeV no fuzz
file24 = dir_data_hydra + 'tlm_packets_2018_087_11_25_02'
surf24 = dir_data_surf  + 'SURF_032818_152503.txt'

; Y beam peak on X123 on 2018-03-28 at 11:33 at 380 MeV no fuzz
file25 = dir_data_hydra + 'tlm_packets_2018_087_11_33_55'
surf25 = dir_data_surf  + 'SURF_032818_153355.txt'

; Y beam peak on X123 on 2018-03-28 at 12:01 at 408 MeV no fuzz - RS422 PC connection went away - bad scan
file26 = dir_data_hydra + 'tlm_packets_2018_087_12_01_30'
surf26 = dir_data_surf  + 'SURF_032818_160133.txt'

; Y beam peak on X123 on 2018-03-28 at 12:18 at 408 MeV no fuzz - repeated
file27 = dir_data_hydra + 'tlm_packets_2018_087_12_18_23'
surf27 = dir_data_surf  + 'SURF_032818_161914.txt'

; Centerpoint on PicoSIM on 2018-03-28 at 12:56 at 285 MeV 0.6mm fuzz
file28 = dir_data_hydra + 'tlm_packets_2018_087_12_56_41'
surf28 = dir_data_surf  + 'SURF_032818_165644.txt'

; Still need to do analysis
; SPS alpha scan on 2018-03-28 at 13:26 at 285 MeV 0.6mm fuzz
file29 = dir_data_hydra + 'tlm_packets_2018_087_13_26_55'
surf29 = dir_data_surf  + 'SURF_032818_172656.txt'

; Still need to do analysis
; SPS beta scan on 2018-03-28 at 13:36 at 285 MeV 0.6mm fuzz
file30 = dir_data_hydra + 'tlm_packets_2018_087_13_36_46'
surf30 = dir_data_surf  + 'SURF_032818_173653.txt'

; Still need to do analysis
; Y beam peak on SPS on 2018-03-28 at 14:01 at 380 0.6mm fuzz
file31 = dir_data_hydra + 'tlm_packets_2018_087_14_01_01'
surf31 = dir_data_surf  + 'SURF_032818_180101.txt'

; Centerpoint on XRS A2 on 2018-03-28 at 14:19 at 380 MeV no fuzz
file32 = dir_data_hydra + 'tlm_packets_2018_087_14_19_56'
surf32 = dir_data_surf  + 'SURF_032818_181949.txt'

; Y beam peak on X123 on 2018-03-28 at 14:54 at 285 MeV no fuzz
file33 = dir_data_hydra + 'tlm_packets_2018_087_14_54_12'
surf33 = dir_data_surf  + 'SURF_032818_185416.txt'

; Centerpoint Multi-Energy on X123 on 2018-03-28 at 15:20 at 285 MeV no fuzz
file34 = dir_data_hydra + 'tlm_packets_2018_087_15_20_26'
surf34 = dir_data_surf  + 'SURF_032818_192020.txt'

; Y beam peak on X123 on 2018-03-28 at 15:38 at 331 MeV no fuzz
file35 = dir_data_hydra + 'tlm_packets_2018_087_15_38_02'
surf35 = dir_data_surf  + 'SURF_032818_193759.txt'

; Centerpoint Multi-Energy on X123 on 2018-03-28 at 15:58 at 331 MeV no fuzz
file36 = dir_data_hydra + 'tlm_packets_2018_087_15_58_47'
surf36 = dir_data_surf  + 'SURF_032818_195829.txt'

; Centerpoint Multi-Energy on X123 on 2018-03-28 at 17:44 at 380 MeV no fuzz
file37 = dir_data_hydra + 'tlm_packets_2018_087_16_17_44'
surf37 = dir_data_surf  + 'SURF_032818_201745.txt'

; Centerpoint Multi-Energy on X123 on 2018-03-28 at 16:33 at 408 MeV no fuzz
file38 = dir_data_hydra + 'tlm_packets_2018_087_16_33_12'
surf38 = dir_data_surf  + 'SURF_032818_203322.txt'

; FOV on X123 on 2018-03-28 at 16:33 at 408 MeV no fuzz
file39 = dir_data_hydra + 'tlm_packets_2018_087_16_41_54'
surf39 = dir_data_surf  + 'SURF_032818_204152.txt'

; Linearity X123 calibration with peaking time of 1.2 microsec with 380 MeV beam
file40 = dir_data_hydra + 'tlm_packets_2018_087_18_22_54'
surf40 = dir_data_surf  + 'SURF_032818_222254.txt'

; Linearity X123 calibraiton with peaking time of 4.8 microsec with 380 MeV beam
file41 = dir_data_hydra + 'tlm_packets_2018_087_20_04_21'
surf41 = dir_data_surf  + 'SURF_032918_000458.txt'

; Check XRS-B2 Y center after breaking vacuum this morning to update flight software
file42 = dir_data_hydra + 'tlm_packets_2018_088_13_38_49'
surf42 = dir_data_surf  + 'SURF_032918_173839.txt'

; Y beam peak on X123 on 2018-03-29 at 14:15 at 416 MeV no fuzz
file43 = dir_data_hydra + 'tlm_packets_2018_088_14_14_53'
surf43 = dir_data_surf  + 'SURF_032918_181448.txt'

; Centerpoint X123 on 2018-03-29 at 14:30 at 416 MeV no fuzz (but with 4.8 microsec peaking time)
file44 = dir_data_hydra + 'tlm_packets_2018_088_14_30_13'
surf44 = dir_data_surf  + 'SURF_032918_183011.txt'

; Linearity X123 calibraiton with peaking time of 2.4 microsec with 408 MeV beam
file45 = dir_data_hydra + 'tlm_packets_2018_088_15_10_40'
surf45 = dir_data_surf  + 'SURF_032918_191042.txt'

; Linearity X123 calibraiton with peaking time of 1.2 microsec with 408 MeV beam - REPEATED
file46 = dir_data_hydra + 'tlm_packets_2018_088_16_31_45'
surf46 = dir_data_surf  + 'SURF_032918_203147.txt'

; Centerpoint SPS on 2018-03-29 at at 380 MeV 0.6 mm fuzz
file47 = dir_data_hydra + 'tlm_packets_2018_088_18_01_39'
surf47 = dir_data_surf  + 'SURF_032918_220139.txt'

; Centerpoint SPS on 2018-03-29 at 380 MeV 0.6 mm fuzz
file47 = dir_data_hydra + 'tlm_packets_2018_088_18_01_39'
surf47 = dir_data_surf  + 'SURF_032918_220139.txt'

; Centerpoint PicoSIM on 2018-03-29 at 285 MeV 0.6 mm fuzz
file48 = dir_data_hydra + 'tlm_packets_2018_088_17_49_23'
surf48 = dir_data_surf  + 'SURF_032918_214918.txt'

; Centerpoint XRS-A2 on 2018-03-29 at 380 MeV no fuzz
file49 = dir_data_hydra + 'tlm_packets_2018_088_18_24_26'
surf49 = dir_data_surf  + 'SURF_032918_222428.txt'

; Centerpoint XRS-A1 on 2018-03-29 at 380 MeV no fuzz
file50 = dir_data_hydra + 'tlm_packets_2018_088_18_35_36'
surf50 = dir_data_surf  + 'SURF_032918_223548.txt'

; Centerpoint XRS-B2 on 2018-03-29 at 380 MeV no fuzz
file51 = dir_data_hydra + 'tlm_packets_2018_088_18_52_31'
surf51 = dir_data_surf  + 'SURF_032918_225229.txt'

; Centerpoint XRS-B1 on 2018-03-29 at 380 MeV no fuzz
file52 = dir_data_hydra + 'tlm_packets_2018_088_18_59_31'
surf52 = dir_data_surf  + 'SURF_032918_225927.txt'

; Centerpoint X123 on 2018-03-29 at 380 MeV no fuzz
file53 = dir_data_hydra + 'tlm_packets_2018_088_19_07_28'
surf53 = dir_data_surf  + 'SURF_032918_230717.txt'

; Centerpoint Multi-Energy on X123 on 2018-03-28 at 331 MeV no fuzz
file54 = dir_data_hydra + 'tlm_packets_2018_088_19_24_47'
surf54 = dir_data_surf  + 'SURF_032918_232443.txt'

; Centerpoint Multi-Energy on X123 on 2018-03-28 at 408 MeV no fuzz
file55 = dir_data_hydra + 'tlm_packets_2018_088_19_54_05'
surf55 = dir_data_surf  + 'SURF_032918_235430.txt'

; Y scan on X123 for 416 MeV with no fuzz on 2018-03-30
file56 = dir_data_hydra + 'tlm_packets_2018_089_08_35_30'
surf56 = dir_data_surf  + 'SURF_033018_123535.txt'

; Multi-energy of X123 for 416 MeV with no fuzz on 2018-03-30
file57 = dir_data_hydra + 'tlm_packets_2018_089_08_46_42'
surf57 = dir_data_surf  + 'SURF_033018_124640.txt'


end
