$ProjectDir = "D:\00000. Operator OS\operator_os"

# Your actual JDK17 path (Eclipse Adoptium)
$env:JAVA_HOME    = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"

# Add everything Flutter needs including PowerShell itself
$env:PATH = "$env:JAVA_HOME\bin;" +
            "$env:USERPROFILE\flutter\bin;" +
            "C:\Program Files\Git\cmd;" +
            "C:\Windows\System32\WindowsPowerShell\v1.0;" +
            "C:\Windows\System32;" +
            "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin;" +
            "$env:LOCALAPPDATA\Android\Sdk\platform-tools;" +
            $env:PATH

& "$env:USERPROFILE\flutter\bin\flutter.bat" config --jdk-dir "$env:JAVA_HOME" 2>&1 | Out-Null

$sdk = $env:ANDROID_HOME -replace "\\","\\"
$fl  = "$env:USERPROFILE\flutter"  -replace "\\","\\"
"sdk.dir=$sdk`nflutter.sdk=$fl`nflutter.buildMode=release`nflutter.versionName=1.0.0`nflutter.versionCode=1" | Set-Content "$ProjectDir\android\local.properties"

Set-Location $ProjectDir

Write-Host "[1/3] flutter pub get..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "pub get FAILED" -ForegroundColor Red; exit 1 }

Write-Host "[2/3] flutter build apk --release..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Write-Host "build FAILED" -ForegroundColor Red; exit 1 }

$apk = Join-Path $ProjectDir "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    $size = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host "SUCCESS -> $apk ($size MB)" -ForegroundColor Green
    Start-Process explorer.exe (Split-Path $apk)
} else {
    Write-Host "APK not found. Paste the error above." -ForegroundColor Red
}