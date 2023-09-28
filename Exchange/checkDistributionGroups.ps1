# Connect to Exchange Online
Connect-ExchangeOnline

# Specify the user's email address
$userEmail = "USER_EMAIL_ADDRESS"

# Get all distribution groups in your organization
$groups = Get-DistributionGroup -ResultSize Unlimited

# Loop through each distribution group and check if the user is a member
foreach ($group in $groups) {
    $groupMembers = Get-DistributionGroupMember -Identity $group.Identity
    foreach ($member in $groupMembers) {
        if ($member.PrimarySmtpAddress -eq $userEmail) {
            Write-Host "$userEmail is a member of $($group.DisplayName)"
        }
    }
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline
