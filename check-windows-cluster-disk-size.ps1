# Date: 18/07/2017
# Author: Richard Wardle
# Purpose: Checks your cluster disks have not exceeded disk thresholds
# Paramters: domainname (domainname to check against, defaults to the the one running on this box), clustername (string, the cluster name to check, defaults to ALL (*)), warn and crit (int, values to warn or go crit against, defaults are 80/90 respectivley)
# If you want to run this standalone on a specific system that is not part of the cluster resource please ensure you have failover feature installed (and the right permissions running this check)
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-cluster-disks": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-cluster-disk-size.ps1",
#      "subscribers": [
#        "roundrobin:windows-clusters"
#      ],
#      "interval": 180,
#      "standalone": false,
#      "source": "HQ_Cluster_Systems",
#      "contact": "Cluster Administrators",
#      "Description": "Checks your cluster disks have not exceeded disk thresholds"
#    }
#  }
#}
# Example 1: Checks all clusters and disks checking they are not greater than the maximum
# check-windows-cluster-disk-size.ps1
# Example 2: Checks disks on the cluster called HQ-CLS-1 with a warn threshold of 70 and critical of 80
# check-windows-cluster-disk-size.ps1 -clustername "HQ-CLS-1" -warn 70 -crit 80

Param(
   [Parameter(Mandatory=$false)]
   [string]$domainname = $env:USERDNSDOMAIN,

   [Parameter(Mandatory=$false)]
   [string]$clustername = '*',

   [Parameter(Mandatory=$false)]
   [ValidateScript({ try {$_ -match [int]$_} catch { Write-Output "$_ is not a valid integer"; Exit 3} })] 
   [int]$warn = 80,

   [Parameter(Mandatory=$false)]
   [ValidateScript({ try {$_ -match [int]$_} catch { Write-Output "$_ is not a valid integer"; Exit 3} })] 
   [int]$crit = 90
)

[int]$critCounter=0
[int]$warnCounter=0
[float]$spaceUsedPercentage=100

if (($warn -gt $crit) -or ($warn -lt 0) -or ($crit -gt 100) -or ($crit -lt 0) -or ($crit -eq $warn))
{
    Write-Output "Warning: $warn or Critical: $crit. The can not be < 0 or > 100 or crit < warn or crit == warn, please resolve"
    Exit 3
}

try {
    $clusters= get-cluster -Name "$clustername" -domain "$domainname"
    if ($clusters.Length -eq 0)
    {
        Write-Output "We could not find any clusters called $clustername in the domain $domainname"
        Exit 1
    }

    ForEach ($indcluster in $clusters)
    {
        $Disks = Get-CimInstance -Namespace Root\MSCluster -ClassName MSCluster_Resource -ComputerName $indcluster.name | ?{$_.Type -eq 'Physical Disk'}
        ForEach ($single in $Disks)
        {
            $indDisk=$(Get-CimAssociatedInstance -InputObject $single -ResultClassName MSCluster_DiskPartition)
            $spaceUsedPercentage=(($inddisk.totalSize-$indDisk.FreeSpace)/$inddisk.totalsize*100)
            
            if ($spaceUsedPercentage -gt $crit) { $status="Critical:"; $critCounter++ }
            elseif ($spaceUsedPercentage -gt $warn) { $status="Warning:"; $warnCounter++ }
            else { $status="OK:"}

            Write-Output "$($status) Cluster: $($indDisk.PSComputerName) for volume: $($indDisk.VolumeLabel) has used $spaceUsedPercentage of the total disk space"
        }
    }

    if ( $critCounter -gt 0) {Exit 2}
    elseif ($warnCounter -gt 0) { Exit 1}
    else { Exit 0}
}
catch
{
     Write-Output "Run Error: $($_.Exception | format-list -force)"
     Exit 3
}
