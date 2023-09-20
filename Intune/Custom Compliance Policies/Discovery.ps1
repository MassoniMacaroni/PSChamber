# Define the file path and service name (Replace with actual values later)
$filePath = "FILE PATH HERE"
$serviceName = "SERVICE NAME HERE"

# Check if the file exists
$fileExists = Test-Path $filePath

# Check if the service is running
$serviceStatus = Get-Service -Name $serviceName -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }

# Create a result object
$result = @{
    "fileExists"     = $fileExists;
    "serviceRunning" = ($null -ne $serviceStatus)
}

# Convert the result object to JSON and output. -Compress is required.
return $result | ConvertTo-Json -Compress