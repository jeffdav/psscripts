Function Write-Menu {
    param([Array] $Items)

    $Index = 0
    $Items | ForEach-Object -Process {
        if ($Index -lt 10) {
            $Item = " $($Index): "
        } else {
            $Item = "$($Index): "
        }

        if ($Index -eq $SelectedItem) {
            $Item += "* "
        } else {
            $Item += "  "
        }

        $Item += $_

        $Padding = " " * ($LineLength - $_.Length)
        if ($Index -eq $CurrentItem) {
            Write-Host -ForegroundColor Black -BackgroundColor White "$($Item + $Padding)"
        } else {
            Write-Host -ForegroundColor White "$($Item + $Padding)"
        }
        $Index++
    }
    Write-Host -ForegroundColor Green " ↑↓: Move, ↩: Switch, m: main!, d: Delete, D: Delete!, Q or Esc: Quit"
}

Function Set-CurrentBranch {
    # There is a slight delay, so print something to comfort the user.
    Write-Host -ForegroundColor Green "Switching..."
    $SelectedItem = $CurrentItem

    # Redraw the list with the '*' on the new selection.
    $CursorTop = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition(0, $CursorTop - $Items.Length - 2)
    Write-Menu -Items $Items

    git checkout "$($Items[$CurrentItem])"
    exit
}

Function Watch-InputForMenu {
    param([Array] $Items)

    # Bug in powershell requires this first one to be KeyDown
    # because KeyUp gets a supurious enter key the first time.
    $Key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    while($Key.VirtualKeyCode -ne 81) {
        $ShiftPressed = $Key.ControlKeyState.HasFlag([System.Management.Automation.Host.ControlKeyStates]::ShiftPressed)
        switch($Key.VirtualKeyCode) {
            # Enter
            13 {
                Set-CurrentBranch
            }

            # Escape
            27 {
                exit
            }

            # Up / K
            { $_ -in 38, 75 } {
                if ($CurrentItem -gt 0) {
                    $CurrentItem--
                }
            }

            # Down / J
            { $_ -in 40, 74 } {
                if ($CurrentItem -lt $Items.Length - 1) {
                    $CurrentItem++
                }
            }

            # 0-9
            { $_ -in 48..57 } {
                $Target = $_ - 48
                if ($Target -lt $Items.Length) {
                    $CurrentItem = $Target
                }
            }

            # Numpad 0-9
            { $_ -in 96..105 } {
                $Target = $_ - 96
                if ($Target -lt $Items.Length) {
                    $CurrentItem = $Target
                }
            }

            # D
            68 {
                if ($CurrentItem -eq $SelectedItem) {
                    # Can't delete the current branch.
                    break
                } elseif ($ShiftPressed) {
                    Write-Host -ForegroundColor Red "Force deleting..."
                    git branch -D "$($Items[$CurrentItem])"
                } else {
                    Write-Host -ForegroundColor Red "Deleting..."
                    git branch -d "$($Items[$CurrentItem])"
                }
                exit
            }

            # M
            77 {
                $CurrentItem = $Items.IndexOf("main")
                Set-CurrentBranch
            }
        }

        $CursorTop = [System.Console]::CursorTop
        [System.Console]::SetCursorPosition(0, $CursorTop - $Items.Length - 1)
        Write-Menu -Items $Items

        $Key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyUp')
    }
}

Function Show-Menu {
    param(
        [Parameter(Mandatory)]
        [Array] $Items
    )

    Write-Menu -Items $Items
    Watch-InputForMenu -Items $Items
}

# Global state. Yee-haw!
$CurrentItem = 0
$SelectedItem = 0
$BranchArray = @()
$LineLength = 0

# Preprocess the branches to trim extra characters and initialize state.
$Index = 0
git branch | ForEach-Object -Process {
    if ($_.StartsWith("*")) {
        $CurrentItem = $Index
        $SelectedItem = $Index
    }
    $Item = $_.Trim('* ')
    $BranchArray += $Item

    if ($Item.Length -gt $LineLength) {
        $LineLength = $Item.Length + 1
    }

    $Index++
}

# If `git branch` failed, bail.  Git will print an error.
if (-not $?) {
    exit
}

# Write enough blank lines to give us room to print the list, plus one extra.
# This stops drawing issues when the terminal is at the bottom and printing
# the list would scroll the screen.
$TotalLines = $BranchArray.Count + 2
for ($i = 0; $i -lt $TotalLines; $i++) {
    Write-Host
}
$CursorTop = [System.Console]::CursorTop
[System.Console]::SetCursorPosition(0, $CursorTop - $TotalLines)

Show-Menu -Items $BranchArray
