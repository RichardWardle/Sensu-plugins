Param(
  [Parameter(Mandatory=$false)]
  [string]$comp = $env:COMPUTERNAME,

  [Parameter(Mandatory=$false)]
  [ValidateScript({ try {$_ -match [int]$_} catch { Write-Output "$_ is not a valid integer"; Exit 3} })]  
  [int]$eventline = 5

)
[int]$errors=0

try
{
    $lockedUsers=Get-WmiObject -Class Win32_UserAccount -computer "$comp" -Filter  "LocalAccount='True' AND AccountType='512' AND disabled='false' AND Lockout='true'" -EA stop | Select PSComputername, Name, Status, Disabled, AccountType, Lockout, SID

    if ($lockedUsers.Count -eq 0)
    {
        Write-Output "OK: There are no users who are currently locked out on $($env:COMPUTERNAME)"
        Exit 0
    }

    ForEach ($indLock in $lockedUsers)
    {
        $events=Get-WinEvent -ComputerName $comp -FilterHashtable @{logname='security';data=$indLock.Name} -MaxEvents $eventline | 
        Select-Object -Property TimeCreated, Message, MachineName
      
        Write-output "User: $($events[0].MachineName)\$($indLock.Name) is currently locked out"
        Write-output ""

        ForEach ($single in $events)
        {
         Write-output "Time: $($single.TimeCreated.DateTime), Message: $(($single.message -split '\n')[0])"
        }
        Write-Output ""
        $errors=1
    }

    if ($errors -gt 0) {Exit 2}
    else {exit 0}
}
catch
{
    Write-host Run Error: $_.Exception.Message
    Exit 1
}
