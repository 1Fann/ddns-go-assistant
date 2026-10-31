param(
    [string]$Sdk = $env:ANDROID_SDK_ROOT,
    [string]$BuildTools = '35.0.0',
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$Keystore = $env:DDNS_KEYSTORE,
    [string]$KeyAlias = 'panel'
)
$ErrorActionPreference = 'Stop'
if (-not $Sdk) { $Sdk = $env:ANDROID_HOME }
if (-not $Sdk) { throw 'Set ANDROID_SDK_ROOT or pass -Sdk.' }
$project = $PSScriptRoot
$bt = Join-Path $Sdk "build-tools/$BuildTools"
$androidJar = Join-Path $Sdk 'platforms/android-35/android.jar'
$build = Join-Path $project 'build'
$out = Join-Path $project 'out'
function Tool([string]$name) {
    if ($JavaHome) { return Join-Path $JavaHome "bin/$name.exe" }
    return $name
}
function Check-Exit { if ($LASTEXITCODE -ne 0) { throw "Build step failed ($LASTEXITCODE)" } }
if (-not (Test-Path -LiteralPath $androidJar)) { throw 'Install Android platform 35 and build-tools 35.0.0.' }
# Clear only this project's generated build directory, never source or signing keys.
if (Test-Path -LiteralPath $build) {
    $resolved = (Resolve-Path -LiteralPath $build).Path
    if ($resolved -ne [IO.Path]::GetFullPath((Join-Path $project 'build'))) { throw 'Unexpected build path.' }
    if ((Get-Item -LiteralPath $build).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Build directory must not be a link.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $build,"$build/classes","$build/dex","$build/generated","$build/assets/runtime",$out | Out-Null
$runtime = Join-Path (Split-Path -Parent $project) 'runtime'
foreach ($name in @('control.sh','daemon.sh','watchdog.sh','process.sh','interval.sh','control-version','ipv6.sh','filter-ipv6.awk','wake.sh','99-ddns-go.sh','install.sh','LICENSE.ddns-go')) {
    $content = [IO.File]::ReadAllText((Join-Path $runtime $name)).Replace("`r`n","`n")
    [IO.File]::WriteAllText((Join-Path "$build/assets/runtime" $name),$content,[Text.UTF8Encoding]::new($false))
}
& "$bt/aapt.exe" package -f -m -J "$build/generated" -M "$project/AndroidManifest.xml" -S "$project/res" -A "$build/assets" -I $androidJar -F "$build/resources.apk"
Check-Exit
$sources = @(Get-ChildItem -LiteralPath "$project/src","$build/generated" -Filter '*.java' -Recurse | ForEach-Object FullName)
& (Tool 'javac') -encoding UTF-8 --release 8 -classpath $androidJar -d "$build/classes" @sources
Check-Exit
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory("$build/classes","$build/classes.jar")
& (Tool 'java') -cp "$bt/lib/d8.jar" com.android.tools.r8.D8 --min-api 26 --lib $androidJar --output "$build/dex" "$build/classes.jar"
Check-Exit
Copy-Item -LiteralPath "$build/resources.apk" -Destination "$build/unsigned.apk"
$zip = [IO.Compression.ZipFile]::Open("$build/unsigned.apk",[IO.Compression.ZipArchiveMode]::Update)
try { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,"$build/dex/classes.dex",'classes.dex') } finally { $zip.Dispose() }
& "$bt/zipalign.exe" -f 4 "$build/unsigned.apk" "$build/aligned.apk"
Check-Exit
if ($Keystore) {
    if (-not $env:DDNS_STORE_PASS -or -not $env:DDNS_KEY_PASS) { throw 'Signing requires DDNS_STORE_PASS and DDNS_KEY_PASS environment variables.' }
    $signArgs = @('--ks',$Keystore,'--ks-key-alias',$KeyAlias,'--ks-pass','env:DDNS_STORE_PASS','--key-pass','env:DDNS_KEY_PASS')
    $apk = Join-Path $out 'ddns-go-assistant.apk'
} else {
    # Local test key only. It is generated in ignored output and is never a release identity.
    $debugKey = Join-Path $out 'debug.keystore'
    if (-not (Test-Path -LiteralPath $debugKey)) {
        & (Tool 'keytool') -genkeypair -keystore $debugKey -storepass android -keypass android -alias androiddebugkey -dname 'CN=Android Debug' -keyalg RSA -keysize 2048 -validity 10000 -noprompt
        Check-Exit
    }
    $signArgs = @('--ks',$debugKey,'--ks-key-alias','androiddebugkey','--ks-pass','pass:android','--key-pass','pass:android')
    $apk = Join-Path $out 'ddns-go-assistant-debug.apk'
}
& (Tool 'java') -jar "$bt/lib/apksigner.jar" sign @signArgs --out $apk "$build/aligned.apk"
Check-Exit
& (Tool 'java') -jar "$bt/lib/apksigner.jar" verify $apk
Check-Exit
Get-Item -LiteralPath $apk | Select-Object FullName,Length
