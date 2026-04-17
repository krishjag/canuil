#!/usr/bin/env pwsh
# Canuil bootstrap — downloads the ilasm NuGet package for the current OS and
# extracts it to tools/ilasm-pkg/. Run once after cloning; build.ps1 depends
# on the output. PowerShell 7+ required.
#
# Usage (run from the repo root):
#   ./scripts/bootstrap.ps1           # download if missing
#   ./scripts/bootstrap.ps1 -Force    # re-download even if present

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Map OS to RID + binary name used by the runtime.*.Microsoft.NETCore.ILAsm
# NuGet packages.
if ($IsWindows) {
    $rid = 'win-x64';   $ilasmName = 'ilasm.exe'
} elseif ($IsLinux) {
    $rid = 'linux-x64'; $ilasmName = 'ilasm'
} elseif ($IsMacOS) {
    $rid = 'osx-x64';   $ilasmName = 'ilasm'
} else {
    throw "Unsupported platform."
}

$pkgId      = "runtime.$rid.Microsoft.NETCore.ILAsm"
$pkgVersion = '10.0.0'

$root    = Split-Path -Parent $PSScriptRoot
$toolDir = Join-Path $root 'tools'
$nupkg   = Join-Path $toolDir 'ilasm.nupkg'
$extract = Join-Path $toolDir 'ilasm-pkg'
$ilasm   = Join-Path $extract "runtimes/$rid/native/$ilasmName"

if ((Test-Path $ilasm) -and -not $Force) {
    Write-Host "ilasm already bootstrapped at $ilasm"
    return
}

New-Item -ItemType Directory -Force -Path $toolDir | Out-Null

$url = "https://api.nuget.org/v3-flatcontainer/$($pkgId.ToLower())/$pkgVersion/$($pkgId.ToLower()).$pkgVersion.nupkg"
Write-Host "Downloading $url"
Invoke-WebRequest -Uri $url -OutFile $nupkg

if (Test-Path $extract) { Remove-Item -Recurse -Force $extract }
Write-Host "Extracting to $extract"
Expand-Archive -Path $nupkg -DestinationPath $extract -Force

if (-not (Test-Path $ilasm)) {
    throw "Bootstrap failed: $ilasm not present after extraction."
}

# Expand-Archive doesn't preserve POSIX execute bits from NuGet zip entries.
if (-not $IsWindows) {
    & chmod +x $ilasm
}

Write-Host "ilasm ready at $ilasm"
