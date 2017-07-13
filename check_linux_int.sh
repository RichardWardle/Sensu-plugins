#!/bin/bash
# This DOES not check the speed of master bonded or teamded interfaces but will check slaves. This will only check interfaces that are of state DEV "ip addr show type dev". It could be changed to look at another type
# This check can be used to ensure your UNIX based systems have interfaces that are up, full duplex and match the speed you expect and MTU (configurable)
# You can include only certain interfaces or by default it will choose all DEV type interfaces. You can then exclude certain ones if you want noting this is applied AFTER we have checked the interfaces we want to include
# if we had ens1, ens2, ens3 and we only wanted to include ens1,ens2 then we could do '-e ens3' or '-i ens -e ens3'
# I will eventually add in logic to allow you to specify multiple wildcard interfaces like my windows check

while getopts :i:e:s:m:h: option; do
 case "${option}" in
        i) incINT=${OPTARG};;
        e) excINT=${OPTARG};;
        s) SPEED=${OPTARG};;
        m) MTU=${OPTARG};;
        h) echo USAGE: check_linux_int.sh -i Included INTERFACE -e excluded Interface -s SPEED -m MTU; exit 1; ;;
        \?) echo Invalid Parameter used. USAGE: check_linux_int.sh -i included_interfaces_string -e excluded_interfaces_string -s 10_100_1000_10000 -m 1500; exit 1; ;;
 esac
done

shift $((OPTIND-1))
error=0

function strip()
{
 temp=$(cat /sys/class/net/$i/$2 2> /dev/null)
 echo "$temp"
}

#Sets my defaults if you do not put int anything, excINT set to somethingrandom that will always fail if you dont put anything in, speed is 1000 and MTU is 1500, incINT is regex to match everything
if [[ $incINT == "" ]]; then
        incINT=^.*
fi
if [[ $excINT == "" ]]; then
        excINT=gdsfdfgs
fi
if [[ $SPEED == "" ]]; then
        SPEED=1000
fi
if [[ $MTU == "" ]]; then
        MTU=1500
fi

#The below gets all the interfaces which are masters in teaming then we get all the interfaces and only include the ones we want, strip those we dont adn remove loopback/team/bonded
teamMasters=$(ip addr show type team | grep -e "^.: " | awk -F ": " '{print $2}')
if [[ $teamMasters == "" ]]; then teamMasters=efsdfaefawe; fi
interfaces=$(ls -1 /sys/class/net/ | grep -e "$incINT" | grep -v "$excINT" | grep -v "lo" |  grep -v "$teamMasters")

#If we are empty then we should exit with WARNING  as we have no interfaces matching our criteria or maybe at all
if [[ $interfaces == "" ]]; then
        echo No interfaces have been returned after searching through the network cards after inclusions
        exit 1
fi

echo "Interface %ID%: Link up(yes) or down(no) / NIC Speed in Mbps / MTU of NIC / MAC Address of NIC"
for i in $interfaces; do
                tempDuplex=$(strip $i duplex)
                tempLink=$(strip $i operstate)
                tempSpeed=$(strip $i speed)
                tempMTU=$(strip $i mtu)
                tempMAC=$(strip $i address)
                if [ "$tempDuplex" != "full" ] || [ "$tempLink" != "up" ] || [ "$tempSpeed" != "$SPEED" ] || [ "$tempMTU" != "$MTU" ]; then
                        echo Interface $i Error: $tempLink/$tempSpeed/$tempDuplex/$tempMTU/$tempMAC EXPECTED yes/$SPEED/Full/$MTU/$tempMAC
                        let error++
                else
                        echo Interface $i OK: $tempLink/$tempSpeed/$tempDuplex/$tempMAC
                fi
done

#This checks to see if we have had an error and if we had exit with CRITICAL else with OK
if [[ $error > 0 ]]; then
        exit 2
else
        exit 0
fi
