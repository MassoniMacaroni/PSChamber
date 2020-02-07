$UserList = import-csv \\8cc9224ppb\C$\Temp\Scripts\ExpireUserList.csv 

ForEach ($Username in $UserList) {
    $User = Get-ADUser $Username -properties pwdLastSet
    Set-ADUser -Identity $User -PasswordNeverExpires:$False
    
    Write-Host "Processing "$User -ForegroundColor Yellow
	$User.pwdLastSet = 0
	Set-ADUser -Instance $User -Server HCC-S-SRAD05
	$User.pwdLastSet = -1
	
    Write-Host "Processed "$User -ForegroundColor Green
    #Set-ADUser -ChangePasswordAtLogon:$true
    }
