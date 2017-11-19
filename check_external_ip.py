#!/bin/python

import requests
import sys
import getopt

def check_number(func_param):
    try:
        float(func_param)
        return True
    except ValueError:
        return False

def get_url(func_url,func_timeout):
    r = requests.get(func_url, timeout=float(func_timeout))
    return r

def check_ip(func_passed_ip,func_timeout,func_url):
    try:
        r = get_url(func_url,func_timeout)
        r.raise_for_status()
        actual_ip = r.json()['ip']

        if actual_ip == func_passed_ip:
            print("Success: Your external IP matches and is: "+actual_ip)
            sys.exit(0)
        else:
            print("Error: Your external IP is: "+actual_ip+" when you passed: "+func_passed_ip)
            sys.exit(2)

    except requests.exceptions.Timeout:
        print("Warning: I could not connect to: "+func_url)
        sys.exit(1)
    except requests.exceptions.RequestException as e:
        print(e)
        sys.exit(2)

def main(argv):
   passed_ip = ''
   timeout = '0.15'
   url="http://ifconfig.co/json"

   try:
      opts, args = getopt.getopt(argv,"hi:t:",["ifile=","ofile="])
   except getopt.GetoptError:
      print 'check_external_ip.py -i <ip> -t <timeout>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'check_external_ip.py -i <ip> -t <timeout>'
         sys.exit()
      elif opt in ("-i", "--ip"):
         passed_ip = arg
      elif opt in ("-t", "--timeout"):
         timeout = arg
         if not check_number(arg):
             print("Error: Timeout value is not a number, you passed: "+arg)
             print 'check_external_ip.py -i <ip> -t <timeout>'
             sys.exit(2)
   #call the function to check our URL
   check_ip(passed_ip,timeout,url)

if __name__ == "__main__":
   main(sys.argv[1:])
