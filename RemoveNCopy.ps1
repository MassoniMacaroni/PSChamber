$HostName = get-content 'CSV Location with Hostnames'

foreach ($PC in $HostName) {
    $RemotePath = "\\$PC\C$\Users\Public\Desktop\Specify File"
    remove-item -path $RemotePath -force -recurse
    copy-item "Specify File location" -Destination "\\$PC\C$\Users\Public\Desktop"
    }
