# --- EDIT THESE TWO PER MACHINE ---
$SrcPath = "C:\Users\arbri\Desktop\maksitest"   # Folder to back up
$Bucket  = "arbrim-backups-test"                # Your S3 bucket
# ----------------------------------

$Computer  = $env:COMPUTERNAME
$UserName  = $env:USERNAME
$Stamp     = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Prefix    = "zips/$Computer"
$ZipName   = "${Computer}-${UserName}_${Stamp}.zip"
$TempZip   = Join-Path $env:TEMP $ZipName

# If source missing, exit quietly
if (-not (Test-Path $SrcPath)) { exit 0 }

# Create ZIP (Windows built-in)
try {
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force -ErrorAction SilentlyContinue }
    Compress-Archive -Path $SrcPath -DestinationPath $TempZip -CompressionLevel Optimal -Force
} catch { exit 0 }

# Upload to S3 (silent) and delete local zip
$S3Key = "$Prefix/$ZipName"
$null = aws s3 cp "$TempZip" "s3://$Bucket/$S3Key" --sse AES256 2>$null
Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
