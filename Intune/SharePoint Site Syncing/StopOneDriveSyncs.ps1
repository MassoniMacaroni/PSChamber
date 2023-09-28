param(
    [Parameter(Mandatory=$true)]
    [string]$FriendlySiteName,
    [Parameter(Mandatory=$true)]
    [string]$URLSiteName,
    [Parameter(Mandatory=$true)]
    [string]$Company,
    [Parameter(Mandatory=$false)]
    [string]$ListTitle = "Documents"
)

# stop OneDrive
#If onedrive is in both places It will only stop the program files one
if(Test-Path -path "$env:PROGRAMFILES\Microsoft OneDrive\OneDrive.exe") {
    $OneDrivePath = "$env:PROGRAMFILES\Microsoft OneDrive\OneDrive.exe"
} elseif (Test-Path -path "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"){
    $OneDrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
} else {
    Write-Error "OneDrive not found"
    return
}

if($null -ne $OneDrivePath){
    Start-Process $OneDrivePath /shutdown
    Start-Sleep -Milliseconds 500
} else {
    Write-Error "OneDrive not found"
    return
}

# remove sync configuration file
foreach ($IniFile in (Get-Item "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive\settings\Business1\ClientPolicy_*.ini")) {
    $IniFileContent = Get-Content -Path $IniFile -Encoding Unicode
    $ContainsSiteName = $IniFileContent | Select-String -Pattern $URLSiteName
    if ($null -ne $ContainsSiteName) {
        Remove-Item $IniFile
        break
    }
}


# remove sync registry value
$Key = Get-Item HKCU:\Software\Microsoft\OneDrive\Accounts\Business1\ScopeIdToMountPointPathCache
foreach ($Property in $Key.Property) {
    if ($Key.GetValue($Property) -like "*$FriendlySiteName*" ) {
        Remove-ItemProperty -Path $Key.PSPath -Name $Property
        break
    }
}

$IniFiles = Get-Item "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive\settings\Business1\????????-????-????-????-????????????*.ini"


#Update Temp ini files
foreach($f in $IniFiles){
    $content = Get-Content $f -Encoding Unicode | Where-Object {$_ -notmatch "$URLSiteName"}

    $content | Set-Content ($f.FullName) -Encoding Unicode

}

# Remove the folder
Remove-Item "$env:USERPROFILE\$Company\$FriendlySiteName - $ListTitle" -Recurse -Force

# restart OneDrive
Start-Process $OneDrivePath /background
