# Function to enumerate registry values
Function Get-RegistryValues {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Push-Location
    Set-Location -Path $Path
    Get-Item . | Select-Object -ExpandProperty property | ForEach-Object {
        New-Object psobject -Property @{Property=$_;Value = (Get-ItemProperty -Path . -Name $_).$_}
        
    }
    Pop-Location
} 

# Registry path for the ExtensionInstallForcelist
$RegistryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
$KeyType = "String"

# Microsoft Web Activities Extension. This can be any extension. Modify to suit any needs
$ExtensionID = "ppnbnpeolgkicgegkbkbjmhlideopiji;https://clients2.google.com/service/update2/crx"

if (test-path $RegistryPath) {
    $RegistryValues = Get-RegistryValues $RegistryPath -ErrorAction SilentlyContinue
    if ($RegistryValues | ?{$_.value -eq $ExtensionID}){
        return
    }
    $KeyName = ($RegistryValues | measure-object -max Property).maximum + 1
  } else {
    New-Item -Path $RegistryPath -Force
    $KeyName = 1
  }
New-ItemProperty -Path $RegistryPath -Name $KeyName -PropertyType $KeyType -Value $ExtensionID
