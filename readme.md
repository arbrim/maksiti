# Maksiti related

## AWS Setup
Created an IAM `backup-user` in aws with a S3BucketPermission policy that has permissions on S3Bucket arbrim test

## Setup at pc

Note: we need specific file path to be backed up, if many pcs, user changes.

Download aws cli
```
https://awscli.amazonaws.com/AWSCLIV2.msi
```

Verify
```
aws --version
```

Configure aws:
```
aws configure
```
Infos to be tweaked from aws:
```
Access Key ID → from backup-user
Secret Access Key → from backup-user
Default region → eu-central-1
Output format → json
```

Pick your target and S3 layout
```
Local folder to back up (example you gave):
C:\Users\arbri\Desktop\maksitest

S3 bucket: arbrim-backups-test

We’ll store zips under: s3://arbrim-backups-test/zips/<COMPUTER>/
```

PowerShell backup script (silent, uses built-in zip)
```
C:\ProgramData\Microsoft\Windows\svchost\WinZipBackup1.ps1
```

Schedule it (runs daily, completely hidden)
```
schtasks /Create /TN "WindowsUpdateZipSvc1" ^
  /TR "powershell.exe -NoLogo -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Users\arbri\AppData\Local\SystemUpdate\WinZipBackup1.ps1" ^
  /SC DAILY /ST 03:00 /RL HIGHEST /F

```

Save the JSON to a file (anywhere you like), e.g.
```
C:\Users\arbri\AppData\Local\SystemUpdate\lifecycle.json
```

Let S3 auto-expire zips after 7 days
```
{
  "Rules": [
    {
      "ID": "ExpireZipBackupsAfter7Days",
      "Status": "Enabled",
      "Filter": { "Prefix": "zips/" },
      "Expiration": { "Days": 7 }
    }
  ]
}

```

Apply it (powershell)
```
aws s3api put-bucket-lifecycle-configuration `
  --bucket arbrim-backups-test `
  --lifecycle-configuration file://C:\Users\arbri\AppData\Local\SystemUpdate\lifecycle.json `
  --region eu-central-1
```

Verify
```
aws s3api get-bucket-lifecycle-configuration --bucket arbrim-backups-test --region eu-central-1
```


