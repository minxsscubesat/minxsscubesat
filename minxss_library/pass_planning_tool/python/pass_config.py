import configparser
import sys
import os


class GenericConfig:

    def __init__(self, ini_filename):
        config = configparser.ConfigParser()
        # TODO: Add better error handler (need to pass actual error into the "except" clause)
        print('Reading configuration file: {}/{}'.format(os.getcwd(), ini_filename))
        config.read(ini_filename)

        # section_list = config.sections()

        # TODO: Add error handling for invalid types and such (check for things that must be zero or 1)

        # [overview]
        self.station_name = config['overview']['station_name']

        # [satellite_list]
        self.sat_ini_files = []
        for satellite in config['satellite_list']:
            self.sat_ini_files.append(config['satellite_list'][satellite])

        # [email_list]
        self.email_list = []
        try:
            for email in config['email_list']:
                self.email_list.append(config['email_list'][email])
        except:
            print("ERROR:", ini_filename, "lacks the section '[email_list]'. This sections must exist, even if empty!")
            self.error_handle()

        # [computer_config]
        self.use_satpc = config['computer_config']['use_satpc']
        
        # [email_config]
        self.email_server = config['email_config']['email_server']
        self.email_username = config['email_config']['email_username']
        self.email_password = config['email_config']['email_password']

        # [pass_config]
        self.setup_minutes_before_pass = int(config['pass_config']['setup_minutes_before_pass'])
        self.buffer_seconds_after_pass_end = float(config['pass_config']['buffer_seconds_after_pass_end'])
        self.buffer_seconds_transition_high_priority = float(config['pass_config']['buffer_seconds_transition_high_priority'])

        # [testing_only]
        self.disable_restart_programs = int(config['testing_only']['disable_restart_programs'])
        self.enable_rapidfire_test = int(config['testing_only']['enable_rapidfire_test'])

        # [directories]
        self.idl_tle_dir = config['directories']['tle_dir']
        if self.use_satpc == 1: 
            self.satpc_dir = config['directories']['satpc_dir']
            self.satpc_exe_name = config['directories']['satpc_exe_name']
            self.satpc_server_exe_name = config['directories']['satpc_server_exe_name']
            self.satpc_tle_dir = config['directories']['satpc_tle_dir']
        else: 
            self.satpc_dir = ''
            self.satpc_exe_name = ''
            self.satpc_server_exe_name = ''
            self.satpc_tle_dir = ''

        # [behavior]
        if self.use_satpc == 1:
            self.do_update_satpc_tle = int(config['behavior']['do_update_satpc_tle'])
        else:
            self.do_update_satpc_tle = 0

        self.error_check()

    @staticmethod
    def error_handle():
        sys.exit()

    def error_check(self):
        iserr = 0
        # check a couple of file paths
        if not(os.path.exists(self.idl_tle_dir)):
            print("\r\nERROR: Initial configuration failed!")
            print("[Environment Variables] idl_tle_dir File path does not exist! Listed as: ")
            print(self.idl_tle_dir)
            print("Please update the environment variable 'TLE_dir' to point to the correct location\r\n")
            iserr = 1
        
        if self.use_satpc == 1:
            if not(os.path.exists(self.satpc_dir)):
                print("\r\nERROR: Initial configuration failed!")
                print("[pass_config.ini] satpc_dir File path does not exist! Listed as: ")
                print(self.satpc_dir)
                print("Please update the 'satpc_dir' item in pass_config.ini to point to the correct location\r\n")
                iserr = 1
    
            if not(os.path.exists(self.satpc_tle_dir)):
                print("\r\nERROR: Initial configuration failed!")
                print("[pass_config.ini] satpc_tle_dir File path does not exist! Listed as: ")
                print(self.satpc_tle_dir)
                print("Please update the 'satpc_tle_dir' item in pass_config.ini to point to the correct location\r\n")
                iserr = 1

        if iserr == 1:
            self.error_handle()


# inherits from generic_config so we can share error handling
class SatelliteConfig(GenericConfig):

    # loads info for the specific CubeSat ini file fed in
    def __init__(self, ini_filename):
        config = configparser.ConfigParser()
        # TODO: Add better error handler (need to pass actual error into the "except" clause)
        print('Reading configuration file: {}/{}'.format(os.getcwd(), ini_filename))
        config.read(ini_filename)

        # [satellite]
        self.sat_name = config['satellite']['sat_name']
        self.priority = int(config['satellite']['priority'])

        # [email_list_info] and [email_list_error_only]
        self.email_list_full = []
        self.email_list_info = []
        try:
            for email in config['email_list_info']:
                self.email_list_info.append(config['email_list_info'][email])

            self.email_list_full = self.email_list_info.copy()
            for email in config['email_list_error_only']:
                if config['email_list_error_only'][email] not in self.email_list_full:
                    self.email_list_full.append(config['email_list_error_only'][email])
        except:
            print("ERROR:", ini_filename, "lacks the section '[email_list_info]' or '[email_list_error_only]'. These sections must exist, even if empty")
            self.error_handle()

        # [email_config]
        self.do_send_analysis_email = int(config['email_config']['do_send_analysis_email'])
        self.do_send_prepass_email = int(config['email_config']['do_send_prepass_email'])
        self.elevation_to_expect_data = float(config['email_config']['elevation_to_expect_data'])
        self.min_expected_data = float(config['email_config']['min_expected_data'])

        # [directories]
        self.hydra_dir = config['directories']['hydra_dir']
        self.script_dir = config['directories']['script_dir']
        self.sdr_dir = config['directories']['sdr_dir']

        # [executables]
        self.hydra_exe_name = config['executables']['hydra_exe_name']
        self.sdr_script_starter_name = config['executables']['sdr_script_starter_name']

        # [behavior]
        self.do_monitor_hydra = int(config['behavior']['do_monitor_hydra'])
        self.do_run_hydra_scripts = int(config['behavior']['do_run_hydra_scripts'])
        self.do_monitor_sdr = int(config['behavior']['do_monitor_sdr'])
        self.do_run_pre_pass_script = int(config['behavior']['do_run_pre_pass_script'])

        self.error_check(ini_filename)

    def error_check(self, ini_filename):
        iserr = 0
        # check a couple of file paths
        if not(os.path.exists(self.hydra_dir)):
            print("\r\nERROR: Initial configuration failed!")
            print("[" + ini_filename + "] hydra_dir File path does not exist! Listed as: ")
            print(self.hydra_dir)
            print("Please update the 'hydra_dir' item in " + ini_filename + " to point to the correct location\r\n")
            iserr = 1

        if iserr==1:
            self.error_handle()
