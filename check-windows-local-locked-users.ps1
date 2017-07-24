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
        $time= (Get-Date).AddHours(-3)
     
        $events=Get-WinEvent -ComputerName "$comp" -FilterHashtable @{logname='security';data=$indLock.Name;id='4625';StartTime=$time} -MaxEvents $eventline -EA stop | 
        Select-Object -Property TimeCreated, Message, MachineName, Id
      
        $lockOutEvent= Get-WinEvent -ComputerName "$comp" -FilterHashtable @{logname='security';id=4740;data=$indLock.Name;StartTime=$time} -MaxEvents 1 -EA stop |
        Select-Object -Property @{label='computername';expression={$_.properties[1].value}}

        Write-output "User: $($events[0].MachineName)\$($indLock.Name) is currently locked out, suspect source is $($lockOutEvent.computername)"
        Write-output ""

        ForEach ($single in $events)
        {
         Write-output "EventID:$($single.Id), Time: $($single.TimeCreated.DateTime), Message: $(($single.message -split '\n')[0])"
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
