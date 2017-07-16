# Date: 15/07/2017
# Author: Richard Wardle
# Purpose: Checks files in a specified directory exsist as per count, greater than a specified size and have updated after a certain time
# Paramters: 
# Sensu Example Check:
#{
#  "checks": {
#    "sensu-windows-file-details": {
#      "command": "powershell.exe -ExecutionPolicy Unrestricted -f C:\\opt\\sensu\\plugins\\powershell\\check-windows-file-updated.ps1 -dir C:\certs -include *.csv -exclude backup*.csv -minSize 100 -expectedCount 3",
#      "subscribers": [
#        "windows-hosts"
#      ],
#      "cron": "60 * * * *",
#      "standalone": false,
#      "contact": "System Administrators",
#      "Description": "Checks files in a specified directory exsist as per count, greater than a specified size and have updated after a certain time"
#      "auto_resolve": false
#    }
#  }
#}
# Example 1: The below will check we have 7 files in the folder C:\backup, it will exclude any files ending in backup.csv and will only check on monday-friday, it will expect all files to have updated after 0500 local
# check-windows-file-updated.ps1 -dir C:\backup -minSize 1000 -expectedCount 7 -exclude *backup.csv -days "Monday,Tuesday,Wednesday,Thursday,Friday" -minutes 300
# Example 2: Below will check all files in C:\backup ensuring all files are above 10000 bytes expecting the default 5 files, the files updated after default 0800 local every day (480 minutes)
# check-windows-file-updated.ps1 -dir C:\backup -minSize 10000 
# Example 3: All files in C:\certs ending in .cer and exlcuding backup.*cer files, there are 3 files with a minimum size of 1000 bytes, the files should updated AFTER 1600 local and we will only do this check on a Monday
# check-windows-file-updated.ps1 -dir C:\certs -include *.cer -exclude backup*.cer -minSize 1000 -expectedCount 3 -minutes 960 -days "Monday"
##### PLEASE NOTE THE BELOW #####
# This check will clear if we roll into a business day that we do not check, e.g. if we error for a file that has updated at 2300 and we only check on a Monday, and we roll into Tuesday it will auto clear.
# This check will clear if we roll into the next business day and the current time in minutes is less than the time which is specified in the paramter $minutes
# To overcome this i set auto_resolve to false and an operator will have to manually clear this. I should move the below logic around so we automatically handle this

Param(
     [Parameter(Mandatory=$True)]
   [string] $dir,
     [Parameter(Mandatory=$False)]
   [string] $days = "Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday",
     [Parameter(Mandatory=$False)]
   [int] $expectedCount = 5,
     [Parameter(Mandatory=$False)]
   [string] $include = "**",
     [Parameter(Mandatory=$False)]
   [string] $exclude = "sdv32zs",
     [Parameter(Mandatory=$False)]
   [int] $minSize = 10,
     [Parameter(Mandatory=$False)]
   [int] $minutes = 480
)

[int]$counter = 0
[string]$countString = "Count Success: "
[string]$errorfiles = "File Errors:"
[string]$okfiles = "File OK:"
[string[]]$splitdays = $days.split(",")

$current=$(Get-date)
$currentTimeMinutes=($current.Hour*60 + $current.Minute)

if (!(Test-Path $dir)) { Write-Output "Folder $dir does not exsist"; Exit 1}

if (($splitdays -notcontains $current.DayOfWeek) -or ( $currentTimeMinutes -lt $minutes))
{
    Write-Output "NOT CHECKED: The days we check on are $($days), we are on $($current.DayOfWeek). We also only check after ($minutes), Current time is ($currentTimeMinutes)"
    Write-Output "This is informational only and we will not error given that your check may be running constantly, if you expect this to run ensure your days paramter is passed as a string with no spaces and has the correct days with the right spelling"
    Exit 0
}

try 
{
   $results = Get-ChildItem -Path "$dir\*" -include $include -exclude $exclude -Verbose -Debug 

   if (($results.count -eq 0) -or ($results.count -ne $expectedCount))  
   { 
    $countString = "Count Error:";
    $counter++ 
   }

   foreach ( $file in $results)
    { 
        $fileModifiedTime= $file.lastwritetime.Hour*60 + $file.lastwritetime.Minute
         if (( $file.lastwritetime.Day -ne $current.Day) -or ($file.LastWriteTime.Month -ne $current.Month) -or ( $file.LastWriteTime.Year -ne $current.year) -or ($file.Length -lt $minSize))
         { 
            $errorFiles = $errorfiles + " $($file.Name) ($($file.LastWriteTime)) $($file.Length) bytes,"
            $counter++
         }
         elseif ($fileModifiedTime -gt $minutes)
         { 
            $okFiles = $okfiles + " $($file.Name) ($($file.LastWriteTime)) $($file.Length) bytes,"
         }
         else 
         { 
            $errorFiles = $errorfiles + " $($file.Name) ($($file.LastWriteTime) $($file.Length) bytes),"
            $counter++
         }
       }
    Write-Output "$($countString) We have $($results.count)/$($expectedCount) files in $($dir)"
    Write-Output $errorfiles.TrimEnd(",")
    Write-Output $okfiles.TrimEnd(",")
    
    if ( $counter -gt 0) {Exit 2}
    else {Exit 0}
}
catch
{
    Write-Output "Unknown Error has occured please investigate"
    Write-Output "Run Error: $_.Exception.Message"
    Exit 3
}
