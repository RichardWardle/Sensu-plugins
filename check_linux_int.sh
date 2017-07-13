#!/bin/bash
# This is a hack check and isnt the greatest but it solves an immediate check i wanted to write
# This DOES not check the speed of master bonded or teamded interfaces but will check slaves. This will only check interfaces that are of state DEV "ip addr show type dev". It could be changed to look at another type
# This check can be used to ensure your UNIX based systems have interfaces that are up, full duplex and match the speed you expect (configurable)
# You can include only certain interfaces or by default it will choose all DEV type interfaces. You can then exclude certain ones if you want noting this is applied AFTER we have checked the interfaces we want to include
# if we had ens1, ens2, ens3 and we only wanted to include ens1,ens2 then we could do '-e ens3' or '-i ens -e ens3'
# I will eventually add in logic to allow you to specify multiple wildcard interfaces like my windows check

while getopts :i:e:s:h: option; do
 case "${option}" in
        i) incINT=${OPTARG};;
        e) excINT=${OPTARG};;
        s) SPEED=${OPTARG};;
        h) echo USAGE: check_linux_int.sh -i Included INTERFACE -e excluded Interface -s SPEED; exit 1; ;;
        \?) echo Invalid Parameter used. USAGE: check_linux_int.sh -i included_interfaces_string -e excluded_interfaces_string -s 10_100_1000_10000; exit 1; ;;
 esac
done

shift $((OPTIND-1))
error=0

function strip()
{
 temp=$(ethtool $1 2> /dev/null | grep -e "$2" | awk -F ": " '{ print $2}' | sed 's/Mb\/s//g' )
 echo "$temp"
}

if [[ $excINT == "" ]]; then
        excINT=gdsfdfgs
fi
if [[ $SPEED == "" ]]; then
        SPEED=1000
fi

interfaces=$(ip addr | grep -e "^.:" | awk -F ": " '{printf $2 "\n"}' | grep -e "$incINT" )

if [[ $interfaces == "" ]]; then
        echo No interfaces have been returned after searching through the network cards after inclusions
        exit 1
fi

for i in $interfaces; do
        if [[ $i == *"$excINT"* ]] || [[ $i == "lo" ]]; then
                # Do noting with the interface as we dont care about or the loopback - i should strip this out really further up
                ignore=ignored
        elif [[ $i == "$(ip addr show type team dev $i | grep -e "^.:" | awk -F ": " '{print $2}')"  ]]; then
                ignore=ignored
                # We can not pull duplex, speed settings for teams, please exclude them using the -e option
        else
                tempDuplex=$(strip $i Duplex)
                tempLink=$(strip $i Link)
                tempSpeed=$(strip $i Speed)
                if [ "$tempDuplex" != "Full" ] || [ "$tempLink" != "yes" ] || [ "$tempSpeed" != "$SPEED" ]; then
                        echo Interface $i Error: $tempLink/$tempSpeed/$tempDuplex EXPECTED yes/$SPEED/Full
                        let error++
                else
                        echo Interface $i OK: $tempLink/$tempSpeed/$tempDuplex
                fi
        fi
done

if [[ $error > 0 ]]; then
        exit 2
else
        exit 0
fi
