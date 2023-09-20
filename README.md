# psscripts
My powershell scripts.

## BranchManager.ps1
A simple command line text UI for switching branches.

Add this to your `~/.gitconfig`:
```
[alias]
        bm = !pwsh.exe C:/PATH/TO/psscripts/BranchManager.ps1
```
Then just type:
```
PS > git bm
```
