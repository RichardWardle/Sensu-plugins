# Date: 11/07/2017
# Author: Richard Wardle
# Purpose: Checks your DFSR replication queues from one script for every connection on 2012 SYSTEMS ONLY
# Paramters: $domainname (string, optional, defaults to your current domain name), $groupname (string, optional, defaults to all groupnames using '*'), $folder (string, optional, defaults to all folders), $backlogwarn (int, optional, defaults to 500, returns state 2 if we have more than this files between a connection site) , $backlogcrit (int, optional, defaults to 500, returns state 2 if we have more than this files for one connection),output (bool, optional, if you want to see outputs that are less than your warning value, useful if you want to show all links. This can get quite large if you have many member servers in a full mesh topology)
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-dfsr-backlog": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-dfsr-backlog.ps1",
#      "subscribers": [
#        "windows-monitor"
#      ],
#      "interval": 60,
#      "standalone": false,
#      "contact": "Network/Systems Administrators",
#      "Description": "Checks the DFSR replication backlog, continued high levels could mean network or server performance issues"
#    }
#  }
#}
# Example 1: Check all groupnames in default domain and supress all OK outputs except for the final validation. If there are any errors it will show them also using warning 1000 and critical 2000
# check-windows-dfsr-backlog.ps1 -output $False -backlogwarn 1000 -backlogcrit 2000
# Output below shows no warnings or errors and only the basic output
# PS ./check-windows-dfsr-backlog.ps1 -output $false -backlogwarn 1000 -backlogcrit 2000
#    Success: No backlogs for '*' are greater than your specified warning or critical values
# Example 2: Shows the same as Eample 1 but shows us the full output. You can see we show the source server, its domain site then the same again for the destination server. We then show the backlog appropriatley, noting we have two dfsr groupnames. THIS IS A FULL MESH TOPOLOGY
# check-windows-dfsr-backlog.ps1 -backlogwarn 1000 -backlogcrit 2000
# ./check-windows-dfsr-backlog.ps1 -backlogwarn 1000 -backlogcrit 2000
#    Success: MEMBER2 (Headquarters) to MEMBER1 (Headquarters): 0 items for 'example.com\shares\hr'
#    Success: MEMBER1 (Headquarters) to MEMBER2 (Headquarters): 0 items for 'example.com\shares\hr'
#    Success: MEMBER1 (Headquarters) to MEMBER3 (Headquarters): 0 items for 'example.com\shares\hr'
#    Success: MEMBER3 (Headquarters) to MEMBER1 (Headquarters): 0 items for 'example.com\shares\hr'
#    Success: MEMBER2 (Headquarters) to MEMBER3 (Headquarters): 0 items for 'example.com\shares\hr'
#    Success: MEMBER3 (Headquarters) to MEMBER2 (Headquarters): 0 items for 'example.com\shares\hr'
#    Success: MEMBER1 (Headquarters) to MEMBER2 (Headquarters): 0 items for 'example.com\shares\scripts'
#    Success: MEMBER2 (Headquarters) to MEMBER1 (Headquarters): 0 items for 'example.com\shares\scripts'
#    Success: MEMBER1 (Headquarters) to MEMBER3 (Headquarters): 0 items for 'example.com\shares\scripts'
#    Success: MEMBER3 (Headquarters) to MEMBER1 (Headquarters): 0 items for 'example.com\shares\scripts'
# Example 3: Checks groupname example.com\shares\scripts (the namespace for me here is example.com\shares and the folder being replicated is HR), i will show errors or warnings only. THIS IS A HUB AND SPOKE MESH
# check-windows-external-ip.ps1 -ip 6.6.6.6 -timeout 10
# Output: We can see Member 1 is the hub and member2/3 is the spokes. There is backlog sending from member1 out to the other sites
# check-windows-dfsr-backlog.ps1 -groupname example.com\\shares\\scripts
#    Critical: MEMBER1 (Headquarters) to MEMBER2 (Headquarters): 2664 items for 'example.com\shares\scripts'
#    Success: MEMBER2 (Headquarters) to MEMBER1 (Headquarters): 0 items for 'example.com\shares\scripts'
#    Critical: MEMBER1 (Headquarters) to MEMBER3 (Headquarters): 2403 items for 'example.com\shares\scripts'
#    Success: MEMBER3 (Headquarters) to MEMBER1 (Headquarters): 0 items for 'example.com\shares\scripts'

