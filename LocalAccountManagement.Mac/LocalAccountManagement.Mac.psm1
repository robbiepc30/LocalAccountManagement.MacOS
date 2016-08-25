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

function New-LocalUser ($Name, $DisplayName, $Password, $Hint, [Switch]$Admin) {
    [int]$maxUID = dscl . list /Users UniqueID | awk '$2>m{m=$2}END{print m}'
    $nextUID = $maxUID + 1

    dscl . create /Users/$Name
    dscl . create /Users/$Name RealName $DisplayName
    dscl . create /Users/$Name hint $Hint
    dscl . passwd /Users/$Name $Password
    dscl . create /Users/$Name UniqueID $nextUID

    if ($Admin) {
        dscl . create /Users/$Name PrimaryGroupID 80 # Admin Group
    }
    else {
        dscl . create /Users/$Name PrimaryGroupID 20 # Standard User Staff Group
    }

    dscl . create /Users/$Name UserShell /bin/bash
    dscl . create /Users/$Name NFSHomeDirectory /Users/$Name
    Copy-Item -Path "/System/Library/User Template/English.lproj" -Destination /Users/$Name
    #cp -R "/System/Library/User Template/English.lproj" /Users/$Name  
    chown -R "$($Name):staff" /Users/$Name

    # Picture ..?
    # dscl . create /Users/administrator picture "/Path/To/Picture.png"

    # Ref: http://apple.stackexchange.com/questions/82472/what-steps-are-needed-t create-a-new-user-from-the-command-line
}

function Remove-LocalUser ($Name) {

    # Extra precaution against $Name being null
    # If $Name var was null it would read dscl . delete /Users/ and would DELETE ALL USERS!!!
    if ($Name) {
        dscl . delete /Users/$Name
    }
    
}

function Remove-LocalUserProfile ($Name) {
    Remove-Item -Recurse -Force -Path /Users/$Name
}