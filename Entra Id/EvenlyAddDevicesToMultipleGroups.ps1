# Path to CSV with ObjectIDs
$data = Import-Csv -Path "CSV HERE"

#extracts the objectId column from the CSV data and stores it in the $columnData variable
$columnData = $data.objectId

# The number of devices in the CSV file is determined by counting the number of elements in the $columnData array using the Count
$deviceCount = $columnData.Count
$count = $deviceCount

# The number of groups to add the devices to is determined by counting the number of elements in the $groups array using the Count
$groups = "objectID1","objectID2","objectID3","objectID4"
$groupCount = $groups.count

# The for loop iterates through the $columnData array and adds each device to the group specified by the $groups array
for($i = 0; $i -lt $count; $i++){
  # The modulus operator (%) is used to determine which group to add the device to  
  add-AzureAdgroupmember -objectid $($groups[$i%$groupCount]) -refobjectid $($columnData[$i])
}

