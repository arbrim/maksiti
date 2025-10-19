# --- Config (edit these 2 lines per laptop) ---
$SrcPath   = "C:\Users\arbri\Desktop\maksitest"   # Folder to back up
$Bucket    = "arbrim-backups-test"                # S3 bucket name
# ----------------------------------------------

# Derived values (usually no need to change)
$Computer  = $env:COMPUTERNAME
$UserName  = $env:USERNAME
$Stamp     = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Prefix    = "zips/$Computer"
$ZipName   = "${Computer}-${UserName}_${Stamp}.zip"
$TempZip   = Join-Path $env:TEMP $ZipName

# Ensure source exists
if (-not (Test-Path $SrcPath)) { exit 0 }

# Create ZIP (built-in Compress-Archive). No window; quiet.
try {
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force -ErrorAction SilentlyContinue }
    Compress-Archive -Path $SrcPath -DestinationPath $TempZip -CompressionLevel Optimal -Force
} catch { exit 0 }

# Upload to S3 with server-side encryption, then delete local zip
$S3Key = "$Prefix/$ZipName"
$null = aws s3 cp "$TempZip" "s3://$Bucket/$S3Key" --sse AES256 2>$null
Remove-Item $TempZip -Force -ErrorAction SilentlyContinue

# --- Optional: script-side retention (delete > 7 days) ---
# (You can skip this if you’ll add an S3 lifecycle rule below.)
try {
    $cutoff = (Get-Date).AddDays(-7)
    $list = aws s3api list-objects-v2 --bucket $Bucket --prefix $Prefix/ | ConvertFrom-Json
    foreach ($obj in ($list.Contents | Where-Object { $_.LastModified -lt $cutoff })) {
        $key = $obj.Key
        $null = aws s3api delete-object --bucket $Bucket --key $key 2>$null
    }
} catch { }
