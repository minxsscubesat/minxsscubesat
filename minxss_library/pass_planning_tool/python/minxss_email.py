from jd_utc_time import now_in_jd
from jd_utc_time import jd_to_minutes
import smtplib
import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText
import os
import sys
import re

num_hours_between_emails = 2
enable_email = 1

#Send an email with the associated error text (or informational text).
#Also, only send every hour or so unless error message is different (see constant above)
class email(object):
    def __init__(self, emails_noerr, emails_err, sat_name, cfg):
        #declare all error types in this format, so we can track when they occurred
        self.errNoPassTimes_jd = 0 #time, in JD, that a "NoPassTimes" error occured
        self.errPassAboutToOccur_jd = 0
        self.errNoPassScript_jd = 0
        self.errNoFile_jd = 0 #generic, couldn't find a file errors
        self.script_name = "unchanged, there is a code error"
        self.script_file_location = ""
        #populate email list with default values
        self.toaddrs_err = emails_err
        self.toaddrs_noerr = emails_noerr
        #config settings
        self.fromaddr = cfg.email_username
        self.station_name = cfg.station_name
        self.sat_name = sat_name
        self.cfg = cfg

    def __call__(self,texttype):
        emailtext = None
        if(texttype == "NoPassTimes"):
            tdiff = now_in_jd() - self.errNoPassTimes_jd
            if(tdiff*24>num_hours_between_emails):
                self.errNoPassTimes_jd = now_in_jd()
                email_type = "critical_error"
                emailtext = "No future pass times detected! Perhaps the script that generates pass times has failed! Chicken little."

        if(texttype == "PassAboutToOccur"):
            tdiff = now_in_jd() - self.errPassAboutToOccur_jd
            if(tdiff*24>num_hours_between_emails):
                self.errPassAboutToOccur_jd = now_in_jd()
                email_type = "prepass_info"
                emailtext = "A Pass is about to occur! It will happen in <=15 minutes!"

        if(texttype == "NoPassScript"):
            tdiff = now_in_jd() - self.errNoPassScript_jd
            if(tdiff*24>num_hours_between_emails):
                self.errNoPassScript_jd = now_in_jd()
                email_type = "critical_error"
                emailtext = "No Pass Script available, or next file is not *.prc! Please fix before the pass or we'll run the default script!"

        if(texttype == "NoFile"):
            tdiff = now_in_jd() - self.errNoFile_jd
            if(tdiff*24>num_hours_between_emails):
                self.errNoFile_jd = now_in_jd()
                email_type = "critical_error"
                emailtext = "Pass Automation could not find a file it expected to exist! Please debug!"

        if emailtext != None:
            print(emailtext)
            self.SendEmail(emailtext,email_type,"","")

    def PassResults(self, results, info):
        #construct the body of the email
        email_body = "{0} Pass completed at station {1}.\r\n".format(info.sat_name, info.station_name)
        if(info.is_shortened == 1):
            newlength = jd_to_minutes(info.end_jd_adjusted) - jd_to_minutes(info.start_jd_adjusted)
            if(newlength < 0):
                newlength = 0
                email_body = "{0} Pass CANCELED at station {1}. It overlapped with a higher priority satellite.\r\n".format(info.sat_name, info.station_name)
            else:
                email_body = "SHORTENED " + email_body
        email_body = email_body + "Elevation: " + str(round(info.elevation,2)) + " degrees\r\n"
        if(info.is_shortened == 1):
            email_body = email_body + "Length: " + str(round(newlength,2)) + " minutes (shortened from " + str(round(info.length_minutes,2)) + " minutes)\r\n"
        else:
            email_body = email_body + "Length: " + str(round(info.length_minutes,2)) + " minutes\r\n"
        email_body = email_body + "kB data downlinked: " + str(results.bytes_downlinked_data/1000) + "\r\n"
        email_body = email_body + "Script: " + self.script_name + "\r\n\r\n"

        if(len(results.errors_array)>0):
            email_type = "errors_during_pass"
            email_body = email_body + "ERRORS OCCURED!\r\n\r\nErrors from EventLog:\r\n"
            email_body = email_body + "============================================\r\n"
            for line in results.errors_array:
                email_body = email_body + line
            email_body = email_body + "============================================\r\n\r\n"
        elif(results.bytes_downlinked_data == 0):
            email_type = "no_data"
            email_body = email_body + "Pass provided no data, but this was not unexpected given the max elevation.\r\n\r\n"
        else:
            email_type = "successful_pass"
            email_body = email_body + "PASS WAS SUCCESSFUL!\r\n\r\n"

        email_body = email_body + "Was in Sun: " + str(info.sunlight) + "\r\n"
        email_body = email_body + "TLM filename: " + results.tlm_filename + "\r\n"

        #email_body = email_body + "cmdTry and cmdSuccess prints:\r\n"
        #email_body = email_body + "============================================\r\n"
        #for line in results.cmdTrySucceed_arr:
        #    email_body = email_body + line
        #email_body = email_body + "============================================\r\n\r\n"

        self.SendEmail(email_body, email_type, results.eventlog_filepath, results.csv_filepath)

    def StoreScriptName(self,script_name):
        self.script_name = script_name

    def StoreScriptLocation(self,script_file_location):
        self.script_file_location = script_file_location

    # Taken, in part, from: https://docs.python.org/3/library/email-examples.html#email-examples
    def SendEmail(self, email_body, email_type, eventlog_filepath, csv_filepath):

        if(email_type == "critical_error" or email_type == "errors_during_pass"):
            iserror = 1
        else:
            iserror = 0

        #Create the subject
        now = datetime.datetime.now()
        datestring = str(now.year) + "." + str(now.month) + "." + str(now.day) + " " + str(now.hour) + ":" + str(now.minute) + ":" + str(now.second)
        if(email_type == "critical_error"):
            subject = "CRITICAL: {0}: Error at ".format(self.sat_name)
            toaddrs = self.toaddrs_err
        elif(email_type == "prepass_info"):
            subject = "{0}: Status update at ".format(self.sat_name)
            toaddrs = self.toaddrs_noerr
        elif(email_type == "errors_during_pass"):
            subject = "{0}: Pass Results: ERROR! at ".format(self.sat_name)
            toaddrs = self.toaddrs_err
        elif(email_type == "successful_pass"):
            subject = "{0}: Pass Results: Success! at ".format(self.sat_name)
            toaddrs = self.toaddrs_noerr
        elif(email_type == "no_data"):
            subject = "{0}: Pass Results: No Data Received at ".format(self.sat_name)
            toaddrs = self.toaddrs_noerr
        else:
            subject = "MinXSS: Fatal code error! Contact developer. At "
            toaddrs = self.toaddrs_err

        subject = subject + datestring + " (" + self.station_name + ")"

        # Credentials
        username = self.cfg.email_username #'minxss.ops.wind2791@gmail.com'
        password = self.cfg.email_password #'minxssgroundstation'

        #print(email_body)
        #print(toaddrs)

        #Only send if there are any recipients
        if(len(toaddrs)>0):
            #put everything into a message object
            COMMASPACE = ', '
            #msg = MIMEText(email_body)
            msg = MIMEMultipart()
            msg['Subject'] = subject
            msg['From'] = self.fromaddr
            msg['To'] = COMMASPACE.join(toaddrs)
            msg.attach(MIMEText(email_body))

            if(os.path.isfile(eventlog_filepath)):
                with open(eventlog_filepath, "rb") as file:
                    part = MIMEApplication(file.read(), Name=os.path.basename(eventlog_filepath))
                    part['Content-Disposition'] = 'attachment; filename="%s"' % os.path.basename(eventlog_filepath)
                    msg.attach(part)

            if(os.path.isfile(csv_filepath)):
                with open(csv_filepath, "rb") as file:
                    part = MIMEApplication(file.read(), Name=os.path.basename(csv_filepath))
                    part['Content-Disposition'] = 'attachment; filename="%s"' % os.path.basename(csv_filepath)
                    msg.attach(part)

            if(os.path.isfile(self.script_file_location)):
                with open(self.script_file_location, "rb") as file:
                    part = MIMEApplication(file.read(), Name=os.path.basename(self.script_file_location))
                    part['Content-Disposition'] = 'attachment; filename="%s"' % os.path.basename(self.script_file_location)
                    msg.attach(part)

            if(enable_email == 1):
                # The actual mail send
                server = smtplib.SMTP(self.cfg.email_server) #'smtp.gmail.com:587'
                server.starttls() #encryption enabled
                server.login(username,password)
                server.sendmail(self.fromaddr, toaddrs, msg.as_string())
                server.quit()
            else:
                print("Subject: " + subject)
                print("Body: ")
                print(email_body)
        else:
            print("ERROR: Tried to send email '",email_body,"', but no recipients were listed in the email config file!")

# for testing of this file only!!
def main(script):
    print("")
    print("")
    print("")
    print("*******************************")
    #email = email() #initialize
    thisemail = email()
    thisemail("NoPassTimes", "colden_laptop")
    print("------------------------------------")
    thisemail("PassAboutToOccur", "colden_laptop")
    #email.SendEmail("PassAboutToOccur", "colden_laptop")

    print("*******************************")
    print("")
    print("")
    print("")

if __name__ == '__main__':
    main(*sys.argv)

