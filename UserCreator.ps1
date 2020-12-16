Clear-Host

############################################################
# Prereqs in order to assign an O365 License to an account #
# Assuming AD module is already installed                  #
#                                                          #
# Install-Module -Name Az -Repository PSGallery -Force     #  
# Install-Module MSOnline                                  #
# Install-Module -Name AzureAD                             #
#                                                          #
############################################################

###Global Variables###
#if there is restructure of the OU tree this variable needs to be updated
$global:dn = "OU= ,OU= ,DC= ,DC= ,DC= ,DC= ,DC= "
#If the azure connect server is updated change this variable
$global:azureConnectServer = "Azure Connect Server"
#Change this variable if the exchange server is updated
$global:exchangeConectURI = "http://ExchangeServer/PowerShell/"

$global:domain = "domain"

function banner(){
write-host "

 ██╗   ██╗███████╗███████╗██████╗      ██████╗██████╗ ███████╗ █████╗ ████████╗ ██████╗ ██████╗ 
 ██║   ██║██╔════╝██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗
 ██║   ██║███████╗█████╗  ██████╔╝    ██║     ██████╔╝█████╗  ███████║   ██║   ██║   ██║██████╔╝
 ██║   ██║╚════██║██╔══╝  ██╔══██╗    ██║     ██╔══██╗██╔══╝  ██╔══██║   ██║   ██║   ██║██╔══██╗
 ╚██████╔╝███████║███████╗██║  ██║    ╚██████╗██║  ██║███████╗██║  ██║   ██║   ╚██████╔╝██║  ██║
  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
                                                                                               


                                                                                                                                "
}

function Start-Sleep($seconds) {
<# 
.SYNOPSIS
creates a loading animation for the start-sleep method by using it as a function instead.

start-sleep(number of seconds)

.Example
start-sleep(10)

#>
    $doneDT = (Get-Date).AddSeconds($seconds)
    while($doneDT -gt (Get-Date)) {
        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds
        $percent = ($seconds - $secondsLeft) / $seconds * 100
        Write-Progress -Activity "Account Being Created" -Status "Creating..." -SecondsRemaining $secondsLeft -PercentComplete $percent
        [System.Threading.Thread]::Sleep(500)
    }
    Write-Progress -Activity "Account Being Created" -Status "Creating..." -SecondsRemaining 0 -Completed
}

function Get-ChildOU($distinguishedName) {
  <#
  .SYNOPSIS
  Populates an array with all of the child OUs under the $baseOU
  #>
  $baseOU = Get-ADOrganizationalUnit -Filter 'DistinguishedName -like $distinguishedName' | Select Name,DistinguishedName
  $childOU = Get-ADOrganizationalUnit -Filter * -SearchBase $baseOU.DistinguishedName.ToString() -SearchScope OneLevel | Select Name,DistinguishedName
  $OUArray = [System.Collections.ArrayList]@($baseOU)
  
  #adds each child of "Current Branch OU" to OUArray
  foreach ($ou in $childOU) {
    [void]$OUArray.Add($ou)
  }

  return $OUArray
}

function Input-UserInfo(){
<#
Prompts and formats all user info variables required to correct an ADUser, prompts the user to see if a like user is required.
#>
banner
$userChoice = ""

#Input for users first name
$global:firstName = Read-Host -Prompt "Please Specify the first name of user"
Write-Host "`n"
#Inputer users last name
$global:lastName = Read-Host -Prompt "Please Specify the last name of user"
Write-Host "`n"
$global:firstName = $global:firstName.Trim()

$global:lastName = $global:lastName.Trim()
#Add names together for friendlyName
$global:friendlyName = $global:firstName + ' '  + $global:lastName

#format first and last name strings to create sam account name
$global:samAccountName = $global:firstName[0] + $global:lastName.Substring(0, [Math]::Min($global:lastName.Length, 7))

#Create user email address
$global:emailAddress = $global:firstName + "." + $global:lastName + "@email.com"

#Get Position Title
$global:positionTitle = Read-Host -Prompt "Specify users position title"
Write-Host "`n"
$userReqCheck = Read-Host -Prompt "Please Specify 'yes' if a like user is required"
if($userReqCheck -eq "yes" -or $userReqCheck -eq 'y'){
  Write-Host "`n"
  $global:userReq = $true  
  #Get like user to copy groups off
    DO{
    $global:likeUser = Read-Host -Prompt "Specify a like user's samAccountName"
    $global:likeUser = $global:likeUser.Trim()

        if($global:likeUser.Length -gt 8){
           
            $likefirstName,$likelastName = $global:likeUser.split(' ')

            $global:likeUser = $likefirstName[0] + $likelastName.Substring(0, [Math]::Min($likelastName.Length, 7))
        }

    $likeUsertest = Get-ADUser -Identity $global:likeUser
    } Until ($likeUsertest -ne $null)
} else {
$global:userReq = $false
}
}

