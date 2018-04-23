import sys

import csv
import re

import configparser
import io
import pass_config

import jd_utc_time


def main(script):
    now_jd = jd_utc_time.now_in_jd()
    target_time = 2457847.497488426 + jd_utc_time.secs_to_jd(120)
    diff = now_jd - target_time
    print(diff)




    # array = []
    # add_element(array)
    # print(array)

# def add_element(array):
    # array.append(10)

    # cfg = pass_config.load_config('pass_config.ini')
    # print(cfg.email_list_info)
    # print(cfg.email_list_full)
    # print(cfg.do_send_analysis_email)

    # config = configparser.ConfigParser()
    # config.read('pass_config.ini')

    # section_list = config.sections()
    # print(section_list[0])

    # for section in section_list:
        # for key in config[section]:
            # print(key, " = ", config[section][key])

    # print(config['computer_specific']['do_update_satpc_tle'])
    # if(int(config['computer_specific']['do_update_satpc_tle']) == 0):
        # print("THIS WORKS!")





# def main(script):
    # file = open('README.txt','r')
    # lines = file.readlines()
    # for i in range(0,len(lines)):
        # m = re.search(r"(?<=\\)\w+", lines[i])
        # print(m.group(0))


# def main(script):
    # with open('eggs.csv', 'w',newline='') as csvfile:
        # spamwriter = csv.writer(csvfile, delimiter=',',
                                # quotechar='|', quoting=csv.QUOTE_MINIMAL)
        # spamwriter.writerow(['Spam'] * 5 + ['Baked Beans'])
        # spamwriter.writerow(['Spam', 'Lovely Spam', 'Wonderful Spam'])

# def main(script):
    # print("in main")
    # (a,b) = return2vals()
    # print(a)
    # print(b)

# def return2vals():
    # return("string",["f","fdsf"])

# import re

# emails = [line for line in open('minxss_pass_automation_error_email.txt')]

# emails = [email for email in emails if re.match(".*@.*\.[^\.]+\n",email) != None]

# emails = [email.rstrip('\n') for email in emails]
# print(emails[0])
# print(emails[1])
# print(len(emails))

# toaddrs_err = ['Rick.Kohnert@lasp.colorado.edu', 'jmason86@gmail.com', 'Tom.Woods@lasp.colorado.edu', 'amir@boulder.swri.edu','colden.rouleau@colorado.edu']

# print(toaddrs_err)
# print(emails)


if __name__ == '__main__':
    main(*sys.argv)