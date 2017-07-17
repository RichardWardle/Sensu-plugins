#!/bin/bash
# Checks your repositories and checks to see if any need updating, if they do it will flag a warning (1), if it cant check the status it will go critical (2)  else it will be a success (0)

holdfile=tmp_file

yum check-update -q >& $holdfile
yumexitcode="$?"

case $yumexitcode in
    100)
        echo "Warning: You have packages to update on this system"
        cat $holdfile | grep -v "^$" | awk '{printf $3 " repository \n"}' | sort | uniq -c
        rm -f tmp_file
        exit 1
        ;;
    0)
        echo "Success: There are no packages to update"
        rm -f tmp_file
        exit 0
        ;;
    *)
        echo "Critical: An unknown error happened when trying to get the results please investigate"
        rm -f tmp_file
        exit 2
        ;;
esac
