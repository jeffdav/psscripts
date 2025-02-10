function Show-TreeStructure {
    <#
    .SYNOPSIS
    Displays a directory structure as a colored tree with optional file listings.

    .DESCRIPTION
    Creates a visual tree representation of a directory structure using ASCII/Unicode characters
    and colors. Can show files optionally, with the ability to limit file display to leaf directories.
    Handles access denied errors gracefully.

    .PARAMETER Depth
    Maximum depth of subdirectories to display. Default is maximum possible integer value.

    .PARAMETER Path
    Starting directory path to display the tree from. Default is current directory (".").

    .PARAMETER ShowFiles
    When specified, includes files in the tree display. By default, only directories are shown.

    .PARAMETER LeafFilesOnly
    When used with -ShowFiles, only displays files in directories that contain no subdirectories.
    This helps reduce clutter in the tree display by only showing files at the "leaves".

    .EXAMPLE
    Show-TreeStructure
    Shows directory structure from current directory with default settings.

    .EXAMPLE
    Show-TreeStructure -Depth 2 -Path C:\Projects -ShowFiles
    Shows directory structure of C:\Projects, limited to 2 levels deep, including all files.

    .EXAMPLE
    Show-TreeStructure -ShowFiles -LeafFilesOnly
    Shows current directory structure with files only in leaf directories.
    #>
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
            [bool] $IsDirectory,
            [string] $ErrorMessage = ""
        )
        
        # Write the prefix in bright white
        Write-Host $Prefix -ForegroundColor White -NoNewline
        
        # Write the item name in grey if there's an error, otherwise use depth-based color
        if ($ErrorMessage) {
            Write-Host $Item -ForegroundColor DarkGray -NoNewline
            Write-Host " [$ErrorMessage]" -ForegroundColor DarkGray
        } else {
            # Write the item name in the color corresponding to its depth
            $ColorIndex = $CurrentDepth % $Colors.Length
            Write-Host $Item -ForegroundColor $Colors[$ColorIndex]
        }
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

        # Get directories first, with error handling
        $Directories = @()
        try {
            $Directories = Get-ChildItem -Path $CurrentPath -Directory -ErrorAction Stop | Sort-Object Name
        } catch {
            # Return empty array but don't display error - it will be handled when trying to display the directory
        }

        # Get files if requested and if we're either showing all files or this is a leaf directory
        $Files = @()
        if ($ShowFiles) {
            $ShouldShowFiles = -not $LeafFilesOnly -or ($Directories.Count -eq 0)
            if ($ShouldShowFiles) {
                try {
                    $Files = Get-ChildItem -Path $CurrentPath -File -ErrorAction Stop | Sort-Object Name
                } catch {
                    # Return empty array but don't display error
                }
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
            $ErrorMsg = ""
            if ($IsDirectory) {
                # Try to test access to the directory
                try {
                    $null = Get-ChildItem -Path $CurrentItem.FullName -ErrorAction Stop
                } catch {
                    $ErrorMsg = "Access Denied"
                }
            }

            Write-TreeItem -Prefix $CurrentPrefix -Item $CurrentItem.Name -CurrentDepth $CurrentDepth -IsDirectory $IsDirectory -ErrorMessage $ErrorMsg

            # Recursively process directories (only if no access error)
            if ($IsDirectory -and -not $ErrorMsg) {
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
