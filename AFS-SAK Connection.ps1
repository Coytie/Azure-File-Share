# Change First
$DriveLetter = "O"
$ConnectAFSDriveTask = "ConnectAzureFileShare_" + $DriveLetter

# This will check that the machine is joined to the AzureAD tenancy - 3 requirements must be met otherwise it will delete the key and the drive if it exists.
# This is to get around the machine not being joined to AzureAD and if it is, it must match the name and id of the tenancy.
$AADJ = (dsregcmd /status | select-string "AzureAdJoined")
$TenName = (dsregcmd /status | select-string "TenantName")
$TenID = (dsregcmd /status | select-string "TenantId")

if (($AADJ -match "YES") -and ($TenName -match "Company Name Pty Ltd") -and ($TenID -match "Tenant-ID-of-Company-Name")) {
    cmd.exe /C "cmdkey /add:`"companyname.file.core.windows.net`" /user:`"localhost\storagename`" /pass `"the storage access key pass this is used for the connection share`""
} else {
    cmd.exe /C 'cmdkey /delete:"companyname.file.core.windows.net"'
    cmd.exe /c 'net use O: /delete' #change the letter before :
    exit
}

function Test-Administrator {
    $User = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

$ScriptDirectory = $env:APPDATA + "\Intune"
# Check if directory already exists.
if (!(Get-Item -Path $ScriptDirectory)) {
    New-Item -Path $env:APPDATA -Name "Intune" -ItemType "directory"
}

# Logfile
$ScriptLogFilePath = $ScriptDirectory + "\ConnectAzureFileShare.log"

if (Test-Administrator) {
    # If running as administrator, create scheduled task as current user.
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + "Running as administrator.")

    $ScriptFilePath = $ScriptDirectory + "\ConnectAzureFileShare_" + $DriveLetter + ".ps1"

    $Script = '<input Azure File Share connection script between the ' '>'

    $Script | Out-File -FilePath $ScriptFilePath

    $PSexe = Join-Path $PSHOME "powershell.exe"
    $Arguments = "-file $($ScriptFilePath) -WindowStyle Hidden -ExecutionPolicy Bypass"
    $CurrentUser = (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object -expand UserName)
    $Action = New-ScheduledTaskAction -Execute $PSexe -Argument $Arguments
    $Principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object -expand UserName)
    $Trigger = New-ScheduledTaskTrigger -AtLogOn -User $CurrentUser
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal

    Register-ScheduledTask $ConnectAFSDriveTask -Input $Task
    Start-ScheduledTask $ConnectAFSDriveTask
}

Else {
    # Not running as administrator. Connecting directly with Azure script.
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + "Not running as administrator.")

    <input Azure File Share connection script>
}

If (Get-PSDrive -Name O) {
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + $DriveLetter + "-Drive mapped successfully.")
}

Else {
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + "Please verify installation.")
}
