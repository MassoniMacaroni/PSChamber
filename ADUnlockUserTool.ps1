#Creates the AccountArray and populates it with locked out objects
$AccountArray = @(search-adaccount -lockedout)
#Initialises index at 0
$Index = 0

#For the aesthetic 
clear-host

#Loops through array
foreach ($account in $AccountArray) {
    #Prints Index and relative hostname on screen
    write-host "`n" $Index - $Account.Name
    #Increments Index
    $Index ++
}



if($AccountArray.Length -lt 1) {
    #Print message if no  accounts are locked
    Write-Host "No accounts available to be unlocked"

}else{
    #Input for the index reference value used to determine which account to unlock
    $IndexRef = Read-host -Prompt "`nSelect Account No. to unlock" 
    #Unlocks the specified AD account from Index Ref value
    Unlock-ADAccount -identity $AccountArray[($IndexRef)]
    #Print account unlocked
    Write-host "`n" $AccountArray[($IndexRef)].name "has been unlocked. `n"

}

#Press any key to continue
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
