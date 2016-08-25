function Get-LocalUser {
    $userPlist= ([xml](dscl -plist .   readall /Users RecordName RealName UniqueID NFSHomeDirectory)).plist.array.dict

    foreach ($up in $userPlist) {
        $userHashTable = @{}
        $up.key | ForEach-Object -Begin { $i = 0 } -Process { $userHashTable.Add($_.Split(':')[1], $up.array[$i].string); $i++ }

        [PSCustomObject] @{ Name = if ($userHashTable.RecordName.count -gt 1) { $userHashTable.RecordName[0]} else { $userHashTable.RecordName }
                            DisplayName = $userHashTable.RealName
                            UID = $userHashTable.UniqueID
                            HomeDirectory = $userHashTable.NFSHomeDirectory }
    }

}

function New-LocalUser ($Name) {
    [int]$maxUID = dscl . list /Users UniqueID | awk '$2>m{m=$2}END{print m}'
    $nextUID = $maxUID + 1
    
}