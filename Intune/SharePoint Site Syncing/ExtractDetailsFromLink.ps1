param(
    [Parameter(Mandatory=$true)]
    [string]$inputUrl
)

# Extract values from the URL
$siteId = [System.Web.HttpUtility]::UrlDecode(($inputUrl -split "siteId=")[1].split("&")[0])
$webId = [System.Web.HttpUtility]::UrlDecode(($inputUrl -split "webId=")[1].split("&")[0])
$listId = [System.Web.HttpUtility]::UrlDecode(($inputUrl -split "listId=")[1].split("&")[0])
$webUrl = [System.Web.HttpUtility]::UrlDecode(($inputUrl -split "webUrl=")[1].split("&")[0])
$webTitle = [System.Web.HttpUtility]::UrlDecode(($inputUrl -split "webTitle=")[1].split("&")[0])
$listTitle = [System.Web.HttpUtility]::UrlDecode(($inputUrl -split "listTitle=")[1].split("&")[0])

# Create the output content
$outputContent = @"
    siteId    = "$siteId"
    webId     = "$webId"
    listId    = "$listId"
    webUrl    = "$webUrl"
    webTitle  = "$webTitle"
    listTitle = "$listTitle"
"@

# Write the content to a text file
$outputContent | Out-File "$webtitle.txt"

Write-Output "File '$webtitle.txt' created successfully!"
