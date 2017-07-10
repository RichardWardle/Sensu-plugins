# Date: 06/07/2017
# Author: Richard Wardle
# Purpose: Query the local domain controller to see if accounts are locked, Do not exsist, if no errors pass back OK, unknown through UNKNOWN (3) can be used with sensu or nagios
# Paramters: account (array) and is mandatory
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-ad-accounts": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-ad-accounts.ps1 -accounts \"ldapuser1,ldapuser2,ldap_22\"",
#      "subscribers": [
#        "domain_controllers"
#      ],
#      "interval": 60,
#      "standalone": false,
#      "contact": "System Administrators",
#      "Description": "The purpose of this is to monitor on these critical accounts in active directory and alert if they are missing or locked out"
#    }
#  }
#}

Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string[]]$accounts
)

Import-Module ActiveDirectory

$userNotExsist = @()
$userLockedOut = @()
$userNotLocked = @()

ForEach($user in $accounts.split(","))
{
    $OU=get-aduser -Filter "sAMAccountName -eq '$user'"
    if (!$OU) {
        $userNotExsist += $user
    }
    else
    {
        if (Search-ADAccount -LockedOut -SearchBase $OU | Select Name | ft -HideTableHeaders)
        {
            $userLockedOut += $user
        }
        else
        {
            $userNotLocked += $user
        }
    }
}

if (($userNotExsist.Length -gt 0) -and ($userLockedOut.Length -gt 0))
{
    Write-Output "Locked Users: $userLockedOut and Unknown Users: $userNotExsist"
    Exit 2
}
elseif ($userLockedOut.Length -gt 0)
{
    Write-Output "Locked Users: $userNotExsist"
    Exit 2
}
elseif ($userNotExsist.Length -gt 0)
{
    Write-Output "Unkown Users: $userNotExsist"
    Exit 1
}
elseif ($UserNotLocked.Length -gt 0)
{
    Write-Output "Unlocked Users: $userNotLocked"
    Exit 0
}
else
{
    Write-Output "Something has gone wrong as no users are locked, unlocked or do NOT exsist, check if i was invoked properly"
    Exit 3
}
