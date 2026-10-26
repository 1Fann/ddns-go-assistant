$ErrorActionPreference = 'Stop'
$version = '6.17.7'
$expected = '1e9dd881e81e5043820f145a82d0df71bfe9b66f4a4d8813bdea5a7f131925fd'
$dist = Join-Path $PSScriptRoot 'dist'
$bundle = Join-Path $dist 'ddns-go-root-runtime'
New-Item -ItemType Directory -Force -Path $dist,$bundle | Out-Null
$archive = Join-Path $dist "ddns-go_${version}_android_arm64.tar.gz"
$url = "https://github.com/jeessy2/ddns-go/releases/download/v$version/ddns-go_${version}_android_arm64.tar.gz"
Invoke-WebRequest -Uri $url -OutFile $archive
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw 'Upstream archive checksum mismatch. Nothing installed.' }
& tar -xzf $archive -C $bundle ddns-go
if ($LASTEXITCODE -ne 0) { throw 'Unable to extract the verified ARM64 engine.' }
Copy-Item -Path (Join-Path $PSScriptRoot 'runtime/*') -Destination $bundle -Force
$zip = Join-Path $dist 'ddns-go-root-runtime.zip'
Compress-Archive -Path $bundle -DestinationPath $zip -Force
Get-FileHash -LiteralPath $zip -Algorithm SHA256
Write-Output 'Runtime prepared. No phone changes were made.'
