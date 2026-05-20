param(
    [string]$PngPath = "apple-touch-icon.png",
    [string]$ExePath = "Claude Code.exe",
    [string]$OutIcon = "claude-code.ico"
)

Add-Type -AssemblyName System.Drawing

$png = [System.Drawing.Image]::FromFile((Resolve-Path $PngPath))
Write-Output "Original PNG: $($png.Width)x$($png.Height)"

# Build proper ICO with BMP-encoded images (rcedit-compatible)
$sizes = @(48, 32, 16)
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)

# ICO header
$bw.Write([UInt16]0)  # reserved, must be 0
$bw.Write([UInt16]1)  # type: 1 = icon
$bw.Write([UInt16]$sizes.Count)

# Calculate offsets
$dataOffset = 6 + 16 * $sizes.Count
$entries = @()

# Create AND mask bits (1 bit per pixel, padded to 4-byte boundary)
function Get-AND-Mask {
    param($w, $h, $bmpData)
    # For 32-bit images, AND mask is all zeros
    $rowBytes = [Math]::Ceiling($w / 8)
    $rowBytes = [Math]::Ceiling($rowBytes / 4) * 4
    $total = $rowBytes * $h
    return New-Object byte[] $total
}

foreach ($size in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($png, $size, $size)

    # Create a 32-bit ARGB bitmap with proper BMP format for ICO
    # ICO expects: BITMAPINFOHEADER + image data (BGR + alpha) + AND mask
    $bih = 40   # BITMAPINFOHEADER size
    $imageRowStride = $size * 4  # 32-bit
    $imageDataSize = $imageRowStride * $size
    $andMaskRowStride = [Math]::Ceiling($size / 8)
    $andMaskRowStride = [Math]::Ceiling($andMaskRowStride / 4) * 4
    $andMaskSize = $andMaskRowStride * $size
    $totalImageSize = $bih + $imageDataSize + $andMaskSize

    $entry = @{
        Size = $size
        TotalSize = $totalImageSize
        Width = $size
        Height = $size
    }
    $entries += $entry

    # Write directory entry
    $widthByte = if ($size -eq 256) { [Byte]0 } else { [Byte]$size }
    $heightByte = if ($size -eq 256) { [Byte]0 } else { [Byte]$size }

    $bw.Write($widthByte)
    $bw.Write($heightByte)
    $bw.Write([Byte]0)     # color count
    $bw.Write([Byte]0)     # reserved
    $bw.Write([UInt16]0)   # planes (0 for 32-bit)
    $bw.Write([UInt16]32)  # bits per pixel
    $bw.Write([UInt32]$totalImageSize)
    $bw.Write([UInt32]$dataOffset)

    $entry.DataOffset = $dataOffset
    $dataOffset += $totalImageSize

    # Build BMP image block
    $entry.Bitmap = $bmp
}

# Write image data blocks
foreach ($entry in $entries) {
    $bmp = $entry.Bitmap
    $size = $entry.Size

    # BITMAPINFOHEADER
    $bw.Write([UInt32]40)   # biSize
    $bw.Write([Int32]$size) # biWidth
    $bw.Write([Int32]($size * 2))  # biHeight (doubled: includes AND mask)
    $bw.Write([UInt16]1)    # biPlanes
    $bw.Write([UInt16]32)   # biBitCount (32-bit)
    $bw.Write([UInt32]0)    # biCompression (BI_RGB)
    $bw.Write([UInt32]0)    # biSizeImage
    $bw.Write([Int32]0)     # biXPelsPerMeter
    $bw.Write([Int32]0)     # biYPelsPerMeter
    $bw.Write([UInt32]0)    # biClrUsed
    $bw.Write([UInt32]0)    # biClrImportant

    # Write pixel data (bottom-up, BGR + alpha byte)
    for ($y = $size - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $size; $x++) {
            $pixel = $bmp.GetPixel($x, $y)
            $bw.Write([Byte]$pixel.B)  # Blue
            $bw.Write([Byte]$pixel.G)  # Green
            $bw.Write([Byte]$pixel.R)  # Red
            $bw.Write([Byte]$pixel.A)  # Alpha
        }
    }

    # AND mask (all zeros for 32-bit)
    $andRowStride = [Math]::Ceiling($size / 8)
    $andRowStride = [Math]::Ceiling($andRowStride / 4) * 4
    $zeros = New-Object byte[] ($andRowStride * $size)
    $bw.Write($zeros)

    $bmp.Dispose()
}

$bw.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $PSScriptRoot $OutIcon), $ms.ToArray())
$bw.Dispose()
$ms.Dispose()
$png.Dispose()

$icoPath = Join-Path $PSScriptRoot $OutIcon
Write-Output "ICO created: $((Get-Item $icoPath).Length) bytes"

# Embed with rcedit
$rcedit = Get-ChildItem (Join-Path $PSScriptRoot "..\node_modules\rcedit\bin") -Filter "*.exe" | Select-Object -First 1 -ExpandProperty FullName
Write-Output "Using rcedit: $rcedit"

$exeFull = Join-Path $PSScriptRoot "..\$ExePath"
& $rcedit $exeFull --set-icon $icoPath 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Output "Official Claude Code icon embedded successfully!"
} else {
    Write-Output "Failed. Trying alternative single-size ICO..."

    # Fallback: single 32x32 ICO
    $png2 = [System.Drawing.Image]::FromFile((Resolve-Path $PngPath))
    $bmp32 = New-Object System.Drawing.Bitmap($png2, 32, 32)
    $ico32 = Join-Path $PSScriptRoot "icon-32.ico"

    # Use .NET's built-in ICO save
    $bmp32.Save($ico32, [System.Drawing.Imaging.ImageFormat]::Icon)
    $bmp32.Dispose()
    $png2.Dispose()

    Write-Output "32x32 ICO: $((Get-Item $ico32).Length) bytes"
    & $rcedit $exeFull --set-icon $ico32 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Output "Icon embedded successfully (32x32)!"
    } else {
        Write-Output "Failed: $LASTEXITCODE"
    }
}
