$UserList = import-csv 'File Path' 

ForEach ($Username in $UserList) {
    $User = Get-ADUser $Username -properties pwdLastSet
    Set-ADUser -Identity $User -PasswordNeverExpires:$False
    
    Write-Host "Processing "$User -ForegroundColor Yellow
	$User.pwdLastSet = 0
	Set-ADUser -Instance $User -Server 'Server Name'
	$User.pwdLastSet = -1
	
    Write-Host "Processed "$User -ForegroundColor Green
    Set-ADUser -ChangePasswordAtLogon:$true
    }
