# Deep clean before release builds on Windows (Pub cache / Gradle locks).
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File tool\windows\clean_flutter_android_build.ps1
$ErrorActionPreference = "Continue"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $repo

Write-Host "Repo: $repo"

Write-Host "`n[1/4] Stopping Gradle daemons..."
& "$repo\android\gradlew.bat" --stop 2>$null

Write-Host "`n[2/4] Removing Flutter/Gradle outputs..."
foreach ($p in @(
        "$repo\build",
        "$repo\.dart_tool",
        "$repo\android\app\build",
        "$repo\android\build",
        "$repo\android\.gradle"
    )) {
    if (Test-Path $p) {
        Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue
        Write-Host "  removed $p"
    }
}

$pubCache = $env:PUB_CACHE
if (-not $pubCache) { $pubCache = Join-Path $env:LOCALAPPDATA "Pub\Cache" }
$brokenPkg = Join-Path $pubCache "hosted\pub.dev\_fe_analyzer_shared-67.0.0"
Write-Host "`n[3/4] Pub cache: $pubCache"
if (Test-Path $brokenPkg) {
    Write-Host "  Removing package folder (will re-download on pub get): $brokenPkg"
    Remove-Item -Recurse -Force $brokenPkg -ErrorAction SilentlyContinue
}

Write-Host "`n[4/4] flutter pub get ..."
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nDone. Next:"
$sdkRoot = $env:ANDROID_HOME
if (-not $sdkRoot) { $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk" }
$apkanalyzer = Join-Path $sdkRoot "cmdline-tools\latest\bin\apkanalyzer.bat"
if (-not (Test-Path $apkanalyzer)) {
    Write-Host ""
    Write-Host "WARNING: apkanalyzer not found. Without Android SDK Command-line Tools,"
    Write-Host "         'flutter build appbundle --release' may fail AFTER Gradle with:"
    Write-Host "         'Release app bundle failed to strip debug symbols...'"
    Write-Host "  Fix (once): powershell -ExecutionPolicy Bypass -File tool\windows\install_android_cmdline_tools.ps1"
    Write-Host "  Then:      flutter doctor --android-licenses"
    Write-Host ""
}
Write-Host "  flutter build appbundle --release"
Write-Host "or"
Write-Host "  flutter build apk --release"
Write-Host "`nIf LICENSE stat errors persist: set user env PUB_CACHE to e.g. C:\dev\pub-cache (outside OneDrive), new terminal, re-run this script."
