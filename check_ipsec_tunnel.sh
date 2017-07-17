#!/bin/bash
# Hack script that needs some touching up to check if a IPSEC tunnel is up and running, i do make 6 calls which is excessive as i could probably use grep to get it down to 3
# -i is the ip of the remote end of the tunnel, -a is the asa address of your end which you use to connect to the other side, -c is the community string
# I have this on my ASAs to allow connection "snmp-server host inside 192.168.50.11 cisco version 2c", 192.168.50.11 makes the snmp query using string cisco
# This script was tested on ASA 5520 with a CPN Plus license
# example usage: bash check_ipsec_tunnel.sh -a "192.168.50.1" -i "192.168.42.1" -c "cisco" 
#        Result: Success: 192.168.42.1 is working, Phase 1: UP, Phase 2: UP
    

while getopts :i:a:c:h option; do
 case "${option}" in
        i) ip=${OPTARG}
           if [[ $ip == "" ]]; then
              echo You must provide the remote IP to monitor; exit 3
           fi
           ;;
        a) host=${OPTARG}
           if [[ $host == "" ]]; then
              echo You must provide the cisco ASA to query for; exit 3
           fi
           ;;
        c) comm=${OPTARG}
           if [[ $comm == "" ]]; then
              echo You must provide the snmp community string to query with; exit 3
           fi
           ;;
        h) echo USAGE: check_linux_int.sh -i Included INTERFACE -e excluded Interface -s SPEED -m MTU; exit 1; ;;
        \?) echo Invalid Parameter used. USAGE: -i Remote tunnel IP  -a cisco asa to query for information -c snmp community; exit 3; ;;
        :) echo "Option -$OPTARG requires an argument"; exit 1 
 esac
done

shift $((OPTIND-1))

function getData() 
{
        tempresult=$(snmpwalk -v 2c -c $comm $host "$1$2" | awk '{ printf $4 " " $5 " " $6 " " $7}' | sed 's/\"//g')
        echo $tempresult
}

cike=1.3.6.1.4.1.9.9.171.1.2.3.1.7
nodeIPaddrPhase1=1.3.6.1.4.1.9.9.171.1.2.3.1.7.
nodeTunStatusPhase1=1.3.6.1.4.1.9.9.171.1.2.3.1.35.
nodeIDphase2=1.3.6.1.4.1.9.9.171.1.3.2.1.2
nodeTunStatusPhase2=1.3.6.1.4.1.9.9.171.1.3.2.1.51.

phase_1_id=$(snmpwalk -v 2c -c $comm $host $cike 2> tmp | grep $ip | awk '{printf $1 "\n"}' | sed 's/SNMPv2\-SMI\:\:enterprises\.9\.9\.171\.1\.2\.3\.1\.//g' | sed 's/^.*\.//g' | sort | uniq )

if [[ $(cat tmp) =~ ^Timeout ]]; then
        echo "There was a problem retreiving SNMP data from $ip using $comm, please check the community, IP address and that the ASA is allowing you to connect from this address"
        rm tmp
        exit 1
elif [[ $phase_1_id == "" ]]; then
        echo There are currently no IPSEC tunnels up and running at this moment for $ip
        rm tmp
        exit 2
fi

ip_phase_1=$(getData $nodeIPaddrPhase1 $phase_1_id)
status_phase_1=$(getData $nodeTunStatusPhase1 $phase_1_id)
phase_2_id=$(snmpwalk -v 2c -c $comm $host $nodeIDphase2 | grep $phase_1_id | awk '{printf $1}' | sed 's/SNMPv2\-SMI\:\:enterprises\.9\.9\.171\.1\.3\.2\.1\.2\.//g')

if [[ $phase_2_id == "" ]]; then
        status_phase_2="0"
else
        status_phase_2=$(getData $nodeTunStatusPhase2 $phase_2_id)
fi

if [[ $status_phase_2  == "1" ]] && [[ $status_phase_1 == "1" ]]; then
        echo "Success: $ip_phase_1 is working, Phase 1: UP, Phase 2: UP"
        rm tmp
        exit 2
else
        echo "Error: $ip_phase_1 has an error condition please investigate"
        rm tmp
        exit 2
fi
