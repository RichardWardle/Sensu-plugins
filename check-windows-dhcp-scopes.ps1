# Date: 16/07/2017
# Author: Richard Wardle
# Purpose: Checks all DHCP scopes on a server to ensure you are not going to run out of IP addresses
# Paramters: scope (string, should be the name of the Scope ID, you can only place one here, if you want to monitor 2 out of 5 of these you will have to run the check twice. The default is all scopes available), WarnThresh (int, throw a warning if the percentage in use is above this, default 80), critThresh (int, throw a critical if the percentage in use is above this, default 80)
# This should be run on a server that has DHCP installed, if you want it to be redundant use the roundrobin functionality and have your DHCP servers be a round robin member
# Have not tested if using the -Failover in my call would require any changes as i havent tested that setup
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-dhcp-scopes": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-dhcp-scopes.ps1",
#      "subscribers": [
#        "windows-dhcp-servers"
#      ],
#      "Interval": 60,
#      "standalone": false,
#      "contact": "Network System Administrators",
#      "Description": "Checks all DHCP scopes on a server to ensure you are not going to run out of IP addresses"
#    }
#  }
#}

Param(
     [Parameter(Mandatory=$False)]
   [string] $scope = '*',
     [Parameter(Mandatory=$False)]
   [int] $warnthresh = 80,
     [Parameter(Mandatory=$False)]
   [int] $critthresh = 90
)

[int]$warnCount=0
[int]$critCount=0
[int]$okCount=0

try
{
    $results= Get-DhcpServerv4ScopeStatistics -ErrorAction silentlycontinue -ErrorVariable output | where scopeid -like "$scope" -ErrorAction silentlycontinue -ErrorVariable output
    
    if ($results.count -eq 0) { Write-Output "Warning: We could not find any scopes configured for the selection, the scope was set as $($scope), the default is * which is ALL scopes on the server"; Exit 3}
    if (($critthresh -lt $warnthresh) -or ($critthresh -lt 0) -or ($warnthresh -lt 0)) { Write-Output "Warning: critthresh can not be lower than warnthresh or below 0, please resolve"; Exit 3}
    
    $results | add-member -name Status -type noteproperty -value ""

    foreach ($id in $results)
    {
        if ($id.PercentageInUse -gt $critthresh)
        {
            $id.Status = "CRITICAL"
            $critCount++
        }
        elseif ($id.PercentageInUse -gt $warnthresh)
        {
            $id.Status = "Warning"
            $warnCount++
        } 
        else
        {
            $id.Status = "OK"
            $okCount++
        }  
    }

    $results | select ScopeId, Status, Free, InUse, Reserved, Pending, PercentageInUse
    if ($critCount -gt 0) { Exit 2}
    elseif ($warnCount -gt 0) { Exit 1}
    elseif ($okCount -gt 0) { Exit 0 }
    else { Exit 3 }
}
catch
{
    Write-Output "An Error has occured please investigate using the below error message"
    Write-Output "Run Error: $($_.Exception.Message)"
    Exit 3
}
