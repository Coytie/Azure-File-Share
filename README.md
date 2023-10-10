# AzureFileShare
This is the Azure File Share PowerShell scirpt that will check and confirm that the device is currently joined to the AzureAD domain, with confirming the Tenancy Name and Tenency ID.
</br></br>
This is still in progress and is mainly used for tenancies that are Cloud Only while Microsoft still slowly impliment their AzureAD Cloud authentication with AFS.
</br></br>
## What You'll Need To Do!

### Converting to an .exe

In order to convert the .ps1 to an .exe file, you will need to get the ps2exe module (run PowerShell as Administrator)
```
install-module ps2exe /force
import-module ps2exe
```
Once the module is installed, you can then run the module to 
```
Invoke-PS2EXE "<path to .ps1 file>\afs-drivescript.ps1" `
"<path to new .exe file>\afs-drivescript.exe" `
-company Brenden -copyright Brenden -version 1.0.0.0 -product "AFK-SAK Connector" -title "PowerShell Script"
```
Don't worry, the ` at the end of each line is to just make the line shorter, but your details will look like this!

![image](https://github.com/Coytie/Azure-File-Share/assets/100748492/852ba459-6f8a-4be9-9fed-be6a1178aab8)
</br></br>
### Changes to be made
You will need to make a few changes to the script before you convert it to an .exe.</br>
This is actually quite simple and easy to locate as its up the top and between 

```
$DriveLetter = 'Y'
$DriveRoot = 'BrendenStorageAccount.file.core.windows.net'
$DriveShare = '\all-of-the-data' #Change to your Share Drive in AFS
$CMDKey = cmd.exe /C cmdkey /add:$DriveRoot /user:localhost\BrendenStorageAccount /pass:Thisis-aPassword34234-fortheaccount52351
$TenantName = "Brendens Test Azure Tenancy"
$TenantID = "a1b2c3d4-d5e6-f71a-2b3c-4d567890abcd"
```

## Things to be updated
- Work on getting it to link with MS Graph in order for the command to
- Removal of the PS Drive once the user is offboarded or is to not have access anymore. This might need to be done via Intune.
