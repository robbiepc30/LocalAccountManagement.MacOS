function Get-LocalUser {
    $userList = dscl . list /Users | grep -v '^_'
    foreach ($u in $userList) {
        $detailedUserInfo = dscl . -read /Users/$u 
        New-Object PSCustomObject -Property @{ Name=$u
                                               DisplayName = $detailedUserInfo | grep 'RealName' | awk '{print $2}'
                                               UniqueID = $detailedUserInfo | grep 'UniqueID' | awk '{print $2}'
                                               HomeDirectory = $detailedUserInfo | grep 'NFSHomeDirectory' | awk '{print $2}'
                                              }
    }
}

function test {
    $userPlist= ([xml](dscl -plist .   readall /Users RecordName RealName UniqueID NFSHomeDirectory)).plist.array.dict

    foreach ($up in $userPlist) {
        $userHashTable = @{}
        $up.key | ForEach-Object -Begin {$i = 0} -Process { $userHashTable.Add($_.Split(':')[1], $up.array[$i].string); $i++}
        #$userHashTable
        [PSCustomObject] @{ Name = $userHashTable.RecordName
                            DisplayName = $userHashTable.RealName
                            UID = $userHashTable.UniqueID
                            HomeDirectory = $userHashTable.NFSHomeDirectory }
    }

}

function test2 {
    $userList = dscl -plist . list /Users RecordName RealName UniqueID NFSHomeDirectory

    foreach ($up in $userList) {
       [PSCustomObject] @{ Name = $userHashTable.RecordName
                                               DisplayName = $userHashTable.RealName
                                               UID = $userHashTable.UniqueID
                                               HomeDirectory = $userHashTable.NFSHomeDirectory }
    }

}