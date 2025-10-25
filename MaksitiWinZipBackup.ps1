# --- EDIT THESE TWO PER MACHINE ---
$SrcPath = "C:\Users\arbri\Desktop\maksitibackup"   # Folder to back up
$Bucket  = "maksiti-backup"                      # S3 bucket name
# ----------------------------------

$Computer  = $env:COMPUTERNAME
$UserName  = $env:USERNAME
$Stamp     = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Prefix    = "zips/$Computer"
$ZipName   = "${Computer}-${UserName}_${Stamp}.zip"
$TempZip   = Join-Path $env:TEMP $ZipName

# Exit quietly if source folder missing
if (-not (Test-Path $SrcPath)) { exit 0 }

try {
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force -ErrorAction SilentlyContinue }
    Compress-Archive -Path $SrcPath -DestinationPath $TempZip -CompressionLevel Optimal -Force
} catch { exit 0 }

$S3Key = "$Prefix/$ZipName"

# Upload with encryption (Standard first; lifecycle will move it to Glacier IR)
aws s3 cp "$TempZip" "s3://$Bucket/$S3Key" --sse AES256 | Out-Null

Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
