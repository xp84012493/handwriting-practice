# Export app icons from practice-sheet stroke paths (Make Me a Hanzi), then resize for all platforms.
# Usage (repo root): powershell -ExecutionPolicy Bypass -File tool/export_app_icons.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw "Run from repo with pubspec.yaml; could not resolve root from $PSScriptRoot"
}

Push-Location $root
try {
    Write-Host 'Rendering source icon from hanzi stroke paths (flutter test)...'
    flutter test tool/render_glyph_icon_test.dart
    if ($LASTEXITCODE -ne 0) {
        throw "flutter test tool/render_glyph_icon_test.dart failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

function Save-RgbPng([System.Drawing.Bitmap]$bmp, [string]$path) {
    $dir = Split-Path $path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Resize-RgbPng([System.Drawing.Bitmap]$src, [int]$px, [string]$path) {
    $bmp = New-Object System.Drawing.Bitmap $px, $px, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Black)
    $g.DrawImage($src, 0, 0, $px, $px)
    $g.Dispose()
    Save-RgbPng $bmp $path
    $bmp.Dispose()
}

$sourcePath = Join-Path $root 'assets\branding\app_icon_lian_square.png'
if (-not (Test-Path $sourcePath)) {
    throw "Missing rendered source icon: $sourcePath"
}

$src = [System.Drawing.Image]::FromFile($sourcePath)
$square = New-Object System.Drawing.Bitmap $src.Width, $src.Height, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($square)
$g.DrawImage($src, 0, 0, $src.Width, $src.Height)
$g.Dispose()
$src.Dispose()
Write-Host "Source icon: $sourcePath"

$android = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
foreach ($k in $android.Keys) {
    Resize-RgbPng $square $android[$k] (Join-Path $root "android\app\src\main\res\mipmap-$k\ic_launcher.png")
}

$ios = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
@(
    @{ f = 'Icon-App-20x20@2x.png'; s = 40 },
    @{ f = 'Icon-App-20x20@3x.png'; s = 60 },
    @{ f = 'Icon-App-29x29@1x.png'; s = 29 },
    @{ f = 'Icon-App-29x29@2x.png'; s = 58 },
    @{ f = 'Icon-App-29x29@3x.png'; s = 87 },
    @{ f = 'Icon-App-40x40@2x.png'; s = 80 },
    @{ f = 'Icon-App-40x40@3x.png'; s = 120 },
    @{ f = 'Icon-App-60x60@2x.png'; s = 120 },
    @{ f = 'Icon-App-60x60@3x.png'; s = 180 },
    @{ f = 'Icon-App-20x20@1x.png'; s = 20 },
    @{ f = 'Icon-App-40x40@1x.png'; s = 40 },
    @{ f = 'Icon-App-76x76@1x.png'; s = 76 },
    @{ f = 'Icon-App-76x76@2x.png'; s = 152 },
    @{ f = 'Icon-App-83.5x83.5@2x.png'; s = 167 },
    @{ f = 'Icon-App-1024x1024@1x.png'; s = 1024 }
) | ForEach-Object {
    Resize-RgbPng $square $_.s (Join-Path $ios $_.f)
}

$web = Join-Path $root 'web'
Resize-RgbPng $square 192 (Join-Path $web 'icons\Icon-192.png')
Resize-RgbPng $square 512 (Join-Path $web 'icons\Icon-512.png')
Resize-RgbPng $square 192 (Join-Path $web 'icons\Icon-maskable-192.png')
Resize-RgbPng $square 512 (Join-Path $web 'icons\Icon-maskable-512.png')
Resize-RgbPng $square 32 (Join-Path $web 'favicon.png')

$windowsIco = Join-Path $root 'windows\runner\resources\app_icon.ico'
if (Test-Path (Split-Path $windowsIco -Parent)) {
    try {
        Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @"
using System;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
public static class AppIconHelper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool DestroyIcon(IntPtr handle);
    public static void SaveBitmapAsIcon(Bitmap bmp, string path) {
        IntPtr hIcon = bmp.GetHicon();
        try {
            using (Icon icon = Icon.FromHandle(hIcon)) {
                using (var fs = File.Open(path, FileMode.Create)) {
                    icon.Save(fs);
                }
            }
        } finally {
            DestroyIcon(hIcon);
        }
    }
}
"@
        [AppIconHelper]::SaveBitmapAsIcon($square, $windowsIco)
        Write-Host "Windows icon: $windowsIco"
    } catch {
        Write-Warning "Skipped Windows .ico export: $_"
    }
}

$square.Dispose()
Write-Host 'Exported app icons from practice-sheet stroke paths.'
