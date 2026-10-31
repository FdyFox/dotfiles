<#
.SYNOPSIS
    Registers all fonts in the per-user font folder (no admin rights needed).

.DESCRIPTION
    Copy .ttf/.otf/.ttc files to %LOCALAPPDATA%\Microsoft\Windows\Fonts and run
    this script. Every font that is not yet registered in
    HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts gets an entry and is
    loaded into the current session, so a logout is usually not necessary.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install_fonts_user.ps1
#>

$ErrorActionPreference = 'Stop'

$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$regPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

if (-not (Test-Path $fontDir)) {
    Write-Host "Font folder $fontDir does not exist. Nothing to do." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Win32 helpers to load fonts without logout. Fails in Constrained Language Mode.
$canLoad = $true
try {
    Add-Type -Namespace Win32 -Name FontApi -MemberDefinition @'
[DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
public static extern int AddFontResource(string lpFileName);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
'@
} catch {
    $canLoad = $false
    Write-Host "Cannot load Win32 API (policy?). Fonts will be available after logout/login." -ForegroundColor Yellow
}

# Font name for the registry entry (only a label, Windows reads the real name from the file)
function Get-FontName([System.IO.FileInfo]$file) {
    try {
        Add-Type -AssemblyName System.Drawing
        $collection = New-Object System.Drawing.Text.PrivateFontCollection
        $collection.AddFontFile($file.FullName)
        $name = $collection.Families[0].Name
        $collection.Dispose()
        if ($name) { return $name }
    } catch {
        # GDI+ can not read CFF based .otf files -> fall back to the file name
    }
    return $file.BaseName
}

# Already registered files (values can be a full path or only a file name)
$registered = @{}
$props = Get-ItemProperty -Path $regPath
foreach ($p in $props.PSObject.Properties) {
    if ($p.Name -like 'PS*') { continue }
    $registered[(Split-Path ([string]$p.Value) -Leaf).ToLowerInvariant()] = $true
}

$fonts = Get-ChildItem -Path $fontDir -File |
    Where-Object { $_.Extension -match '^\.(ttf|otf|ttc)$' }

$installed = 0
foreach ($font in $fonts) {
    if ($registered.ContainsKey($font.Name.ToLowerInvariant())) {
        Write-Host "Skipping $($font.Name) (already registered)"
        continue
    }

    $type = if ($font.Extension -eq '.otf') { 'OpenType' } else { 'TrueType' }
    $regName = "$(Get-FontName $font) ($type)"

    New-ItemProperty -Path $regPath -Name $regName -Value $font.FullName `
        -PropertyType String -Force | Out-Null

    if ($canLoad) {
        [Win32.FontApi]::AddFontResource($font.FullName) | Out-Null
    }

    Write-Host "Installed $($font.Name) as '$regName'" -ForegroundColor Green
    $installed++
}

# Tell running applications that the font list changed (WM_FONTCHANGE)
if ($canLoad -and $installed -gt 0) {
    $result = [IntPtr]::Zero
    [Win32.FontApi]::SendMessageTimeout([IntPtr]0xffff, 0x1D, [IntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$result) | Out-Null
}

Write-Host "Done: $installed new font(s) registered." -ForegroundColor Cyan
if ($installed -gt 0) {
    Write-Host "Restart running applications to use the new fonts. If a font is still missing, log out and back in."
    Write-Host ""
    Write-Host "Browsers often keep running in the background. Restart them completely with:"
    Write-Host "  Chrome:  chrome://restart"
    Write-Host "  Edge:    edge://restart"
    Write-Host "  Brave:   brave://restart"
    Write-Host "  Vivaldi: vivaldi://restart"
    Write-Host "  Firefox: close all windows (about:profiles -> 'Restart normally...')"
}
