# Upscale phone screenshots to App Store Connect 6.5" iPhone slot (1284 x 2778).
# Usage:
#   powershell -ExecutionPolicy Bypass -File tool/resize_appstore_screenshot.ps1 input.jfif
#   powershell -ExecutionPolicy Bypass -File tool/resize_appstore_screenshot.ps1 *.png -OutDir store-screenshots

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$InputPath,

    [string]$OutDir = "store-screenshots",
    [ValidateSet("6.5", "6.9")]
    [string]$Slot = "6.5"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw "Run from repo; pubspec.yaml not found at $root"
}

$targets = @{
    '6.5' = @{ W = 1284; H = 2778; Label = '6.5-inch iPhone (1284x2778)' }
    '6.9' = @{ W = 1290; H = 2796; Label = '6.9-inch iPhone (1290x2796)' }
}
$t = $targets[$Slot]
$outRoot = Join-Path $root $OutDir
if (-not (Test-Path $outRoot)) { New-Item -ItemType Directory -Path $outRoot -Force | Out-Null }

function Resize-ToAppStore {
    param([string]$Src, [string]$Dst, [int]$W, [int]$H)

    $img = [System.Drawing.Image]::FromFile($Src)
    try {
        $bmp = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.Clear([System.Drawing.Color]::Black)
        $g.DrawImage($img, 0, 0, $W, $H)
        $g.Dispose()
        $bmp.Save($Dst, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
    } finally {
        $img.Dispose()
    }
}

$files = foreach ($p in $InputPath) { Get-Item -Path $p -ErrorAction Stop }
foreach ($file in $files) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $dst = Join-Path $outRoot "${base}-appstore-${Slot}.png"
    Resize-ToAppStore -Src $file.FullName -Dst $dst -W $t.W -H $t.H
    Write-Host "OK $($file.Name) -> $dst ($($t.Label))"
}

Write-Host ""
Write-Host "Upload these PNGs in App Store Connect:"
Write-Host "  App -> Version -> Previews and Screenshots -> iPhone"
Write-Host "  Click 'View All Sizes in Media Manager' -> 6.5-inch Display"
Write-Host "  Drag files into the 6.5-inch well (required for review)."
