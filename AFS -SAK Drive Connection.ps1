#Change Below
$DriveLetter = 'O'
$DriveRoot = 'ahhazaesa01.file.core.windows.net'
$DriveShare = '\o-drive-test\test1'
$CMDKey = cmd.exe /C "cmdkey /add:ahhazaesa01.file.core.windows.net /user:localhost\ahhazaesa01 /pass:J0wmUVKKdoDHPObSkv9NzKP4QwyahRlcxercDCMckZNUX0cv8Ro403QGz+j0Fdqw9DH2G22tyTRh+AStIcQtLQ=="
#End of Change
#Variables for later, no need to change
$ConnectAFSDriveTask = "ConnectAzureFileShare_" + $DriveLetter
$DriveDir = $DriveRoot + $DriveShare
$DriveLetterTotal = $DriveLetter + ':'
$DriveRootConnection = '"\\' + $DriveDir + '"'

$1 = (dsregcmd /status | select-string "AzureAdJoined")
$2 = (dsregcmd /status | select-string "TenantName")
$3 = (dsregcmd /status | select-string "TenantId")
#End of Variables

function Test-Administrator {
    $User = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (($1 -match "YES") -and ($2 -match "Private Universe Pty Ltd") -and ($3 = "a853109b-1cd1-4bc3-a5be-4c03938393ae")) {
    $CMDKey
} else {
    cmd.exe /c "cmdkey /delete:"$DriveRoot
    net use $DriveLetterTotal /delete
exit
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

    $Script = '$connectTestResult' + " = Test-NetConnection -Computername $DriveRoot -Port 445
         if ($connectTestResult.TcpTestSucceeded) {
             net use $DriveLetterTotal $DriveRootConnection
         } else {
        Write-Error -Message 'Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port.'
    }"

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

    $connectTestResult = Test-NetConnection -Computername $DriveRoot -Port 445
        if ($connectTestResult.TcpTestSucceeded) {
            net use $DriveLetterTotal $DriveRootConnection
        } else {
        Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
    }
}

If (Get-PSDrive -Name O) {
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + $DriveLetter + "-Drive mapped successfully.")
}

Else {
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + "Please verify installation.")
}
