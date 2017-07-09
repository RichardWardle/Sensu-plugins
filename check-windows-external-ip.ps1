# Date: 09/07/2017
# Author: Richard Wardle
# Purpose: Checks your external IP address matches what you expect
# Paramters: ip (IP Address, Mandatory, takes a valid IP address errors if not), timeout (Int, Optional, takes a timeout value for invoke-webrequest, defaults to 5)
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-external-ip": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-external-ip.ps1 -ip 55.55.55.55 -timeout 5",
#      "subscribers": [
#        "windows-monitor"
#      ],
#      "interval": 600,
#      "standalone": false,
#      "contact": "Network Administrators",
#      "Description": "Checks your external IP address matches what you expect"
#    }
#  }
#}
# Example 1: Checks IP address matches 5.5.5.5
# check-windows-external-ip.ps1 -ip 5.5.5.5
# Example 2: Checks IP address matches 6.6.6.6 and specifies a timeout of 10
# check-windows-external-ip.ps1 -ip 6.6.6.6 -timeout 10

Param(
  [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
  [ValidateScript({ try {$_ -match [IPAddress]$_} catch { Write-Host $_ is not a valid IP address; Exit 3} })]  
  [string]$ip,

  [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
  [ValidateScript({ try {$_ -match [int]$_} catch { Write-Host $_ is not a valid integer; Exit 3} })]  
  [string]$timeout
)

try {
    $results = invoke-webrequest http://ifconfig.co/json -TimeoutSec $timeout | ConvertFrom-Json -ErrorAction stop -Verbose
    if ($results.ip -eq $ip)
    {
        Write-Host Success: Internal $ip matches external address: $results.ip
        Exit 0
    }
    elseif ($results.ip -ne $ip)
    {
        Write-Host Error: Internal $ip DOES NOT match external address: $results.ip
        Exit 2
    }
    else
    {
        Write-Host Unknown Error has occured, please check debug
        Write-Host Results: $results
        Exit 1
    }
}
catch
{
    Write-Host "Warning: I could not connect to the service. Please ensure internet connectivity, timeout value is high enough, you are not hammering http://ifconfig.co and the Invoke-WebRequest error below"
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    Exit 1
}
