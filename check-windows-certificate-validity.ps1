# Date: 08/07/2017
# Author: Richard Wardle
# Purpose: Checks if any certificates in the specified store are about to expire with in your specified warning/critical time (days) has the ability to ignore specific strings too
# Paramters: Name (string, defaults to *), Warning (int, defaults to 30), critical (int, defaults to 15), location (string, defaults to localmachine\My), override (string array, defaults to nothing)
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-certificate-validity": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-certificate-validity.ps1 -name * -warning 30 True -critical 15 -override example-DC-CA",
#      "subscribers": [
#        "windows"
#      ],
#      "cron": 5 */2 * * *,
#      "standalone": false,
#      "contact": "System Administrators",
#      "Description": "Checks if any certificates in specified store are going to expire"
#    }
#  }
#}
# Example 1: Checks all certificates with example before/after in DnsName and adheres to the default in cert:\LocalMachine\My
# check-windows-certificate-validity.ps1 -name *example*
# Example 2: Checks all certificates, reduces the warning days to 10 and critical to 5. Does not alert on certificates with example-DC-CA
# check-windows-certificate-validity.ps1 -warning 10 True -critical 5 -override example-DC-CA
# Example 3: Checks all certificates in the CurrentUser location
# check-windows-certificate-validity.ps1 -location "cert:\CurrentUser\"

Param(
  [Parameter(Mandatory=$False)]
   [string]$name="*",

     [Parameter(Mandatory=$False)]
   [int]$warning = 30,

     [Parameter(Mandatory=$False)]
   [int]$critical = 15,

     [Parameter(Mandatory=$False)]
   [string]$location="cert:\LocalMachine\My",

     [Parameter(Mandatory=$False)]
   [string[]]$override
)

Import-Module pki
[string]$ignoredMessage = "Ignored: "
[string]$expiredMessage = "Expired: "
[string]$criticalMessage = "Critical: "
[int]$criticalCount = 0
[string]$warningMessage = "Warnings: "
[int]$warningCount = 0
[string]$okMessage = "Success: "
[int]$okCount = 0

if ( $warning -lt $critical)
{
    Write-Output "Warning($warning) can not be less than critical($critical)"
    Exit 3
}

try 
{
    Set-Location "$location" -ErrorAction stop -Verbose
    $results = Get-ChildItem -Recurse -DnsName "*$name*" | SELECT NotAfter, NotBefore, DnsNameList -ErrorAction stop -Verbose
    if (!$results) 
    {
        Write-Output "Error: No certificates found called $name in $location"
        Exit 3
    }
    ForEach ($cert in $results) 
    {
    $expire = $cert.NotAfter - $cert.NotBefore
        if ($override -notcontains $cert.DnsNameList.Punycode)
        { 
                if ( $expire.Days -lt 1)
                {
                     $expiredMessage = $expiredMessage + $cert.DnsNameList.Punycode + " (" + $expire.NotAfter + "), "
                     $criticalCount++
                }
                elseif ( $expire.Days -lt $critical)
                {
                     $criticalMessage = $criticalMessage + $cert.DnsNameList.Punycode + " (" + $expire.Days + " Days), "
                     $criticalCount++
                }
                elseif ( ($expire.Days -gt $critical) -and ( $expire.Days -lt $warning))
                {
                    $warningMessage = $warningMessage + $cert.DnsNameList.Punycode + " (" + $expire.Days + " Days), "
                    $warningCount++
                }
                else
                {
                     $okMessage = $okMessage + $cert.DnsNameList.Punycode + " (" + $expire.Days + " Days), "
                     $okCount++
                }
            }
            else
            {
                $ignoredMessage = $ignoredMessage + $cert.DnsNameList.Punycode + " (" + $expire.Days + " Days), "
            }
    }

    Write-Output "$expiredMessage"
    Write-Output "$criticalMessage"
    Write-Output "$warningMessage"
    Write-Output "$okMessage"
    Write-Output "$ignoredMessage"

    if ($criticalCount -gt 0) { Exit 2}
    elseif ($warningCount -gt 0) { Exit 1 }
    else { Exit 0}
}
catch 
{
    Write-Output "Run Error: $_.Exception.Message"
    Exit 3
}
