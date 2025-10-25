# Maksiti backup setup

Sample folder backup at `C:\Users\arbri\Desktop\maksitibackup` - and bucket `maksiti-backup` with prefix of `zips/$Computer`.

Script: at `MaksitiWinZipBackup.ps1`

Todos after installing aws:

## Locate script
Move `MaksitiWinZipBackup.ps1` to `C:\Users\arbri\AppData\Local\SystemUpdate\MaksitiWinZipBackup.ps1`

## Open powershell as administrator and run below script (update user arbri to current one):

```
$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument '-NoLogo -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\arbri\AppData\Local\SystemUpdate\MaksitiWinZipBackup.ps1"'

$trigger = New-ScheduledTaskTrigger -Daily -At "17:00"

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask `
    -TaskName 'Maksiti Update Zip SVC' `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -RunLevel Highest `
    -User 'arbri'

```

## Verify
```
schtasks /Query /TN "Maksiti Update Zip SVC" /V /FO LIST
```

## Run manual
```
schtasks /Run /TN "Maksiti Update Zip SVC"
```
