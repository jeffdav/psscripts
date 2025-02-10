# psscripts
My powershell scripts.

## BranchManager.ps1
A simple command line text UI for switching branches.

![image](https://github.com/jeffdav/psscripts/assets/2266946/9bd2f177-e10d-4b8d-b7c8-02a62b0a436d)

Add this to your `~/.gitconfig`:
```
[alias]
        bm = !pwsh.exe C:/PATH/TO/psscripts/BranchManager.ps1
```
Then just type:
```pwsh
PS > git bm
```

## Show-TreeStructure.ps1
A replacement for the builtin DOS `TREE` command.

![image](https://github.com/user-attachments/assets/a9e07f00-fccf-4b00-8350-499e40e782b2)

Add this to your `$PROFILE` file:
```pwsh
. "$(Join-Path (Split-Path $PROFILE) Show-TreeStructure.ps1)"
Set-Alias -Name tree -Value Show-TreeStructure
```

```pwsh
NAME
    Show-TreeStructure

SYNTAX
    Show-TreeStructure [[-Depth] <int>] [-Path <string>] [-ShowFiles] [-LeafFilesOnly]  [<CommonParameters>]
```

- Colorizes by depth.
- Allows specifying depth.
- Options to show files.
