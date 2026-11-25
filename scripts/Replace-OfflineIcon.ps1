[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$InputPath,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [Parameter(Mandatory)][ValidateRange(1, 100000)][int]$X,
    [Parameter(Mandatory)][ValidateRange(0, 100000)][int]$Y,
    [Parameter(Mandatory)][ValidateRange(1, 256)][int]$Width,
    [Parameter(Mandatory)][ValidateRange(1, 256)][int]$Height,
    [ValidateRange(1, 256)][int]$IconSize = 16
)
$ErrorActionPreference = 'Stop'
if ($IconSize -gt [Math]::Min($Width, $Height)) { throw 'Icon exceeds replacement rectangle.' }
Add-Type -AssemblyName System.Drawing
[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$reference = [Drawing.Bitmap]::new((Join-Path $PSScriptRoot '../assets/offline.png'))
$icon = [Drawing.Bitmap]::new($IconSize, $IconSize)
try {
    $graphics = [Drawing.Graphics]::FromImage($icon)
    try {
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($reference, [Drawing.Rectangle]::new(0, 0, $IconSize, $IconSize))
    } finally { $graphics.Dispose() }

    $iconX = $X + [int][Math]::Floor(($Width - $IconSize) / 2)
    $iconY = $Y + [int][Math]::Floor(($Height - $IconSize) / 2)
    foreach ($file in $InputPath) {
        try {
            $source = [Drawing.Bitmap]::new((Get-Item -LiteralPath $file).FullName)
            try {
                if ($X + $Width -ge $source.Width -or $Y + $Height -gt $source.Height) {
                    throw 'Replacement rectangle is outside the image.'
                }
                $bitmap = $source.Clone([Drawing.Rectangle]::new(0, 0, $source.Width, $source.Height), [Drawing.Imaging.PixelFormat]::Format32bppArgb)
                try {
                    for ($yPixel = $Y; $yPixel -lt $Y + $Height; $yPixel++) {
                        $left = $source.GetPixel($X - 1, $yPixel)
                        $right = $source.GetPixel($X + $Width, $yPixel)
                        for ($xPixel = $X; $xPixel -lt $X + $Width; $xPixel++) {
                            $fraction = ($xPixel - $X + 1) / ($Width + 1)
                            $ink = 0
                            if ($xPixel -ge $iconX -and $xPixel -lt $iconX + $IconSize -and
                                $yPixel -ge $iconY -and $yPixel -lt $iconY + $IconSize) {
                                $ink = $icon.GetPixel($xPixel - $iconX, $yPixel - $iconY).A / 255.0
                            }
                            $red = ($left.R * (1 - $fraction) + $right.R * $fraction) * (1 - $ink) + 16 * $ink
                            $green = ($left.G * (1 - $fraction) + $right.G * $fraction) * (1 - $ink) + 16 * $ink
                            $blue = ($left.B * (1 - $fraction) + $right.B * $fraction) * (1 - $ink) + 16 * $ink
                            $bitmap.SetPixel($xPixel, $yPixel, [Drawing.Color]::FromArgb([int]$red, [int]$green, [int]$blue))
                        }
                    }
                    $stem = [IO.Path]::GetFileNameWithoutExtension($file)
                    $destination = Join-Path $OutputDirectory "$stem-offline.png"
                    $sequence = 2
                    while (Test-Path -LiteralPath $destination) {
                        $destination = Join-Path $OutputDirectory "$stem-offline-$sequence.png"
                        $sequence++
                    }
                    $bitmap.Save($destination, [Drawing.Imaging.ImageFormat]::Png)
                    [pscustomobject]@{ Input = $file; Output = $destination; Error = $null }
                } finally { $bitmap.Dispose() }
            } finally { $source.Dispose() }
        } catch {
            [pscustomobject]@{ Input = $file; Output = $null; Error = $_.Exception.Message }
        }
    }
} finally {
    $icon.Dispose()
    $reference.Dispose()
}
