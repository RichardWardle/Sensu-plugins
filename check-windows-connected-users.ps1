# Date: 13/07/2017
# Author: Richard Wardle
# Purpose: Checks your connected users and alerts based on amount of connected/not connected users etc
# Paramters: Server where you want to monitor and defaults to localhost. minConnected is the how many users you expect to be connected, it is 0 by default but if you always expect someone to be logged in e.g your applications run in console then change appropriatley
# activeCrit and activeWarn are the used to alert you when you have active sessions running and they are above those values. disconnectCrit and disconnectWarn are the used to alert you when you have Disc sessions running and they are above those values.. Crit exits with 2 and Warn exits with 1, if both error it will always display a CRIT error.
# We are parsing essentially the below output. The below has one user in Active and one in disconnected state. Run this command with SilentlyContinue as ErrorAction as I do not handle if there are NO USERS logged in given I can not pass the output directly into an object and hacked it to work the way i wanted with the internets help
# query user /server localhost
# USERNAME              SESSIONNAME        ID  STATE   IDLE TIME  LOGON TIME
# administrator         console             1  Active       1:45  12/07/2017 4:55 PM
# test                                      2  Disc         1:46  12/07/2017 6:36 PM
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-connected-users": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-connected-users.ps1 -ErrorAction SilentlyContinue",
#      "subscribers": [
#        "windows-monitor"
#      ],
#      "interval": 60,
#      "standalone": false,
#      "contact": "Contact the global operations team",
#      "Description": "Checks the amount of users connected (Active or disconnected) and will alert you appropriatley if any thresholds do not pass"
#    }
#  }
#}
# Example 1: Critical alert if more than 2 users are active/disconnected. Warning alert if more than 1 user is active/disconnected. Defaults to local host
# check-windows-connected-users.ps1
# Example 2: Critical alerts if NO users are connected in either a disconnect or active state on remote server member3
# check-windows-connected-users.ps1 -server member2.example.com -minconnected 1 -server member3.example.com
# Example 3: Critical alerts if we less than 1 user in active or disconnect state or warning if more than 2 in active state and critical if more than 5 in active state. Will alert for disconnect users as per normal defaults
# check-windows-connected-users.ps1 -server member1.example.com -minconnected 1 -activeWarn 2 -activeCrit 5

Param(
  [Parameter(Mandatory=$false)]
   [string]$server = 'localhost',

     [Parameter(Mandatory=$false)]
   [int]$activeCrit = '2',

  [Parameter(Mandatory=$false)]
   [int]$disconnectCrit = '2',

        [Parameter(Mandatory=$false)]
   [int]$activeWarn = '1',

  [Parameter(Mandatory=$false)]
   [int]$disconnectWarn = '1',
   
  [Parameter(Mandatory=$false)]
   [int]$minConnected = '0'
)

[int]$activeUsers = 0
[int]$disconnectedUsers = 0
[string]$consoleUser = "None"
[string]$activeUsersConnected = ""
[string]$disconnectedUsersConnected = ""

if (( $disconnectWarn -gt $disconnectCrit) -or ($activeWarn -gt $activeCrit)) { Write-Output "ERROR: Paramters disconnectWarn($disconnectWarn) or errorWarn($activeWarn) can not be less than disconnectCrit or errorCrit"; Exit 3}

try
{
    foreach ($line in @(query user /server $server)  -split "\n")
    {
            ForEach ( $section in $line)
            {
                $user = $section -split '\s+'
                if ( $section -match "Active") { $activeUsers++; $activeUsersConnected = $activeUsersConnected + $user[1] + " "}
                elseif ( $section -match "Disc") { $disconnectedUsers++; $disconnectedUsersConnected = $disconnectedUsersConnected + $user[1] + " " }
                elseif ($section -match "SESSIONNAME") { } #do nothing since this is the first line 
                if ($section -match "console") { $consoleUser = $user[1] }
            }
    }
    if (($disconnectedUsers -eq 0) -and ($activeUsers -eq 0) -and ( $minConnected -eq 0)) { Write-Output "There are no users logged in currently (Expected $minConnected)"; Exit 0}
    elseif (($disconnectedUsers + $activeUsers) -lt $minConnected) { Write-Output "There are $($disconnectedUsers + $activeUsers) users logged in currently when we expect atleast $minConnected"; Exit 2}
    else
    {   
        Write-Output "Connected Users ($activeUsers): $activeUsersConnected"
        Write-Output "Disconnected Users ($disconnectedUsers): $disconnectedUsersConnected"
        Write-Output "Console User: $consoleUser"
        if ($activeUsers -gt $activeCrit) { Write-Output "CRITICAL:There are more active users ($activeUsers) than the active critical threshold ($activeCrit)"; Exit 2 }
        elseif( $disconnectedUsers -gt $disconnectCrit) { Write-Output "CRITICAL:There are more disconnected users ($disconnectedUsers) then the critical disconnect threshold ($disconnectCrit)"; Exit 2}
        elseif( $activeUsers -gt $activeWarn) { Write-Output "WARNING: There are more active users ($activeUsers) then the warning active threshold ($activeWarn)"; Exit 1 }
        elseif( $disconnectedUsers -gt $disconnectWarn) { Write-Output "WARNING: There are more disconnected users ($disconnectedUsers) then the warning disconnect threshold ($disconnectWarn)"; Exit 1 }
        else { Write-Output "Success: There are no errors"; Exit 0; }
    }
}
catch
{
    Write-Output "Run Error: $($_.Exception|format-list -force)"
    Exit 3
}
