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

    if ($old) {
        $data = (Get-Item $Origin -force | Select-Object LinkType, target)
        if ($data.LinkType -in ("SymbolicLink", "Junction")) {
            if ($data.Target -eq $Target ) {
                return
            } else {
                Write-Error ("$Origin exist, but target is " + $data.LinkType + "(" + $data.Target + "), need $Target")
                exit 1
            }
        }

        if ($new) {
            Write-Error "$Target exist, you need manual move data"
            exit 1
        } else {
            INFO "move $Origin to $Target"
            Move-Item -Path $Origin -Destination $Target
        }
    } else {
        if (!$new) {
            New-Item -Path $Target -ItemType $Type -Force | Out-Null
        }
    }
    new_link $Origin $Target
}

function new_link {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Origin,
        [ValidateNotNullOrEmpty()]
        [string]$Target
    )
    try {
      New-Item -Path $Origin -ItemType 'SymbolicLink' -Value $Target -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Failed to create symbolic link ${_}"
        exit 1
    }
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
