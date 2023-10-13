
Connect-MgGraph -Scopes "Directory.Read.All","AuditLog.Read.All"

$signIns = Get-MgAuditLogSignIn -All | 
    Select-Object CreatedDateTime, UserDisplayName, AppDisplayName, IPAddress |
    Where-Object { $_.CreatedDateTime -ge (Get-Date).AddDays(-30) }

$grouped = $signIns | Group-Object UserDisplayName

$index = 0
$total = $grouped.Count
$oldestSignIns = $grouped | ForEach-Object {
    $index++
    Write-Progress -Activity "Processing Users" -Status "Processing User $index of $total" -PercentComplete (($index / $total) * 100)
    $_.Group | Sort-Object CreatedDateTime | Select-Object -Last 1
}

$oldestSignIns | Format-Table -AutoSize