Param(
  [Parameter(Mandatory=$false)]
   [string]$domainname = "$env:USERDNSDOMAIN",

     [Parameter(Mandatory=$false)]
   [string]$groupname = '*',

  [Parameter(Mandatory=$false)]
   [string]$folder = "*",

  [Parameter(Mandatory=$false)]
   [int]$backlogwarn = 200,

     [Parameter(Mandatory=$false)]
   [int]$backlogcrit = 500,

   [Parameter(Mandatory=$false)]
   [bool]$output = $True
)

[int]$errorCounter = 0
[int]$warningCounter = 0
[int]$successCounter = 0

try 
{
    #Gets all the different connection profiles for specified groupname
    $results = Get-Dfsrconnection -DomainName $domainname -GroupName $groupname | select SourceComputerName, DestinationComputerName, Enabled, State, GroupName
    if (!$results) { Write-Output "Warning: I could not find any information for '$groupname' in '$domainname'"; Exit 3}

    foreach ($link in $results)
    {
        try
        {
            $checkbacklog = (Get-DFSRBacklog -FolderName "$folder" -SourceComputerName $link.SourceComputerName -destinationComputerName $link.DestinationComputerName -groupname $link.GroupName -ErrorAction silentlycontinue -verbose 4>&1)
            if (!$($checkbacklog))
            {
                Write-Output "Error: $($link.SourceComputerName) ($($srcSite[0].site)) to $($link.DestinationComputerName) ($($dstSite[0].site)): Returned no results at all for '$($link.GroupName)', please check nodes and investigate"
                $errorCounter++
            }
            else
            {
                $srcSite = Get-DfsrMember | where ComputerName -eq $link.SourceComputerName
                $dstSite = Get-DfsrMember | where ComputerName -eq $link.DestinationComputerName

                if ( $checkbacklog -like "No backlog for the replicated*")
                {
                    $successCounter++
                    if ($output) { Write-Output "Success: $($link.SourceComputerName) ($($srcSite[0].site)) to $($link.DestinationComputerName) ($($dstSite[0].site)): 0 items for '$($link.GroupName)'" }
                } 
                else
                {
                    [int]$files = ($checkbacklog.Message.Split(':')[2]).trim()
                    

                    if ( $files -gt $backlogcrit)
                    {
                        Write-Output "Critical: $($link.SourceComputerName) ($($srcSite[0].site)) to $($link.DestinationComputerName) ($($dstSite[0].site)): $($files) items for '$($link.GroupName)'"
                        $errorCounter++
                    }
                    elseif ( $files -gt $backlogwarn)
                    {
                        Write-Output "Warning: $($link.SourceComputerName) ($($srcSite[0].site)) to $($link.DestinationComputerName) ($($dstSite[0].site)): $($files) items for '$($link.GroupName)'"
                        $warningCounter++
                    }
                    elseif (($output) -and ( $files -gt $backlogcrit) -and ( $files -gt $backlogwarn))
                    {
                        Write-Output "Success: $($link.SourceComputerName) ($($srcSite[0].site)) to $($link.DestinationComputerName) ($($dstSite[0].site)): $($files) items for '$($link.GroupName)'"
                        $successCounter++
                    }
                }
            }
        }
        catch
        {
            Write-Output "Run Error: $_.Exception.Message"
            Exit 3
        }
    }

    if ( $errorCounter -gt 0 ) { Exit 2}
    elseif ( $warningCounter -gt 0 ) { Exit 1}
    elseif ( $successCounter -gt 0) { if (!$output) { Write-Host "Success: No backlogs for '$groupname' are greater than your specified warning or critical values"}; Exit 0}
    else { Write-Output "Unknown Error - I should not have got to the end of this script as there were no errors, no warnings or successes"; Exit 3}
}
catch
{
    Write-host Run Error: $_.Exception.Message
    Exit 3
}
