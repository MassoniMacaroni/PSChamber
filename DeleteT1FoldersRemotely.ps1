Write-Host "This Script will end any T1 Processes on the target PC and delete all T1 folders. `n"
Write-Host "This Script requires PSRemoting to be enabled. `n"

# Declare Variables
$HostName = Read-host -Prompt "Please Enter a PC name."
$Username = Read-host -Prompt "Enter the username."
$RemotePath = "\\$Hostname\C$\Users\$Username\Appdata\Local"
$VerbosePreference = 'Continue'

Set-Service -ComputerName $HostName -Name WinRM -Status Running

# Get Computer Name from target PC
$RemotePCName = Invoke-Command $HostName {
    $PCName = Get-ComputerInfo -Property CsDnsHostname | Select-Object CsDnsHostname -ExpandProperty CsDnsHostname
    Return $PCName
}

# Validate the Computer Name
If ( $RemotePCName -match $HostName ) {

    #Stop T1 Processes
    $Result = Invoke-Command $HostName { 
        $StopProcess = Get-Process | Where-Object Name -like "t1*" | Stop-Process -Force -Verbose
        Return $StopProcess }

    # Clear T1 Files/Folders
    Get-ChildItem -Path $RemotePath | Where-Object { $_.Name -like "t1*" -or $_.Name -like "tb*" -or $_.Name -like "techone*" } | Remove-Item -Force -Recurse -Verbose 
}
Else {
    [System.Windows.MessageBox]::Show('DNS Mismatch')
    Exit
}

Set-Service -ComputerName $HostName -Name WinRM -Status Stopped -ErrorAction Ignore