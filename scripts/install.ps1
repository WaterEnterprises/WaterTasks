<#
.SYNOPSIS
  Build, install, and launch Water Tasks on a connected Android device.
.DESCRIPTION
  1. Checks for an ADB-connected device
  2. Builds the Flutter APK (debug)
  3. Uninstalls any previous version
  4. Installs the fresh APK
  5. Launches the app and tails logs
.PARAMETER BuildMode
  Flutter build mode: debug (default) or release
#>

param(
  [ValidateSet('debug','release')]
  [string]$BuildMode = 'debug'
)

$AppId = 'com.jv.watertasks.enterprises'
$RootDir = Split-Path -Parent $PSScriptRoot
$ApkPath = ""

function Step($label) {
  Write-Host "`n==> $label" -ForegroundColor Cyan
}

function Warn($msg) {
  Write-Host "  WARN: $msg" -ForegroundColor Yellow
}

function Die($msg) {
  Write-Host "  ERROR: $msg" -ForegroundColor Red
  exit 1
}

Step 'Checking ADB device'
$raw = & adb devices 2>$null
if ($LASTEXITCODE -ne 0) {
  Die "adb not found. Install Android SDK platform-tools and add adb to PATH."
}
$device = ($raw -split "`r`n|`n") -match '^\S+\s+device$' | ForEach-Object { ($_ -split '\s+')[0] } | Select-Object -First 1
if (-not $device) {
  Die "No Android device connected. Connect a device via USB (with USB debugging enabled)."
}
Write-Host "  Device: $device" -ForegroundColor Green

# ----------------------------------------------------------------
Step "Building Flutter APK ($BuildMode mode)"
Set-Location $RootDir
$buildCmd = "flutter build apk --$BuildMode"
Write-Host "  Running: $buildCmd"
$result = Invoke-Expression $buildCmd
if ($LASTEXITCODE -ne 0) {
  Die "Flutter build failed."
}
Write-Host "  Build succeeded." -ForegroundColor Green

# Locate the APK
if ($BuildMode -eq 'debug') {
  $ApkPath = Join-Path $RootDir "build\app\outputs\flutter-apk\app-debug.apk"
} else {
  $ApkPath = Join-Path $RootDir "build\app\outputs\flutter-apk\app-release.apk"
}
if (-not (Test-Path $ApkPath)) {
  # fallback: look for any apk in the output directory
  $found = Get-ChildItem -Path (Join-Path $RootDir "build\app\outputs\flutter-apk") -Filter "*.apk" -ErrorAction SilentlyContinue
  if ($found.Count -eq 0) {
    Die "Could not find built APK."
  }
  $ApkPath = $found[0].FullName
}
Write-Host "  APK: $ApkPath" -ForegroundColor Green

# ----------------------------------------------------------------
Step "Uninstalling previous version"
$uninstall = & adb -s $device uninstall $AppId 2>&1
if ($LASTEXITCODE -eq 0) {
  Write-Host "  Uninstalled $AppId" -ForegroundColor Green
} else {
  Warn "App not installed or uninstall failed (this is OK for first install)."
}

# ----------------------------------------------------------------
Step "Installing APK"
$install = & adb -s $device install $ApkPath 2>&1
if ($LASTEXITCODE -ne 0) {
  Die "Installation failed.`n$install"
}
Write-Host "  Installed successfully." -ForegroundColor Green

# ----------------------------------------------------------------
Step "Launching app"
& adb -s $device shell am start -n "$AppId/.MainActivity" 2>&1
Write-Host "  App launched. Tailing logcat (Ctrl+C to stop)..." -ForegroundColor Green

# Tail filtered logcat output
& adb -s $device logcat --pid=$(& adb -s $device shell pidof -s $AppId 2>$null) -v brief 2>&1
cd scripts
