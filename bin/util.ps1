function move_link {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Origin,
        [ValidateNotNullOrEmpty()]
        [string]$Target,

        [ValidateNotNullOrEmpty()]
        [Parameter(HelpMessage = "file or directory")]
        [ValidateSet("File", "Directory")]
        [string]$Type = "Directory"
    )
    if ($Origin -eq $Target) {
        return
    }

    $old = Test-Path $Origin
    $new = Test-Path $Target

    $itemType = ''
    if (is_admin) {
        $itemType = 'SymbolicLink'
    } else {
        if ($Type -eq "File") {
            if (same_drive -origin $Origin -target $Target) {
                $itemType = 'HardLink'
            } else {
                error "make symbolic link $Origin => $Target need admin rights"
                break
            }
        } else {
            $itemType = "Junction"
        }
    }

    if ($old) {
        $data = (Get-Item $Origin -force | Select-Object LinkType, target)
        if ($data.LinkType -in ("SymbolicLink", "Junction")) {
            if ($data.Target -eq $Target ) {
                return
            } else {
                error ("$Origin exist, but target is " + $data.LinkType + "(" + $data.Target + "). need $Target")
                exit
            }
        }

        if ($new) {
            error "$Target exist, you need manual move data"
            exit
        } else {
            INFO "move $Origin to $Target"
            Move-Item -Path $Origin -Destination $Target
        }
    } else {
        if (!$new) {
            New-Item -Path $Target -ItemType $Type -Force | Out-Null
        }
    }
    New-Item -Path $Origin -ItemType $itemType -Value $Target | Out-Null
}

function move_or {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Origin,
        [ValidateNotNullOrEmpty()]
        [string]$Target,

        [ValidateNotNullOrEmpty()]
        [Parameter(HelpMessage = "file or directory")]
        [ValidateSet("File", "Directory")]
        [string]$Type = "Directory",
        [switch]$Create = $false
    )
    if ($Origin -eq $Target) {
        return
    }

    $old = Test-Path $Origin
    $new = Test-Path $Target
    if ($new) {
        return
    } elseif ($old) {
        Move-Item -Path $Origin -Destination $Target
    } else {
        if ($Create) {
            New-Item -Path $Target -ItemType $Type -Force | Out-Null
        }
    }
}

function same_drive {
    param (
        [string]$Origin,
        [string]$Target
    )
    if ($Origin.Contains(":\") -and $Target.Contains(":\")) {
        $o = Split-Path -Path $Origin -Qualifier
        $t = Split-Path -Path $Target -Qualifier
        return $o -eq $t
    }
}
