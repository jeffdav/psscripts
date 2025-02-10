function Show-TreeStructure {
    [CmdletBinding(PositionalBinding=$False)]
    param(
        [Parameter(Position=0)]
        [int] $Depth = [int]::MaxValue,
        [string] $Path = ".",
        [switch] $ShowFiles,
        [switch] $LeafFilesOnly
    )

    # Define colors to rotate through for different depths
    $Colors = @(
        "Yellow",
        "Cyan",
        "Green",
        "Magenta",
        "Blue",
        "Red"
    )

    function Write-TreeItem {
        param(
            [string] $Prefix,
            [string] $Item,
            [int] $CurrentDepth,
            [bool] $IsDirectory
        )
        
        # Write the prefix in bright white
        Write-Host $Prefix -ForegroundColor White -NoNewline
        
        # Write the item name in the color corresponding to its depth
        $ColorIndex = $CurrentDepth % $Colors.Length
        Write-Host $Item -ForegroundColor $Colors[$ColorIndex]
    }

    function Show-SubTree {
        param(
            [string] $CurrentPath,
            [string] $Prefix,
            [int] $CurrentDepth = 0
        )

        if ($CurrentDepth -gt $Depth) {
            return
        }

        # Get directories first
        $Directories = Get-ChildItem -Path $CurrentPath -Directory | Sort-Object Name

        # Get files if requested and if we're either showing all files or this is a leaf directory
        $Files = @()
        if ($ShowFiles) {
            $ShouldShowFiles = -not $LeafFilesOnly -or ($Directories.Count -eq 0)
            if ($ShouldShowFiles) {
                $Files = Get-ChildItem -Path $CurrentPath -File | Sort-Object Name
            }
        }

        # Process all items
        $TotalItems = $Directories.Count + $Files.Count
        for ($ItemIndex = 0; $ItemIndex -lt $TotalItems; $ItemIndex++) {
            $IsLast = ($ItemIndex -eq $TotalItems - 1)
            $CurrentItem = if ($ItemIndex -lt $Directories.Count) { 
                $Directories[$ItemIndex] 
            } else { 
                $Files[$ItemIndex - $Directories.Count] 
            }
            $IsDirectory = $ItemIndex -lt $Directories.Count

            # Determine the current line's prefix and the prefix for children
            $CurrentPrefix = if ($IsLast) { "$Prefix$([char]0x2514)$([char]0x2500)$([char]0x2500) " } else { "$Prefix$([char]0x251C)$([char]0x2500)$([char]0x2500) " }
            $ChildPrefix = if ($IsLast) { "$Prefix    " } else { "$Prefix$([char]0x2502)   " }

            # Write the current item
            Write-TreeItem -Prefix $CurrentPrefix -Item $CurrentItem.Name -CurrentDepth $CurrentDepth -IsDirectory $IsDirectory

            # Recursively process directories
            if ($IsDirectory) {
                Show-SubTree -CurrentPath $CurrentItem.FullName -Prefix $ChildPrefix -CurrentDepth ($CurrentDepth + 1)
            }
        }
    }

    # Resolve and verify path
    $ResolvedPath = Resolve-Path $Path
    if (-not (Test-Path $ResolvedPath)) {
        Write-Error "Path not found: $Path"
        return
    }

    # Get and display the root directory name
    $RootItem = Get-Item $ResolvedPath
    Write-TreeItem -Prefix "" -Item $RootItem.Name -CurrentDepth 0 -IsDirectory $true

    # Start the recursive display
    Show-SubTree -CurrentPath $ResolvedPath -Prefix "" -CurrentDepth 1
}
