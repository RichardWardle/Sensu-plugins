# Sensu-plugins
Repository of my sensu plugins created or modified, please take or modify as you want! They can be used for any other system such as nagios/zabbix that utilize the standard 0,1,2,3 exit codes

# Check Descriptions

### check-windows-certificate-validity.ps1 
This is to check the windows certificates in a specified store in windows. You can use this for certificates that you may not be able to curl or query for. Can exclude certificates and warn or give a critical alert with specified thresholds. This should be run individually on server you want to check

### check-windows-connected-users.ps1 
Checks who is logged in and lets you know (inc who has console) you can use this to alert if too many people are logged into a server or if no one is logged in (this is useful if you only expect one user to be logged in as console and other users may cause problems). Has the ability to check remote server if required but I use it and check each server individually

### check-windows-dfsr-backlog.ps1 
Checks the backlogs for DFSR shares between different different members. You can alert for warnings or critical if you breach a threshold. Will tell you the server and the site its located into for each DFSR replication group for clarity. You must run this with a service that has admin privs given get-dfsrbacklog requires it. The server running this needs network access to call all the other DFSR members

### check-windows-dhcp-scopes.ps1
Checks your DHCP scopes to ensure you havent used up all your IP addresses. Alert with warning or critical above certain thresholds. You can target remote servers if need be or run it locally on a server. Account running this must have permission to query get-dhcpserverv4scopestatistics

### check-windows-external-ip.ps1
Checks your external IP against what you think it should be. Useful to know if you change IP randomly for some reason. This should be run at an interval rate that is high so http://ifconfig.co do not rate limit and cause the script to error 

### check-windows-file-details.ps1
Checks you have X amount of files, they are > a specified size, in a specified directory (including sub dirs). You can include only specified files and then exclude even more or only exclude files you specify. This is important if you always expect certain files to be in a folder and above a size but dont care WHEN they were last updated

### check-windows-file-updated.ps1 
Similar to check-windows-file-details but will ensure that these files have updated AFTER a certain specified in minutes. This is useful if you expect certain files to always be there but also to have updated after a certain time. I have jobs that download every day after a certain time, if they dont then we need to investigate why. Read in the notes about when you may have positive negatives and how they can be overcome with the logic i implemented

### check-windows-int-specs.ps1 
Checks that the duplex, speed, state of required NICS are up and at the speed you expect them to be. Errors if they are not

### check_account_locked_missing.ps1 
Checks that specified windows accounts exsist, error that they are missing if not. It will also ensure they are not locked out. I use this for monitoring specific service accounts or core accounts people use such as CEO's or EA's so we can adress them

### check_external_ip.sh 
This is the same as check-windows-external-ip.ps1 but for a linux end node

### check_ipsec_tunnel.sh 
Checks that an IPSEC tunnel is up on an ASA 5520 (may work on others but not tested), error if not so you can look into why this is the case

### check_linux_int.sh
Same as check-windows-int-specs.ps1 but will also check the MTU and provide the MAC address

### check_linux_yum_packages.sh
Simple check that looks to see if you have any packages requiring and update from your repositories. I would use this with an upstream package management solution you control given it could error everyday if you are just looking at the main solutions. I would not reccomend using remediation to automatically install the updates given it could break dependencies unless you have a process in place that ensures this doesnt happen e.g. testing, specified downtime.

### check-windows-cluster-disk-size.ps1
Checks all disks as per your windows cluster against specific thresholds. This is similar to any standard disk check but specifically looks up the clusters and then the cluster resources you have. We then make a call to WMI to get the relevant information. Get-volume could have worked but it seemed that you had to look up where the disk was potentially owned (this was the case for my quorom disk and while possible was more work than nessecary for this immediate check)
