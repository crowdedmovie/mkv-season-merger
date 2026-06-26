# -----------------------------
# 1️⃣ Create files.txt for FFmpeg concat (UTF-8 without BOM)
# -----------------------------
$utf8NoBOM = New-Object System.Text.UTF8Encoding($False)
Get-ChildItem -Filter *.mkv | Sort-Object Name | ForEach-Object {
    # Escape single quotes by doubling them
    $escapedName = $_.Name -replace "'", "''"
    "file '$escapedName'"
} | Set-Content -LiteralPath .\files.txt -Encoding $utf8NoBOM

# -----------------------------
# 2️⃣ Create chapters.txt with metadata (UTF-8 without BOM)
# -----------------------------
$files = Get-ChildItem -Filter *.mkv | Sort-Object Name
$startTime = 0
$metadata = ";FFMETADATA1`n"

foreach ($file in $files) {
    # Get duration of the file in seconds
    $info = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)"
    $duration = [math]::Round([double]$info)
    $endTime = $startTime + $duration

    # Escape '=' in title to avoid metadata parsing issues
    $title = $file.BaseName -replace "=", "\="

    # Add chapter entry
    $metadata += "[CHAPTER]`nTIMEBASE=1/1`nSTART=$startTime`nEND=$endTime`ntitle=$title`n"

    # Next chapter starts at the end of this one
    $startTime = $endTime
}

$metadata | Set-Content -LiteralPath .\chapters.txt -Encoding $utf8NoBOM

# -----------------------------
# 3️⃣ Merge all MKVs into one with chapters
# -----------------------------
ffmpeg -f concat -safe 0 -i files.txt -i chapters.txt -map_metadata 1 -c copy "Kaamelott Livre II - Tome 2.mkv"     