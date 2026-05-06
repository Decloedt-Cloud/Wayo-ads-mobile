# Install Android SDK Command-line Tools (latest bundled URL) so Flutter can run
# apkanalyzer after release builds (avoids "failed to strip debug symbols" false failure).
#
# Run once (user scope):
#   powershell -ExecutionPolicy Bypass -File tool\windows\install_android_cmdline_tools.ps1
#
# Requires: Android SDK folder (default %LOCALAPPDATA%\Android\sdk).
$ErrorActionPreference = "Stop"

$sdkRoot = $env:ANDROID_HOME
if (-not $sdkRoot) { $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk" }
if (-not (Test-Path $sdkRoot)) {
    Write-Error "Android SDK not found at $sdkRoot. Install Android Studio or set ANDROID_HOME."
}

$apkanalyzer = Join-Path $sdkRoot "cmdline-tools\latest\bin\apkanalyzer.bat"
if (Test-Path $apkanalyzer) {
    Write-Host "Already installed: $apkanalyzer"
    exit 0
}

$url = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$zip = Join-Path $env:TEMP "commandlinetools-win.zip"
$unpack = Join-Path $env:TEMP "commandlinetools-unpack"

Write-Host "Downloading command-line tools..."
# curl avoids Invoke-WebRequest encoding issues on some Windows setups
curl.exe -L -f -o $zip $url
if ($LASTEXITCODE -ne 0) { Write-Error "Download failed (curl exit $LASTEXITCODE)" }

if (Test-Path $unpack) { Remove-Item -Recurse -Force $unpack }
New-Item -ItemType Directory -Path $unpack | Out-Null
Expand-Archive -Path $zip -DestinationPath $unpack -Force

$cmdlineRoot = Join-Path $sdkRoot "cmdline-tools"
$latest = Join-Path $cmdlineRoot "latest"
if (Test-Path $latest) { Remove-Item -Recurse -Force $latest }
New-Item -ItemType Directory -Path $cmdlineRoot -Force | Out-Null

$inner = Join-Path $unpack "cmdline-tools"
if (-not (Test-Path $inner)) {
    Write-Error "Unexpected zip layout: missing cmdline-tools folder"
}
Move-Item $inner $latest

Remove-Item $zip -Force -ErrorAction SilentlyContinue
Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $apkanalyzer)) {
    Write-Error "Install finished but apkanalyzer missing at $apkanalyzer"
}

Write-Host "OK: $apkanalyzer"
Write-Host "Next: flutter doctor --android-licenses"
Write-Host "Then: flutter build appbundle --release"
