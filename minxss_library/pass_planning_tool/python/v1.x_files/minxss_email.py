from minxss_time import now_in_jd
import smtplib
import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText
import os
import sys
import re

num_hours_between_emails = .5
enable_email = 0

#Send an email with the associated error text (or informational text).
#Also, only send every hour or so unless error message is different (see constant above)
class email(object):
    def __init__(self, cfg):
        #declare all error types in this format, so we can track when they occurred
        self.errNoPassTimes_jd = 0 #time, in JD, that a "NoPassTimes" error occured
        self.errPassAboutToOccur_jd = 0
        self.errNoPassScript_jd = 0
        self.errNoFile_jd = 0 #generic, couldn't find a file errors
        self.script_name = "unchanged, there is a code error"
        self.script_file_location = ""
        #populate email list with default values
        self.toaddrs_err = cfg.email_list_full
        self.toaddrs_noerr = cfg.email_list_info
        #config settings
        self.fromaddr = 'minxss.ops.WinD2791@gmail.com'

        self.elevation = -1
        self.length_minutes = -1
        self.sunlight = -1

    def __call__(self,texttype,computer_name):
        emailtext = None
        if(texttype == "NoPassTimes"):
            tdiff = now_in_jd() - self.errNoPassTimes_jd
            if(tdiff*24>num_hours_between_emails):
                self.errNoPassTimes_jd = now_in_jd()
                email_type = "critical_error"
                emailtext = "No future pass times detected! Perhaps the script that generates pass times has failed!"

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
                self.errNoPassScript_jd = now_in_jd()
                email_type = "critical_error"
                emailtext = "MinXSS Pass Automation could not find a file it expected to exist! Please debug!"

        if emailtext != None:
            print(emailtext)
            self.SendEmail(emailtext,email_type,computer_name,"","")

    def PassResults(self, results, computer_name):
        #construct the body of the email
        email_body = "MinXSS Pass completed.\r\n"
        email_body = email_body + "Elevation: " + str(round(self.elevation,2)) + " degrees\r\n"
        email_body = email_body + "Length: " + str(round(self.length_minutes,2)) + " minutes\r\n"
        email_body = email_body + "Was in Sun: " + str(self.sunlight) + "\r\n"
        email_body = email_body + "Script: " + self.script_name + "\r\n\r\n"

        if(len(results.errors_array)>0):
            email_type = "errors_during_pass"
            email_body = email_body + "ERRORS OCCURED!\r\n\r\nErrors from EventLog:\r\n"
            email_body = email_body + "============================================\r\n"
            for line in results.errors_array:
                email_body = email_body + line
            email_body = email_body + "============================================\r\n\r\n"
        else:
            email_type = "successful_pass"
            email_body = email_body + "PASS WAS SUCCESSFUL!\r\n\r\n"

        #email_body = email_body + "cmdTry and cmdSuccess prints:\r\n"
        #email_body = email_body + "============================================\r\n"
        #for line in results.cmdTrySucceed_arr:
        #    email_body = email_body + line
        #email_body = email_body + "============================================\r\n\r\n"

        email_body = email_body + "TLM filename: " + results.tlm_filename + "\r\n"
        email_body = email_body + "kB data downlinked: " + str(results.bytes_downlinked_data/1000)

        self.SendEmail(email_body, email_type, computer_name, results.eventlog_filepath, results.csv_filepath)
        print("pass info:")
        print(self.elevation)
        print(self.length_minutes)

    def StoreScriptName(self,script_name):
        self.script_name = script_name

    def StoreScriptLocation(self,script_file_location):
        self.script_file_location = script_file_location

    # Taken, in part, from: https://docs.python.org/3/library/email-examples.html#email-examples
    def SendEmail(self, email_body, email_type, computer_name, eventlog_filepath, csv_filepath):

        if(email_type == "critical_error" or email_type == "errors_during_pass"):
            iserror = 1
        else:
            iserror = 0

        #Create the subject
        now = datetime.datetime.now()
        datestring = str(now.year) + "." + str(now.month) + "." + str(now.day) + " " + str(now.hour) + ":" + str(now.minute) + ":" + str(now.second)
        if(email_type == "critical_error"):
            subject = "CRITICAL: MinXSS: Error at "
            toaddrs = self.toaddrs_err
        elif(email_type == "prepass_info"):
            subject = "MinXSS: Status update at "
            toaddrs = self.toaddrs_noerr
        elif(email_type == "errors_during_pass"):
            subject = "MinXSS: Pass Results: ERROR! at "
            toaddrs = self.toaddrs_err
        elif(email_type == "successful_pass"):
            subject = "MinXSS: Pass Results: Success! at "
            toaddrs = self.toaddrs_noerr
        else:
            subject = "MinXSS: Fatal code error! Contact developer. At "

        subject = subject + datestring + " (" + computer_name + ")"

        # Credentials
        username = 'minxss.ops.wind2791@gmail.com'
        password = 'minxssgroundstation'

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
                server = smtplib.SMTP('smtp.gmail.com:587')
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

