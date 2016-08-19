function Get-LocalUser {
    $userList = dscl . list /Users | grep -v '^_'
    foreach ($u in $userList) {
        $detailedUserInfo = dscl . -read /Users/$u 
        New-Object PSCustomObject -Property @{name=$u
                                              DisplayName = $detailedUserInfo | grep 'RealName' | awk '{print $2}'
                                              UniqueID = $detailedUserInfo | grep 'UniqueID' | awk '{print $2}'
                                              HomeDirectory = $detailedUserInfo | grep 'NFSHomeDirectory' | awk '{print $2}'
                                              }
    }
}
Get-LocalUser