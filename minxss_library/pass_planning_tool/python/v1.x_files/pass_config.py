import configparser
import io
import sys

class load_config():

    def __init__(self, ini_file_name):
        config = configparser.ConfigParser()
        #TODO: Add better error handler (need to pass actual error into the "except" clause)
        config.read(ini_file_name)

        #self.email_list_full
        #self.email_list_info

        section_list = config.sections()

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
            print("ERROR:", ini_file_name, "lacks the section '[email_list_info]' or '[email_list_error_only]'. These sections must exist, even if empty")
            self.error_handle()

        #TODO: Add error handling for invalid types and such (check for things that must be zero or 1)

        self.do_send_analysis_email = int(config['email_config']['do_send_analysis_email'])
        self.do_send_prepass_email = int(config['email_config']['do_send_prepass_email'])

        self.setup_minutes_before_pass = int(config['pass_config']['setup_minutes_before_pass'])
        self.minutes_sleep_after_pass_start = float(config['pass_config']['minutes_sleep_after_pass_start'])

        self.computer_name = config['computer_specific']['computer_name']
        self.do_update_satpc_tle = int(config['computer_specific']['do_update_satpc_tle'])
        self.do_monitor_hydra = int(config['computer_specific']['do_monitor_hydra'])
        self.do_run_hydra_scripts = int(config['computer_specific']['do_run_hydra_scripts'])

        self.disable_restart_programs = int(config['testing_only']['disable_restart_programs'])
        self.enable_rapidfire_test = int(config['testing_only']['enable_rapidfire_test'])
        self.is_jims_machine = int(config['testing_only']['is_jims_machine'])

    def error_handle(self):
        sys.exit()