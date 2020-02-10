$HostName = get-content 'C:\Temp\Scripts\CScomputerlist.csv'


foreach ($PC in $HostName) {
    $RemotePath = "\\$PC\C$\Users\Public\Desktop\Cisco Finesse - Backup.url"
    remove-item -path $RemotePath -force -recurse
    copy-item "\\hcc-dom\files\Common\Rigo\Cisco Finesse.url" -Destination "\\$PC\C$\Users\Public\Desktop"
    }