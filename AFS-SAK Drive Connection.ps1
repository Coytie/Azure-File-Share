#Change Variables Below
$companyname = " " #This is where you'll put your Azure Company Name.
$TenantId = " " #This is where you'll put your Azure Tenancy ID.
$DriveLetter = ' ' #This is where you'll select your drive letter.
$DriveRoot = 'StorageAccount.file.core.windows.net'
$DriveFolder = '\folder'
$CMDKey = "cmd.exe /C `cmdkey /add:`"StorageAccount.file.core.windows.net`" /user:`"localhost\StorageAccount`" /pass:`"password`"`"


#Variables for later - Nothing to change
$ConnectAFSDriveTask = "ConnectAzureFileShare_" + $DriveLetter
$DriveDir = $DriveRoot + $DriveShare
$DriveLetterTotal = $DriveLetter + ':'
$DriveRootConnection = '\\' + $DriveDir + $DriveFolder

$1 = (dsregcmd /status | select-string "AzureAdJoined")
$2 = (dsregcmd /status | select-string "TenantName")
$3 = (dsregcmd /status | select-string "TenantId")
#End of Variables

function Test-Administrator {
    $User = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (($1 -match "YES") -and ($2 -match $companyname) -and ($3 -match $TenantId)) {
    write-host "Domain Verification Passed..."
} else {
    cmd.exe /c "cmdkey /delete:$DriveRoot"
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
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + "Running as administrator.")
    $ScriptFilePath = Join-Path -Path $ScriptDirectory -ChildPath "ConnectAzureFileShare_$DriveLetter.ps1"

    $Script = @"
`$driveInfo = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue #Change
    if (`$driveInfo.DisplayRoot -eq "$DriveRootConnection") { #Change
        write-host "Connection already exists! Exiting."
        exit
    }
$CMDKey
`$TaskConnectTestResult = Test-NetConnection -ComputerName $DriveRoot -Port 445
if (`$TaskConnectTestResult.TcpTestSucceeded) {
    # Mount the drive
    New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root "$DriveRootConnection" -Persist #Change
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
"@

    $Script | Out-File -FilePath $ScriptFilePath -Encoding ASCII

    $PSexe = Join-Path $PSHOME powershell.exe
    $Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File $ScriptFilePath"
    $Action = New-ScheduledTaskAction -Execute $PSexe -Argument $Arguments
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal

    Register-ScheduledTask -TaskName $ConnectAFSDriveTask -InputObject $Task -Force | Out-Null
    Start-ScheduledTask -TaskName $ConnectAFSDriveTask | Out-Null
    start-sleep -seconds 15
    Unregister-ScheduledTask -TaskName "$ConnectAFSDriveTask" -Confirm:$false
    start-sleep -seconds 1
    Remove-Item -Path $ScriptFilePath
} Else {
    # Not running as administrator. Connecting directly with Azure script.
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + "Not running as administrator.")

    $connectTestResult = Test-NetConnection -Computername $DriveRoot -Port 445
        if ($connectTestResult.TcpTestSucceeded) {
            $driveInfo = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue #Change
            if ($driveInfo.DisplayRoot -eq "$DriveRootConnection") { #Change
                write-host "Connection already exists! Exiting."
                exit
            } else {
                Invoke-Expression -Command $CMDKey
                net use $DriveLetterTotal $DriveRootConnection
            }
        } else {
        Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
      }
}

If (net use $DriveLetterTotal) {
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + $DriveLetter + "-Drive mapped successfully.")
}

Else {
    Add-Content -Path $ScriptLogFilePath -Value ((Get-Date).ToString() + ": " + "Please verify installation.")
}
