#All folders in our DFSR will always exist on a specific set of servers, this is to ensure that they are backed up. E.g. In Europe or in US we will have one server which acts as a hub or a specific backup servers in the DC that is backedup. We always want to ensure that no folder is never on one of these specific servers. 
#Add your servers as an array of strings to $servers (in lower case) and if your RF exists on one of those servers it will not error otherwise it will alert you and error, Exit code of 2 for any failure or 0 for all backed up. Please also provide your domain name in $dom and the group name you want * for ALL

$dom = "example.com"
$groupname = "*"
$servers = "server1", "server2",
$endErrors = 0
$folders = Get-DfsReplicatedFolder -GroupName $groupname -DomainName $dom
$listall = Get-DfsrMembership -GroupName $groupname -ComputerName *
Write-Output "We have $($folders.count) folders that are being handled by DFS"

foreach ($indFolder in $folders)
{
    $list = $listall | Where-Object {($_.foldername -eq $indFolder.FolderName) -and ($_.Enabled -eq 'Enabled')}
    $countServers = $list.count
    $errors = 0

    foreach ($indList in $list)
    {
        if (-not ($servers.Contains($indList.ComputerName.ToLower())))
        {
            $errors++
            $endErrors++
        }
    }
    if ($errors -eq $countServers)
    {
        Write-Output "DFSR Replication Folder Name: $($indFolder.FolderName) DFSR Group Name: $($indFolder.GroupName)"
    }
}
if ($endErrors -eq 0)
{
    Write-Output "Success: Your DFSR folders all exist on the required servers!"
    Exit 0
}
else
{
    Write-output ""
    Write-output "Error: The above folders are not visible on any of the required servers to be backed up"
    Exit 2
}
