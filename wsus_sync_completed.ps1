# Date: 18/08/2017
# Author: Richard Wardle
# Purpose: Checks that the WSUS has synchronized upstream succesfully, that it has recently and didn't take too long
# Paramters: update_time (not mandatory, int, this is the time in hours to alert if synchronization took longer), last_update (not mandatory, int, if the last time we synchornized in hours is greater than this we will alert)
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-wsus_sync": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\wsus_sync_completed.ps1 -update_time 1 -last_update 24",
#      "subscribers": [
#        "wsus-servers"
#      ],
#      "interval": 86400,
#      "standalone": false,
#      "contact": "Network Administrators",
#      "Description": "Checks that the WSUS has synchronized upstream succesfully, that it has recently and didn't take too long"
#    }
#  }
#}

Param(
   [Parameter(Mandatory=$False)]
   [ValidateScript({ try {$_ -match [int]$_} catch { Write-Output "$_ is not a valid integer"; Exit 3} })]
   [int]$update_time = "1",

   [Parameter(Mandatory=$false)]
   [ValidateScript({ try {$_ -match [int]$_} catch { Write-Output "$_ is not a valid integer"; Exit 3} })]
   [int]$last_update = "24"
)

$message = ""
$code = "0"

try
{
    $results = (Get-WsusServer).GetSubscription().GetLastSynchronizationInfo() | select Result,StartTime,EndTime,Error,ErrorTest
    $currentTime = get-date

    if ($results.result -eq "Succeeded")
    {
        if (($currentTime - $results.endtime).hours -gt $last_update)
        {
            $message = "Warning: The last update $($results.EndTime) was succesfully but it has been more than the specified $last_update hours since we last checked"
            $code = "1"
        }
        elseif (($results.endtime - $results.StartTime).hours -gt $update_time)
        {
            $message = "Warning: The last update $($results.EndTime) was succesfully but it took $($results.EndTime - $results.StartTime) hours which is longer than the specified $update_time hours"
            $code = "1"
        }
        else
        {
            $message = "Success: The last update $($results.EndTime) completed with no issues"
            $code = "0"
        }
        
        Write-Output "$message"
        Write-output "Result: $($results.Result)"
        Write-output "Start Time: $($results.StartTime)"
        Write-output "End Time: $($results.EndTime)"

        Exit $code
    }
    else
    {
        $code = "2"
        $message = "Failure: The last update was not a success"

        Write-Output "$message"
        Write-output "Result: $($results.Result)"
        Write-output "Start Time: $($results.StartTime)"
        Write-output "End Time: $($results.EndTime)"
        Write-output "Error Code: $($results.Error)"
        Write-output "Error Message: $($results.ErrorText)"
        Exit $code

    }
}
catch
{
    Write-Error "Run Error: $($_.Exception.message | format-list -force)"
    Exit 3
}
