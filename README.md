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
```
PS > git bm
```

