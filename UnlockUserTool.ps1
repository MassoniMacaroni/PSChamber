$AccountArray = @(search-adaccount -lockedout)
$Index = 0

clear-host

foreach ($account in $AccountArray) {
    write-host $Index - $Account.Name
    $Index ++
}

$IndexRef = Read-host -Prompt "Select Account No. to unlock"
Unlock-ADAccount -identity $AccountArray[($IndexRef)]