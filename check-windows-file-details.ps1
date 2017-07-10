# Date: 08/07/2017
# Author: Richard Wardle
# Purpose: Checks files in a specified directory (and sub directories if specified) exsist as per count and are greater than a specified size
# Paramters: dir (String, Mandatory, location of files), include (String, Optional, Files you want to include in search, defaults to *.*), exclude (string, Optional, file you want to exclude defaults to a random string), minSize (int, optional, size in bits defaults to 100000)
# expected count (int, Optional, defaults to 5 and is how many files you expect to be there), subfolders (string array, Optional, defaults to False and is EITHER False of True exactly - this is NOT A BOOLEAN STRING) 
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-file-details": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-file-details.ps1 -dir C:\certs -include *.cer -subfolders False -exclude backup*.cer -minSize 1000 -expectedCount 3",
#      "subscribers": [
#        "windows-hosts"
#      ],
#      "cron": "60 * * * *",
#      "standalone": false,
#      "contact": "System Administrators",
#      "Description": " Checks files in a specified directory (and sub directories if specified) exsist as per count and are greater than a specified size"
#    }
#  }
#}
# Example 1: Checks all files in directory C:\backup are greater than 1000 bytes and we have the last 7 days (logrotate removes everything older than that)
# check-windows-file-details.ps1 -dir C:\backup -minSize 1000 -expectedCount 7
# Example 2: Checks all files in C:\backup including subfolders have a count of default 5 and minSize of 10000
# check-windows-file-details.ps1 -dir C:\backup -minSize 10000 -subfolders True
# Example 3: Checks all files in C:\certs only (no subfolders) for files matching *.cer but excluding any files which start with backup and end with .cer e.g. backup_main.cer. We expect 3 files to exsist all greater than 1000 bytes
# check-windows-file-details.ps1 -dir C:\certs -include *.cer -subfolders False -exclude backup*.cer -minSize 1000 -expectedCount 3

Param(
     [Parameter(Mandatory=$True)]
   [string]$dir,
     [Parameter(Mandatory=$False)]
   [string]$include = "*.*",
     [Parameter(Mandatory=$False)]
   [string]$exclude = "sdv32zs",
     [Parameter(Mandatory=$False)]
   [int]$minSize = 1000000,
     [Parameter(Mandatory=$False)]
   [int]$expectedCount = 5,
     [Parameter(Mandatory=$False)]
   [string]$subfolders = "False"
)

[int]$counter = 0
[string]$errorfiles = "File Errors:"
[string]$okfiles = "File OK:"

if (!(Test-Path $dir)) { Write-Output "Folder $dir does not exsist"; Exit 1}
if (($subfolders -ne "False") -and ($subfolders -ne "True")){ Write-Output "Incorrect subfolders parameter passed, it is either True or False exactly"; Exit 3}

try 
{
    if ($subfolders -eq "False") { $results = Get-ChildItem -Path "$dir\*" -include $include -exclude $exclude -Verbose -Debug }
    else { $results = Get-ChildItem -Path "$dir\*" -Recurse -include $include -exclude $exclude -Verbose -Debug }
 
    if (( $results.Count -lt $expectedCount ) -or ( $results.Count -gt $expectedCount )) { Write-Output "File Count Error:  $($results.Count) out of $expectedCount"; $counter++ }
    else {  Write-Output "File Count OK: $($results.Count) out of $expectedCount" }

    ForEach( $file in $results)
    {
        if ($file.Length -lt $minSize) { $errorfiles = $errorfiles + " " + $file.FullName + "," }
        else { $okfiles = $okfiles + " " + $file + "," }
    }

    if ($errorFiles -ne "File Errors:") { $counter++}
    
    $errorfiles = $errorfiles.TrimEnd(", ")
    $okFiles = $okfiles.TrimEnd(", ")

    Write-Output "$errorfiles"
    Write-Output "$okFiles"

    if ( $counter -eq 1) {Exit 1}
    elseif ( $counter -eq 2) {Exit 2}
    else { Exit 0 }
}
catch
{
    Write-Output "Unknown Error has occured please investigate"
    Write-Output "Run Error: $_.Exception.Message"
    Exit 3
}
