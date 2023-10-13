$password = Read-Host -Prompt "Enter password" -AsSecureString
$Cred = New-Object System.Management.Automation.PSCredential ("ADMIN EMAIL HERE", $password)
$CSVpath = "PATH TO CSV WITH SHAREPOINT URLs"
Import-csv $CSVpath | ForEach-Object {
    Connect-PnPOnline -Url $_.URL -Credentials $Cred
    Get-PnPList -Identity Documents
    Disconnect-PnPOnline
}