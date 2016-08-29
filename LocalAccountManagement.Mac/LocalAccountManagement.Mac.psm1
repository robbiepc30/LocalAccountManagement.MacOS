function Get-LocalUser {
    [CmdletBinding()]
    Param(
        [String]$Name = '*'
    )
    Process 
    {
        Write-Verbose "Retrieving local user accounts"
        $userPlist= ([xml](dscl -plist .   readall /Users RecordName RealName UniqueID NFSHomeDirectory)).plist.array.dict

        foreach ($up in $userPlist) 
        {
            $userHashTable = @{}
            $up.key | ForEach-Object -Begin { $i = 0 } -Process { $userHashTable.Add($_.Split(':')[1], $up.array[$i].string); $i++ }

            $user =  [PSCustomObject] @{ Name          = if ($userHashTable.RecordName.count -gt 1) { $userHashTable.RecordName[0]} else { $userHashTable.RecordName }
                                         DisplayName   = $userHashTable.RealName
                                         UID           = $userHashTable.UniqueID
                                         HomeDirectory = $userHashTable.NFSHomeDirectory }
            # If user matches search criteria then return user object
            # It would be more efficient if I could figure out a way to do a wildcard search using dscl 
            #  rather then importing all users, creating objects, and then checking if the name matcehs
            if ($user.Name -like $Name) { 
                $user
            }
        } 
    }
}

function New-LocalUser {
    [CmdletBinding(SupportsShouldProcess=$true,
                   confirmImpact='Medium')]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
        [String]$DisplayName,
        [Parameter(Mandatory=$True)]
        [String]$Password,
        [String]$Hint,
        [String]$PicturePath,
        [Switch]$Admin
    )
    Process 
    {
        If ($psCmdlet.shouldProcess((hostname), "New-LocalUser: Account(s): $Name"))
        {
            foreach($N in $Name)
            {
                Write-Verbose "Creating user `"$N`""
                [int]$maxUID = dscl . list /Users UniqueID | awk '$2>m{m=$2}END{print m}'
                $nextUID = $maxUID + 1

                dscl . create /Users/$N
                dscl . create /Users/$N RealName $DisplayName
                dscl . create /Users/$N hint $Hint
                dscl . passwd /Users/$N $Password
                dscl . create /Users/$N UniqueID $nextUID
                if ($Admin) {
                    dscl . create /Users/$N PrimaryGroupID 80 # Admin Group
                }
                else {
                    dscl . create /Users/$N PrimaryGroupID 20 # Standard User Staff Group
                }
                dscl . create /Users/$N picture $PicturePath
                dscl . create /Users/$N UserShell /bin/bash
                dscl . create /Users/$N NFSHomeDirectory /Users/$N
                Copy-Item -Path "/System/Library/User Template/English.lproj" -Destination /Users/$N
                chown -R "$($N):staff" /Users/$N
            }
        }
    }
    # Ref: http://apple.stackexchange.com/questions/82472/what-steps-are-needed-t create-a-new-user-from-the-command-line
}

function Remove-LocalUser {
    [CmdletBinding(SupportsShouldProcess=$true,
                   confirmImpact='High')]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
        [Switch]$Force
    )
    Begin
    {
        if ($Force) { $ConfirmPreference = 'None' }
    }
    Process 
    {
        If ($psCmdlet.shouldProcess((hostname), "Remove-LocalUser: Account(s): $Name"))
        {
            foreach($N in $Name)
            {
                Write-Verbose "Removing user `"$N`""
                dscl . delete /Users/$N
            }
        }
    }
}   

function Remove-LocalUserProfile {
    [CmdletBinding(SupportsShouldProcess=$true,
                   confirmImpact='High')]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
        [Switch]$Force
    )
    Begin
    {
        if ($Force) { $ConfirmPreference = 'None' }
    }
    Process 
    {
        If ($psCmdlet.shouldProcess((hostname), "Remove-LocalUserProfile: Account(s): $Name"))
        {
            foreach($N in $Name)
            {
                Write-Verbose "Removing user `"$N`" home folder from /Users/$N"
                Remove-Item -Recurse -Force -Path /Users/$N
            }
        }
    }
}