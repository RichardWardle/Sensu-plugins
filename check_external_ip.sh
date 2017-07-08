#!/bin/bash
# Date: 08/07/2017
# Author: Richard Wardle
# Purpose: Checks your external IP matches what you expect
# Paramters: -i IP (string, mandatory, IP address of what you believe your external IP is), -t timeout (int (seconds), optional, timeout for curl incase it takes to long), -h help option
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-linux-external-ip": {
#      "command": "check_external_ip.sh -i 55.55.55.55 -t 10",
#      "subscribers": [""],
#      "source": "HQ_Internet",
#      "interval": 300,
#      "standalone": true,
#      "contact": "Network Administrators",
#      "Description": "Checks your external IP matches what you expect
#    }
#  }
#}

#Set my default values of NO IP address and 10 second timeout
TIMEOUT=10
IP=NULL

#Handles the paramters i expect to be passed
while getopts :i:t:h option; do
 case "${option}" in
        i) IP=${OPTARG};;
        t) TIMEOUT=${OPTARG};;
        h) echo USAGE: check_external_ip.sh -h IPADDRESS -t TIMEOUT (in seconds); exit 1; ;;
        \?) echo Invalid Parameter used.USAGE: check_external_ip.sh -h IPADDRESS -t TIMEOUT; exit 1; ;;
 esac
done

shift $((OPTIND-1))

#Errors if i do not get an IP address from -i, it does not check to see if its a valid IP though
if [[ $IP == "NULL" ]]
then
        echo No IP Address Supplied
        exit 1
fi

#Calls the actual service to get my IP address, ignoring certificate errors incase we are redirected or something magical happens -k, and shows nothing to the screen with -s but shows us errors with -S. Pulls .ip value from json request and removes the quotations with -r
external=$(curl -ksS http://ifconfig.co/json -m $TIMEOUT | jq .ip -r)

#If our response matches then we are good, if we dont have anything in external then we didnt get anything back from our request, if its neither of these two then our IP addresses do not match
if [[ $external == $IP ]]
then
        echo Success: Your external IP $external matches $IP
        exit 0
elif [[ $external == "" ]]
then
        echo Warning: I had a problem connecting to the service please check curl error response above
        exit 1
else
        echo Error: Your external IP is $external and NOT $IP
        exit 2
fi
