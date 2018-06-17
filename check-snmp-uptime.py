#!/usr/bin/python
import easysnmp
import sys
import getopt

def check_number(func_opt, func_arg):
    try:
        float(func_arg)
    except ValueError:
        print("Warning: " + func_opt + " is not a number, you passed: " + func_arg)
        print_help()
        sys.exit(1)

def check_param(snmp_obj):
    if snmp_obj['snmp_hightime'] < snmp_obj['snmp_lowtime'] or snmp_obj['snmp_hightime'] == snmp_obj['snmp_lowtime']:
       print("Error: Hightime must be greater than lowtime")
       sys.exit(2)
    elif snmp_obj['snmp_timeout'] < 0 or snmp_obj['snmp_timeout'] == 0:
       print("Error: Timeout can not be less than 0 or equal to 0")
       sys.exit(2)
    elif snmp_obj['snmp_hightime'] == 0 or snmp_obj['snmp_hightime'] == 0:
       print("Error: Hightime or Lowtime can not be less than 0 or equal to 0")
       sys.exit(2)

def print_help():
    print("check-snmp-uptime.py -i <ip (192.168.1.1)> -C <community (public)> -L <lowtime (15 minutes)> -H <hightime ( 518400 minutes)> -t <timeout (5 seconds)> -P <port (161)>")

def main(argv):
    snmps = {}
    snmps['snmp_community'] = 'public'
    snmps['snmp_target'] = '192.168.1.1'
    snmps['snmp_port'] = 161
    snmps['snmp_ver'] = 2
    snmps['snmp_lowtime'] = 15
    snmps['snmp_hightime'] = 518400
    snmps['snmp_oid'] = '1.3.6.1.2.1.1.3'
    snmps['snmp_timeout'] = 5

    try:
      opts, args = getopt.getopt(argv,"i:C:L:H:t:P:", ['ip=', 'community=', 'lowtime=', 'hightime=', 'timeout=', 'port='])
    except getopt.GetoptError as e:
          print_help()
          print(str(e))
          sys.exit(2)
    for opt, arg in opts:
          if opt == '-h':
             print_help()
             sys.exit()
          elif opt in ("-i", "--ip"):
             snmps['snmp_target'] = arg
          elif opt in ("-C", "--community"):
             snmps['snmp_community'] = arg
          elif opt in ("-L", "--lowtime"):
             check_number(opt, arg)
             snmps['snmp_lowtime'] = int(arg)
          elif opt in ("-H", "--hightime"):
             check_number(opt, arg)
             snmps['snmp_hightime'] = int(arg)
          elif opt in ("-t", "--timeout"):
             check_number(opt, arg)
             snmps['snmp_timeout'] = int(arg)
          elif opt in ("-P", "--port"):
             check_number(opt, arg)
             snmps['snmp_port'] = int(arg)
    check_param(snmps)
    query_snmp(snmps)

def query_snmp(snmp_obj):
    try:
        exit_code = 2
        session = easysnmp.Session(hostname=snmp_obj['snmp_target'], community=snmp_obj['snmp_community'], version=snmp_obj['snmp_ver'], remote_port=snmp_obj['snmp_port'], timeout=snmp_obj['snmp_timeout'])
        system_items = session.walk(snmp_obj['snmp_oid'])
        for item in system_items:
            snmp_obj['uptime'] = int(item.value)/6000
            if snmp_obj['uptime'] <= snmp_obj['snmp_lowtime']:
                print("Error: The device has been rebooted since: " + str(snmp_obj['uptime']) + " which is less than: " + str(snmp_obj['snmp_lowtime']))
            elif snmp_obj['uptime'] >= snmp_obj['snmp_hightime']:
                print("Error: The device has not been rebooted since: " + str(snmp_obj['uptime']) + " which is greater than: " + str(snmp_obj['snmp_hightime']))
            else:
                exit_code = 0
                print("Success: The device uptime is: " + str(snmp_obj['uptime']) + " (" + str(int(item.value)/8640000) + " days)")
        sys.exit(exit_code)
    except easysnmp.exceptions.EasySNMPError as e:
        print("Warning: " + str(e))
    except Exception as e:
        print("Error: " + str(e))
    sys.exit(exit_code)

if __name__ == "__main__":
   main(sys.argv[1:])
