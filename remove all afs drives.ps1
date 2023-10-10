cmdkey /list | ForEach-Object{if($_ -like "*file.core.windows.net*" -and $_ -like "*file.core.windows.net*"){cmdkey /del:($_ -replace " ","" -replace "Target:","")}}
net use * /delete /YES
Restart-Service IntuneManagementEngine -Force
