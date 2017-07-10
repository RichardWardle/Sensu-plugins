# Date: 07/07/2017
# Author: Richard Wardle
# Purpose: Check if network interfaces match the expected speeds and settings, defaults are all interfaces, Full and 1GB using the Get-NetAdaper powershell module, exits with 0 if OK or 2 if ANY of the settings do not match
# Paramters: Name, Speed in bits, Duplex True or False and Status Up/Down/Disabled
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-interface-check": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-int-specs.ps1 -name Core -fullduplex True -speed 1000000000",
#      "subscribers": [
#        "windows"
#      ],
#      "interval": 120,
#      "standalone": false,
#      "contact": "System Administrators",
#      "Description": "Check if network interfaces match the expected speeds and settings, defaults are all interfaces, Full and 1GB using the Get-NetAdaper powershell module"
#    }
#  }
#}


Param(
  [Parameter(Mandatory=$False)]
   [string]$name = '*',

  [Parameter(Mandatory=$False)]
   [string]$speed = 1000000000,

     [Parameter(Mandatory=$False)]
   [string]$fullduplex = 'True',

     [Parameter(Mandatory=$false)]
   [string]$status = 'Up'
)

$errors = "ERRORS: "
$success = "Success: "

try { 
    $results = Get-NetAdapter | SELECT name, status, speed, fullduplex | where name -like *$name* 
    if (!$results)
        {
        Write-Output "Error: Search Returned no results"
        Exit 3
        }
    } 
catch { 
    Write-Output "Run Error: $_.Exception.Message"
    Exit 3
    }
    
ForEach ($element in $results) {
    $holder = $element.name + " "
    if (( $element.speed -ne $speed) -or ($element.fullduplex -ne $fullduplex) -or ( $element.status -ne $status))
        {
            $holder = $holder + "State: " + $element.speed + "/" + $element.fullduplex + "/" + $element.status + ", "
            $errors = $errors + $holder
        }
    else
        {
            $holder = $holder + "OK, "
            $success = $success + $holder
        }      
}

#Computing section has been done and now we are checking if errors matches are original definition
#If it does not then we have a problem. We also regardless remove the last 2 characters which
#are a comma and then space for the formatting people.

if ( $errors -ne "ERRORS: ")
{
    $errors = $errors.Substring(0,$errors.Length-2)
    Write-Output "$errors"
    Exit 2
}
elseif ( $errors -like "ERRORS: *")
{
    $success = $success.Substring(0,$success.Length-2)
    Write-Output "$success"
    Exit 0
}
else
{
    Write-Output "Unknown logic error has occured, please investigate."
    Exit 3
}
