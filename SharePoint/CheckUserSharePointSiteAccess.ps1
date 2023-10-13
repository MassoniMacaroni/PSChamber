<#
To be able to run this the executing user needs to be a site collection admin for all sites in the tenant.
Additionally this script is terrible and needs some work... Running for a single upn is not an issue but inputting
from a csv may cause sharepoint to throttle. need to look at batching the requests or some sort of wait?

$sites = Get-SPOSite
foreach($site in $sites){$url = $($site.url).ToString()
Set-SPOUser -site $url -LoginName "ADMIN UPN" -IsSiteCollectionAdmin $true}
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    [Parameter(Mandatory=$true)]
    [string]$AdminSiteURL,
    [Parameter(Mandatory=$false)]
    [string]$InputCsvPath
)

# Function to get sites a user has access to
function Get-UserAccessSites {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UPN
    )
    # Create an array to hold the output
    $output = @()
    #Get all sites
    $sites = Get-SPOSite
    foreach($site in $sites){
        #Get all users with access to the site
        $url = $($site.Url).ToString()
        Write-Host "Checking $url for $UPN"
        $users = Get-SPOUser -Site $url
        foreach($user in $users){
            #Check if the user is the user we are looking for
            if($user.LoginName -eq $UPN){
                Write-Host "User $($user.LoginName) has access to $($site.Url)"
                # Create a custom object to hold the site info
                $siteInfo = [PSCustomObject]@{
                    User = $user.LoginName
                    SiteUrl = $site.Url
                }
                # Add the custom object to the output array
                $output += $siteInfo
            }
        }
    }
    # Return the output array from the function
    return $output
}

#Connect to SharePoint Online
Connect-SPOService -Url $AdminSiteURL

# Collect the results outside the function
$results = @()

# Check if a single UserPrincipalName is provided
if ($UserPrincipalName) {
    $results += Get-UserAccessSites -UPN $UserPrincipalName
} 
# Check if an Input CSV path is provided
elseif ($InputCsvPath) {
    $userList = Import-Csv -Path $InputCsvPath
    foreach ($user in $userList) {
        $results += Get-UserAccessSites -UPN $user.UPN
    }
} 
else {
    Write-Host "Please provide either a UserPrincipalName or an InputCsvPath"
    exit
}

# Export the results array to a CSV file
$results | Export-Csv -Path "UserSites.csv" -NoTypeInformation