function Select-OU(){
<#
.SYNOPSIS
Prompts for an OU in which the user will be created to be selected, loops through all OUs and outputs a list to be selected from.
Selecting the option 0 selects that option.
#>
Clear-Host
banner
Write-Host "Please select the OU for where the user will be created. `n"

#When User specifies 0
Do {
  #Calls Get childOU function to get "Current Branch" Children  
  $temporaryArray = Get-ChildOU -distinguishedName $global:dn
   
  #Loop through OUs and format display for user 
  $i = 0
  foreach ($ou in $temporaryArray) {
    Write-Host $i - $ou.Name `n
    $i ++
  }
  
  #Users Choice specifies what index is used as $dn
  $userChoice = Read-Host -Prompt "`nChoose One"
  Write-Host "`n"
  $global:dn = $temporaryArray[$userChoice].DistinguishedName
        
} Until ($userChoice -eq 0)

#Check OU path
Write-Host "User will be created in this OU `n`n$dn"
Start-Sleep(2)
}

function Review-UserInfoOU(){
<#
.SYNOPSIS
Prints all of the fields that will be written to in the Input-UserInfo function to be reviewed
#>
Clear-Host
banner
Write-Host "`nPlease Review all entered information."
Write-Host "`n`nThe users full name is: $global:friendlyname"
Write-Host "`nThe users first name is: $global:firstName"
Write-Host "`nThe users last name is: $global:lastName"
Write-Host "`nThe users position title is: $global:positionTitle"
Write-Host "`nThe users samAccountName is: $global:samAccountName"
Write-Host "`nThe user will be created in the: $dn OU"
}

function Set-LikeUser(){
<#
.SYNOPSIS
If a likeuser was required this function gets the properties for the department/company/office and copies the likeusers groups to the newly created user.
#>
  #Copy user groups 
  Get-ADUser -Identity $global:likeUser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $global:samAccountName -PassThru | Select-Object -Property SamAccountName
  #Get User Properties
  $department = (Get-ADuser -Identity $global:likeUser -Properties department).department
  $company = (Get-ADuser -Identity $global:likeUser -Properties company).company
  $office = (Get-ADuser -Identity $global:likeUser -Properties office).office
  #set user properties
  Set-ADUser -Identity $global:samAccountName -Department $department -Company $company -Office $office
}

function Test-Cred(){
<#
.SYNOPSIS
Validates credentials used to connect to the exchange server, neccessary as the Get-Credential method does not allow for incorrect passwords.
#>
$credsVerified = $false
Do {
    $cred = Get-Credential #Read credentials
        $username = $cred.username
        $password = $cred.GetNetworkCredential().password

 # Get current domain using logged-on user's credentials
 $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
 $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

if ($domain.name -eq $null){
    write-host "Authentication failed - please verify your username and password."
}
else {
    write-host "Successfully authenticated with domain $domain.name"
    $credsVerified = $true
}

} Until ($credsVerified -eq $true)
return $cred
}

function Create-FDrive($username){
<#
.SYNOPSIS
Creates the users FDrive and adds all of the security required for that folder, takes the username parameter of a samaccountname and uses it to name the folder
#>
  $fDriveReq = $false
  $fDriveCheck = Read-host -Prompt "`nPlease specify 'yes' if you'd like to add a F Drive"
  if($fDriveCheck -eq 'yes' -or $fDriveCheck -eq 'y'){
  Do {
  #Path for user folder
  $Path = "\\$global:domain\files\User"


  #create new folder
  New-Item -Name $username.ToUpper() -Path $Path -ItemType Directory

  #Create access
  $acl  = Get-Acl "$path\$username"
  #The most painful part of powershell ever.
  $ace1 = New-Object Security.AccessControl.FileSystemAccessRule ("$global:domain\$username", 'Modify', 'ContainerInherit, ObjectInherit', 'InheritOnly', 'Allow')
  $ace2 = New-Object Security.AccessControl.FileSystemAccessRule ("$global:domain\$username", @('ReadandExecute', 'Write','DeleteSubdirectoriesAndFiles'), 'None', 'None', 'Allow')
  
  $acl.AddAccessRule($ace1)
  $acl.AddAccessRule($ace2)

  #Set access
  Set-Acl -AclObject $acl "$path\$username"
  $fDriveReq = $true
  } Until ($fDriveReq -eq $true)
}

function Create-Mailbox(){
<#
.SYNOPSIS
Creates the users mailbox and prompts for which mail database to use. Uses the credentials from the Test-Cred function to create a session with the exchange shell.
#>
#Authentication to Exchange Server
#start PS session with exchange server in order to execute Exchange shell CMDLETS
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $exchangeConectURI -Credential $UserCredential -Authentication Kerberos
Import-PSSession $Session -DisableNameChecking

$correctMB = $false
Do{
#Load database objects into the array
$mailboxArray = (Get-MailboxDatabase)
Clear-host
banner
#Create a selection menu
Write-host "Select a Mailbox Database `n"
$i = 0
foreach ($database in $mailboxArray){
    Write-Host $i - $database.Name `n
    $i ++
  }

$MBChoice = Read-Host -Prompt "Select database"  
$mailboxDatabase = $mailboxArray[$MBChoice].Name
Write-host "`n"
Write-Host "$mailboxDatabase has been selected"
$MBCheck = Read-Host -Prompt "`nPlease specify 'yes' if $mailboxDatabase is the database you'd like to select"
if ($MBCheck -eq 'yes' -or $MBCheck -eq 'y') {
#User is already created, so a mailbox needs to be enabled
Enable-Mailbox -Identity $emailAddress -Alias $global:samAccountName -Database $mailboxDatabase
Write-Host "$mailboxDatabase has been finalised as the database"
$correctMB = $true
}
} until ($correctMB -eq $true)

#Add the sip email address to the mailboxes other addresses
$mbx = Get-Mailbox $global:samAccountName
$mbx.EmailAddresses +="SIP:$emailAddress"
Set-Mailbox $global:samAccountName -EmailAddresses $mbx.EmailAddresses

#Only a limited number of sessions can be open so it needs to be closed
Remove-PSSession $Session
}

function Set-UserProperties() {
<#
.SYNOPSIS
If a user does not have a like user this function provides options to select a department and office.
#>
Clear-Host
$officeArray = get-aduser -Properties office -Filter * -SearchBase $dn | select office -ExpandProperty office | sort | get-unique
$i = 0
foreach ($office in $officeArray){
    Write-Host $i - $office `n
    $i++
}

$OffChoice = Read-Host -Prompt "Select the office suitable for the user"
$office = $officeArray[$OffChoice]

Clear-host
$departmentArray = get-aduser -Properties department -Filter * -SearchBase $dn | select department -ExpandProperty department | sort | get-unique
$i = 0
foreach ($department in $departmentArray){
    Write-Host $i - $department `n
    $i++
}

$depChoice = Read-Host -Prompt "Select the department suitable for the user"
$department = $departmentArray[$depChoice]

$company = "Your company name"

Set-ADUser -Identity $global:samAccountName -Department $department -Company $company -Office $office
}

function Assign-365License(){
<#
.SYNOPSIS
Connects to microsoft online and assigns a 365 Enterprise pack license
#>
Clear-Host
banner
Write-Host "Does the user require an Office 365 License?`n`nPlease be aware that assigning a license will ask you to log in to verify AzureAD Services`n`nUSE YOUR ADMIN ACCOUNT" `n`n
$365Check = Read-Host -Prompt "Please specify 'yes' if the user requires a 365 license"
if($365Check -eq 'yes' -or $365Check -eq 'y'){
    Connect-MsolService

    Set-MsolUser -UserPrincipalName $emailaddress -UsageLocation "AU"
    Set-MsolUserLicense -UserPrincipalName $emailaddress -AddLicenses "365 License Type"
}

}

function Sync-Azure(){
<#
.SYNOPSIS
Invokes a delta sync on the azure connect server to sync the newly created account so a license can be assigned.
#>
Invoke-Command -ComputerName $azureConnectServer -ScriptBlock {
    Import-Module adsync
    Start-ADSyncSyncCycle -PolicyType Delta
}
}

function Check-Phone() {
<#
.SYNOPSIS
Prompts if a phone extension is required for the user profile and provides and option to review input
#>
$extVerified = $false
$phoneReq = Read-Host -Prompt "`nPlease specify 'yes' if you'd like to add a phone extension"
    if($phoneReq -eq 'yes' -or $phoneReq -eq 'y'){
    Do {
    
        $phones = Get-aduser -Identity $global:samAccountName -Properties ipphone,homephone,officephone
        $global:extNumber = Read-Host -Prompt "`nPlease enter a four digit extension"
        $phones.ipphone = $global:extNumber
        $phones.homephone = "(02) XXXX $global:extNumber"
        $phones.officephone = "+61XXXXX$global:extNumber"
        $phones.fax = "(02) XXXX XXXX"

        Write-host "The current extension number is $global:extNumber"
        $reviewcheck = Read-Host -Prompt "`nPlease specify 'yes' if the extension number $global:extNumber is correct"
        if($reviewCheck -eq 'yes' -or $reviewCheck -eq 'y') {
            Set-ADUser -Instance $phones
            Write-Host "`n$global:samAccountName has been assigned an extension of $global:extNumber"
            $extVerified = $true
            Start-Sleep(3)
}

} until ($extVerified -eq $true)
}
}

function User-CreatedBanner(){
Clear-Host
Write-Host '


 __    __                                       ______                                   __                      __  __  __ 
/  |  /  |                                     /      \                                 /  |                    /  |/  |/  |
$$ |  $$ |  _______   ______    ______        /$$$$$$  |  ______    ______    ______   _$$ |_     ______    ____$$ |$$ |$$ |
$$ |  $$ | /       | /      \  /      \       $$ |  $$/  /      \  /      \  /      \ / $$   |   /      \  /    $$ |$$ |$$ |
$$ |  $$ |/$$$$$$$/ /$$$$$$  |/$$$$$$  |      $$ |      /$$$$$$  |/$$$$$$  | $$$$$$  |$$$$$$/   /$$$$$$  |/$$$$$$$ |$$ |$$ |
$$ |  $$ |$$      \ $$    $$ |$$ |  $$/       $$ |   __ $$ |  $$/ $$    $$ | /    $$ |  $$ | __ $$    $$ |$$ |  $$ |$$/ $$/ 
$$ \__$$ | $$$$$$  |$$$$$$$$/ $$ |            $$ \__/  |$$ |      $$$$$$$$/ /$$$$$$$ |  $$ |/  |$$$$$$$$/ $$ \__$$ | __  __ 
$$    $$/ /     $$/ $$       |$$ |            $$    $$/ $$ |      $$       |$$    $$ |  $$  $$/ $$       |$$    $$ |/  |/  |
 $$$$$$/  $$$$$$$/   $$$$$$$/ $$/              $$$$$$/  $$/        $$$$$$$/  $$$$$$$/    $$$$/   $$$$$$$/  $$$$$$$/ $$/ $$/ 
                                                                                                                            
                                                                                                                                                                                                                                                                                              
                                                                                                                    
                                                                                                                    

'}

function ReviewUserInfoOULoop(){
<#
.SYNOPSIS
Reviews the information provided in the input-userinfo and loops enabling the information to be verified
#>
$reviewBoolean = $false
clear-host
Input-UserInfo
Select-OU
Do {
Review-UserInfoOU
$reviewCheck = Read-Host -Prompt "`n`nPlease specify 'yes' if all details are correct"
if($reviewCheck -eq 'yes' -or $reviewCheck -eq 'y'){
    New-ADUser -Name $global:friendlyName -Path $global:dn -DisplayName $global:friendlyName  -SamAccountName $global:samAccountName.ToLower() -GivenName $global:firstName -Surname $global:lastName.ToUpper() -UserPrincipalName $global:emailAddress -Description $global:positionTitle -Title $global:positionTitle -AccountPassword (ConvertTo-SecureString -AsPlainText "Apples2020" -Force) -Enabled $true -ChangePasswordAtLogon $true
    $reviewBoolean = $true
} else {
    clear-host
    Input-UserInfo
    Select-OU
    Review-UserInfoOU
}
} Until ($reviewBoolean -eq $true)
}


ReviewUserInfoOULoop
if($global:userReq -eq $true){
Set-LikeUser
} else {
Set-UserProperties
}
$UserCredential = Test-Cred
Create-Mailbox
Start-Sleep(10)
Create-FDrive -username $global:samAccountName
Sync-Azure
Assign-365License
Check-Phone
User-CreatedBanner

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



###############################################
#                                             #n
#               Credits:                      #
#                John L                       #
#                Jono M                       #
#                                             #
###############################################
