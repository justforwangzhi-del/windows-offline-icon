---
name: windows-offline-icon
description: Replace the Windows taskbar Ethernet or Wi-Fi icon in one or more screenshots with the Windows offline globe with a diagonal slash. Use for requests such as “把截图右下角的联网标志 P 成断网” or batch edits of this icon.
---

1. Inspect the taskbar locally. Identify the network icon separately from volume and neighboring icons. Group screenshots only when the icon position, scale and background match. Skip screenshots that already show the requested offline icon.
2. Use the exact reference in assets/offline.png with scripts/Replace-OfflineIcon.ps1. The script assumes a light, locally smooth taskbar. Supply the tight rectangle covering the original icon and the replacement, with a clean background pixel immediately to either side on every row. Use X and Y from the top-left image pixel. For another scale, supply IconSize. For dark or textured backgrounds, adapt the localized compositing and preview it before applying in bulk.
3. Verify a taskbar crop for each layout before running the full group. Check the globe with diagonal slash, background seams and neighboring icons. Keep original files and save edited copies as PNG. Report skipped or ambiguous inputs and any errors.

PowerShell example for the verified 1920×1080 layout. Use these coordinates only after checking the layout.

```powershell
$files = Get-ChildItem -LiteralPath $inputFolder -File | Where-Object Extension -in '.png','.jpg','.jpeg','.bmp'
& "$skillFolder/scripts/Replace-OfflineIcon.ps1" -InputPath $files.FullName -OutputDirectory $outputFolder -X 1756 -Y 1046 -Width 21 -Height 20
```
