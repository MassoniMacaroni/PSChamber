## MODULE REQUIREMENTS ##
# install-module -name MSAL.PS

## APP REGISTRATION REQUIRED PERMISSIONS ##
# Directory.ReadWrite.All - Application
# Policy.ReadWrite.SecurityDefaults - Application
# PrivilegedAccess.ReadWrite.AzureAD - Application
# PrivilegedAccess.ReadWrite.AzureADGroup - Application
# RoleManagement.ReadWrite.Directory - Application
# RoleManagement.ReadWrite.Exchange - Application
# SecurityEvents.ReadWrite.All - Application
# User.ReadWrite.All - Application

# Import the MSAL module
Import-Module MSAL.PS

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$ClientSecret,

    [Parameter(Mandatory=$true)]
    [string]$displayName,

    [Parameter(Mandatory=$true)]
    [string]$mailNickname,

    [Parameter(Mandatory=$true)]
    [string]$userPrincipalName,

    [Parameter(Mandatory=$true)]
    [string]$password
)

# Define a hashtable with connection details for Microsoft Authentication Library (MSAL)
$connectionDetails = @{
    'TenantId'     = $TenantId
    'ClientId'     = $ClientId
    'ClientSecret' = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
}

# Use the connection details to get an authentication token from MSAL
$authToken = Get-MsalToken @connectionDetails

$params = @{
        accountEnabled = $true
        displayName = $displayName
        mailNickname = $mailNickname
        userPrincipalName = $userPrincipalName
        passwordProfile = @{
            forceChangePasswordNextSignIn = $false
            password = $password
        }
}

# Convert the parameters to JSON format
$jsonParams = $params | ConvertTo-Json

# Invoke a POST request to the Microsoft Graph API to create a new user
# The headers include an authorization token
# The body of the request is the JSON parameters
$user = Invoke-RestMethod -Headers @{Authorization = "Bearer $($authToken.AccessToken)" } `
    -Uri  'https://graph.microsoft.com/v1.0/users' `
    -Method POST `
    -Body $jsonParams `
    -ContentType 'application/json'


# Prepare the parameters for the role assignment
# The id of the newly created user is used here
$roleParam = @"
    {
    "@odata.id": "$("https://graph.microsoft.com/v1.0/directoryObjects/" + $user.id)"
     }
"@

# Invoke a GET request to the Microsoft Graph API to fetch the role id for a global administrator
# The headers include an authorization token 
# 62e90394-69f5-4237-9190-012177145e10 is the roleTemplateId for Global Administrator  
$roles = Invoke-RestMethod -Headers @{Authorization = "Bearer $($authToken.AccessToken)" } `
    -Uri  "https://graph.microsoft.com/v1.0/directoryRoles(roleTemplateId='62e90394-69f5-4237-9190-012177145e10')" `
    -Method GET 


# Invoke a POST request to the Microsoft Graph API to add a member to the role
Invoke-RestMethod -Headers @{Authorization = "Bearer $($authToken.AccessToken)" } `
    -Uri  $('https://graph.microsoft.com/v1.0/directoryRoles/' + $roles.id + '/members/$ref') `
    -Method POST `
    -Body $roleParam `
    -ContentType 'application/json'

