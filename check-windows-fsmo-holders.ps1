# Date: 12/12/2017
# Author: Richard Wardle
# Purpose: Checks all FSMO roles are what you expect
# Paramters: takes FSMO role holders as a mandatory with schemaMaster, pdcEmulator, DomainNamingMaster, ridMaster, InfrastructureMaster and domainName as optional
# will use your current domain as the one to check. It will use user dns domain so if thats off or if you are running in a multi forest environment i would not
# use this and manually set it. You can use get-addomain and check the Forest attribute for what you should put there
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-fsmo-holders": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-fsmo-holders.ps1 -schemaMaster X -domainNamingMaster X -infrastructureMaster X -pdcEmulator X -ridMaster X",
#      "subscribers": [
#        "windows-monitor-servers"
#      ],
#      "Interval": 86400,
#      "standalone": false,
#      "contact": "Network System Administrators",
#      "Description": "Checks all FSMO roles are what you expect"
#    }
#  }
#}

Param(
     [Parameter(Mandatory=$False)]
     [string] $domainName = $env:USERDNSDOMAIN,

     [Parameter(Mandatory=$True)]
     [string] $schemaMaster,

     [Parameter(Mandatory=$True)]
     [string] $pdcMaster,

     [Parameter(Mandatory=$True)]
     [string] $infrastructureMaster,

     [Parameter(Mandatory=$True)]
     [string] $ridMaster,

     [Parameter(Mandatory=$True)]
     [string] $domainNamingMaster
)

$ridMasterState = "[OKAY]"
$schemaMasterState = "[OKAY]"
$infraMasterState = "[OKAY]"
$pdcMasterState = "[OKAY]"
$domainMasterState = "[OKAY]"
$errors = 0

try
{

    $domain = Get-ADDomain | where { $_.Forest -eq $domainName}| select Name,DomainMode,Forest,RIDMaster,PDCEmulator,InfrastructureMaster,SchemaMaster,DomainNamingMaster

    if ($domain.length -eq 0)
    {
        Write-Output "The domain $domainName does not exist or I could not get any results for it, ensure you have the rights to check and that a ping $domainname returns a valid domain controller"
        Exit 2
    }
    else
    {

        if ($domain.RIDMaster -ne $ridMaster)
        {
            $ridMasterState = "[ERROR]"
            $errors +=1
        }

        if ($domain.PDCemulator -ne $pdcMaster)
        {
            $pdcMasterState = "[ERROR]"
            $errors +=1
        }

        if ($domain.DomainNamingMaster -ne $domainMaster)
        {
            $domainMasterState = "[ERROR]"
            $errors +=1
        }

        if ($domain.SchemaMaster -ne $schemaMaster)
        {
            $SchemaMasterState = "[ERROR]"
            $errors +=1
        }

        if ($domain.InfrastructureMaster -ne $infrastructureMaster)
        {
            $infraMasterState = "[ERROR]"
            $errors +=1
        }

        Write-Output "Domain Name: $($domain.Name)"
        Write-Output "Domain Level: $($domain.DomainMode)"
        Write-output "$infraMasterState Infrastructure Master is: $($domain.InfrastructureMaster)"
        Write-output "$SchemaMasterState Schema Master is: $($domain.SchemaMaster)"
        Write-output "$pdcMasterState PDC Emulator is: $($domain.PDCEmulator)"
        Write-output "$domainMasterState Domain Naming Master is: $($domain.DomainNamingMaster)"
        Write-output "$ridMasterState RID Master is: $($domain.RIDMaster)"

        if ($errors -gt 0) {Exit 2} else { Exit 0}
    }

}
catch
{
    Write-Output "An Error has occured please investigate using the below error message"
    Write-Output "Run Error: $($_.Exception.Message)"
    Exit 3


}
