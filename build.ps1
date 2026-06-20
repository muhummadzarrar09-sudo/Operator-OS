$ProjectDir = "D:\00000. Operator OS\operator_os"
$OutputApkName = "Operator OS.apk"

$env:JAVA_HOME    = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"

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

# Fix compileSdk warning before building
$buildGradle = "$ProjectDir\android\app\build.gradle.kts"
(Get-Content $buildGradle) -replace "compileSdk = 35", "compileSdk = 36" | Set-Content $buildGradle

Set-Location $ProjectDir

Write-Host "[1/4] flutter pub get..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "pub get FAILED" -ForegroundColor Red; exit 1 }

Write-Host "[2/4] dart run build_runner build (generating .g.dart files)..." -ForegroundColor Cyan
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Write-Host "build_runner FAILED" -ForegroundColor Red; exit 1 }

Write-Host "[3/4] flutter build apk --release..." -ForegroundColor Cyan
flutter build apk --release
$flutterExit = $LASTEXITCODE

# AGP 9.x writes the APK under android\app\build\outputs and Flutter's tool can
# fail to relocate/find it (reporting "couldn't find it") even though Gradle's
# build was SUCCESSFUL. So locate the produced APK in any known location.
$apkCandidates = @(
    (Join-Path $ProjectDir "build\app\outputs\flutter-apk\app-release.apk"),
    (Join-Path $ProjectDir "android\app\build\outputs\flutter-apk\app-release.apk"),
    (Join-Path $ProjectDir "android\app\build\outputs\apk\release\app-release.apk")
)
$apk = $apkCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $apk) {
    Write-Host "build FAILED (no app-release.apk found in any output location)" -ForegroundColor Red
    exit 1
}
if ($flutterExit -ne 0) {
    Write-Host "Flutter tool returned $flutterExit but Gradle produced an APK at:" -ForegroundColor Yellow
    Write-Host "  $apk" -ForegroundColor Yellow
}

$namedApk = Join-Path $ProjectDir ("build\app\outputs\flutter-apk\" + $OutputApkName)
New-Item -ItemType Directory -Force -Path (Split-Path $namedApk) | Out-Null
Write-Host "[4/4] Naming output APK..." -ForegroundColor Cyan
if (Test-Path $apk) {
    Copy-Item $apk $namedApk -Force
    $size = [math]::Round((Get-Item $namedApk).Length / 1MB, 1)
    Write-Host "SUCCESS -> $namedApk ($size MB)" -ForegroundColor Green
    Start-Process explorer.exe (Split-Path $namedApk)
    exit 0
} else {
    Write-Host "APK not found. Paste the error above." -ForegroundColor Red
    exit 1
}
