param (
    [Parameter(Mandatory=$true)]
    [string]$startDate,

    [Parameter(Mandatory=$true)]
    [string]$endDate
)

# Define the path for the exported event log files
$hostname = $env:COMPUTERNAME
$logDirectory = "C:\Logs"
if (!(Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory
}
$appLogPath = "$logDirectory\$hostname-ApplicationEventLogs.csv"
$secLogPath = "$logDirectory\$hostname-SecurityEventLogs.csv"
$sysLogPath = "$logDirectory\$hostname-SystemEventLogs.csv"

# Export the Application, Security, and System event logs for the specified date range to CSV files
Get-EventLog -LogName Application -After $startDate -Before $endDate | Export-Csv -Path $appLogPath -NoTypeInformation
Get-EventLog -LogName Security -After $startDate -Before $endDate | Export-Csv -Path $secLogPath -NoTypeInformation
Get-EventLog -LogName System -After $startDate -Before $endDate | Export-Csv -Path $sysLogPath -NoTypeInformation

# Define the path for the zip archive
$zipPath = "$logDirectory\$hostname-EventLogs-$startDate-$endDate.zip"

# Create a zip archive with the exported event log files
Compress-Archive -Path $logDirectory\* -DestinationPath $zipPath -Force

