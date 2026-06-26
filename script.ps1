[CmdletBinding()]
param(
    [string]$InputDirectory = (Get-Location).Path,
    [string]$OutputFile = 'Kaamelott Livre II - Tome 2.mkv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-FfMetadataValue {
    param([Parameter(Mandatory)] [string]$Value)

    $escaped = ($Value -replace "`r`n|`n|`r", ' ') -replace '([\\=;#])', '\\$1'
    return $escaped
}

function ConvertTo-FfConcatLine {
    param([Parameter(Mandatory)] [string]$Path)

    $escapedPath = ($Path -replace '\\', '/') -replace "'", "''"
    return "file '$escapedPath'"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$files = Get-ChildItem -LiteralPath $InputDirectory -Filter *.mkv | Sort-Object Name

if (-not $files) {
    throw "No MKV files were found in '$InputDirectory'."
}

$concatLines = foreach ($file in $files) {
    ConvertTo-FfConcatLine -Path $file.FullName
}

$tempDirectory = [System.IO.Path]::GetTempPath()
$concatListPath = Join-Path $tempDirectory ([System.IO.Path]::GetRandomFileName() + '.txt')
$chaptersPath = Join-Path $tempDirectory ([System.IO.Path]::GetRandomFileName() + '.txt')

$chapterLines = New-Object System.Collections.Generic.List[string]
$chapterLines.Add(';FFMETADATA1')
$startTimeMs = 0

foreach ($file in $files) {
    $durationText = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $file.FullName

    if ([string]::IsNullOrWhiteSpace($durationText)) {
        throw "Unable to read duration for '$($file.FullName)'."
    }

    $durationMs = [int][math]::Round(([double]$durationText) * 1000)
    $endTimeMs = $startTimeMs + $durationMs
    $chapterTitle = ConvertTo-FfMetadataValue -Value $file.BaseName

    $chapterLines.Add('[CHAPTER]')
    $chapterLines.Add('TIMEBASE=1/1000')
    $chapterLines.Add("START=$startTimeMs")
    $chapterLines.Add("END=$endTimeMs")
    $chapterLines.Add("title=$chapterTitle")

    $startTimeMs = $endTimeMs
}

try {
    [System.IO.File]::WriteAllLines($concatListPath, $concatLines, $utf8NoBom)
    [System.IO.File]::WriteAllLines($chaptersPath, $chapterLines, $utf8NoBom)

    & ffmpeg -y -f concat -safe 0 -i $concatListPath -i $chaptersPath -map_metadata 1 -c copy (Join-Path $InputDirectory $OutputFile)
}
finally {
    Remove-Item -LiteralPath $concatListPath, $chaptersPath -ErrorAction SilentlyContinue
}