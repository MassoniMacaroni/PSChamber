Connect-MgGraph -Scopes "Directory.Read.All","AuditLog.Read.All"
# LIGHTHOUSE PROVIDED USER NOT REGISTERED WITH MFA LIST is in format of: User,Username columns
$users = Import-Csv -Path "PATH TO CSV"
$notSignedInUsers = @()

foreach ($user in $users) {
    Write-Host "Checking $($user.User)"
    $signIn = Get-MgAuditLogSignIn -Filter "UserPrincipalName eq '$($user.Username)' and UserDisplayName eq '$($user.User)'" -Top 1
    if (!$signIn) {
        $notSignedInUsers += $user
    }
}

if ($notSignedInUsers.Count -gt 0) {
    $UserObjects = $notSignedInUsers | Select-Object @{Name='Username';Expression={$_}}
    $UserObjects | Export-Csv -Path "C:\temp\notSignedInUsers.csv"
}
Disconnect-MgGraph