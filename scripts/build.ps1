#!/usr/bin/env pwsh
# Canuil build — assembles pure IL sources, verifies them, runs tests.
# Runs on Windows, Linux, or macOS with PowerShell 7+ and .NET 10 installed.
#
# Usage (run from the repo root):
#   ./scripts/build.ps1                   # Build + Verify (default)
#   ./scripts/build.ps1 -Target Build     # just assemble
#   ./scripts/build.ps1 -Target Verify    # just verify already-built outputs
#   ./scripts/build.ps1 -Target Test      # build, verify, run tests
#   ./scripts/build.ps1 -Target Run       # build, verify, run Canuil.App

param(
    [ValidateSet('Build','Verify','Test','Run','All')]
    [string]$Target = 'All',
    [string[]]$AppArgs = @()
)

$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root 'src'
$outDir = Join-Path $root 'build'

# Pick the right ilasm binary for this OS (bootstrap.ps1 dropped the matching
# runtime.<rid>.Microsoft.NETCore.ILAsm package into tools/ilasm-pkg/).
if ($IsWindows) {
    $ilasm = Join-Path $root 'tools/ilasm-pkg/runtimes/win-x64/native/ilasm.exe'
} elseif ($IsLinux) {
    $ilasm = Join-Path $root 'tools/ilasm-pkg/runtimes/linux-x64/native/ilasm'
} elseif ($IsMacOS) {
    $ilasm = Join-Path $root 'tools/ilasm-pkg/runtimes/osx-x64/native/ilasm'
} else {
    throw "Unsupported platform."
}
if (-not (Test-Path $ilasm)) {
    throw "ilasm not found at $ilasm. Run ./scripts/bootstrap.ps1 first."
}

# Runtime pack (for BCL reference DLLs when verifying). Parses `dotnet
# --list-runtimes` so the same lookup works on Windows, Linux, and macOS.
$runtimePack = $null
$latestVersion = $null
foreach ($line in (& dotnet --list-runtimes)) {
    if ($line -match '^Microsoft\.NETCore\.App (10\.0\.\S+) \[(.+)\]$') {
        $v = [version]$matches[1]
        if (-not $latestVersion -or $v -gt $latestVersion) {
            $latestVersion = $v
            $runtimePack   = Join-Path $matches[2] $matches[1]
        }
    }
}
if (-not $runtimePack) {
    throw "No Microsoft.NETCore.App 10.0.x runtime found (checked 'dotnet --list-runtimes')."
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Description of every module we assemble.
$modules = @(
    [pscustomobject]@{ Name='Canuil.Lib';   Source='Lib/Canuil.Lib.il'; Kind='Dll' },
    [pscustomobject]@{ Name='Canuil.App';   Source='Program.il';        Kind='Dll' },
    [pscustomobject]@{ Name='Canuil.Tests'; Source='Tests/Tests.il';    Kind='Dll' }
)

function Invoke-Ilasm {
    param([string]$source, [string]$output, [string]$kind)
    # Use `-` prefix for flags: Linux/macOS ilasm only recognizes `-`, while
    # Windows ilasm accepts both — so `-` is the portable choice.
    $flag = if ($kind -eq 'Exe') { '-exe' } else { '-dll' }
    Write-Host ">> ilasm $flag $source -> $output"
    # Modernize PE to match what Roslyn produces — helps Smart App Control
    # treat the binary as a normal .NET assembly rather than a "legacy" one:
    #   -X64            PE32+ / AMD64 machine type
    #   -HIGHENTROPYVA  64-bit ASLR capable
    #   -DET            deterministic MVID + timestamps (stable hash)
    & $ilasm $flag -X64 -HIGHENTROPYVA -DET `
             "-output:$output" -optimize -nologo -quiet $source
    if ($LASTEXITCODE -ne 0) { throw "ilasm failed for $source" }
}

function Invoke-IlVerify {
    param([string]$assembly)
    Write-Host ">> ilverify $assembly"
    # References must be enumerated individually. A glob like
    # `-r $runtimePack/*.dll` works on Windows but on Linux ilverify ends up
    # treating the glob-matched files as verification inputs (some BCL DLLs
    # like System.Web.HttpUtility.dll aren't strictly verifiable, so the run
    # fails). Peer DLLs exclude the one under test to avoid
    # "Multiple input files matching same simple name".
    $refArgs = @()
    foreach ($ref in Get-ChildItem -Path $runtimePack -Filter '*.dll') {
        $refArgs += '-r'
        $refArgs += $ref.FullName
    }
    foreach ($peer in Get-ChildItem -Path $outDir -Filter '*.dll') {
        if ($peer.FullName -ne $assembly) {
            $refArgs += '-r'
            $refArgs += $peer.FullName
        }
    }
    & ilverify $assembly @refArgs
    if ($LASTEXITCODE -ne 0) { throw "ilverify failed for $assembly" }
}

function Step-Build {
    foreach ($m in $modules) {
        $src = Join-Path $srcDir $m.Source
        $dst = Join-Path $outDir "$($m.Name).dll"
        Invoke-Ilasm -source $src -output $dst -kind $m.Kind
    }
    Copy-Item (Join-Path $srcDir 'Canuil.App.runtimeconfig.json') `
              (Join-Path $outDir 'Canuil.App.runtimeconfig.json') -Force
    Copy-Item (Join-Path $srcDir 'Tests/Tests.runtimeconfig.json') `
              (Join-Path $outDir 'Canuil.Tests.runtimeconfig.json') -Force
    Write-Host "Build OK."
}

function Step-Verify {
    foreach ($m in $modules) {
        Invoke-IlVerify (Join-Path $outDir "$($m.Name).dll")
    }
    Write-Host "Verify OK."
}

function Step-Test {
    $testDll = Join-Path $outDir 'Canuil.Tests.dll'
    Write-Host ">> dotnet $testDll"
    & dotnet $testDll
    if ($LASTEXITCODE -ne 0) { throw "$LASTEXITCODE test(s) failed." }
    Write-Host "Tests OK."
}

function Step-Run {
    $appDll = Join-Path $outDir 'Canuil.App.dll'
    Write-Host ">> dotnet $appDll $($AppArgs -join ' ')"
    & dotnet $appDll @AppArgs
    if ($LASTEXITCODE -ne 0) { throw "Canuil.App exited with $LASTEXITCODE." }
}

switch ($Target) {
    'Build'  { Step-Build }
    'Verify' { Step-Verify }
    'Test'   { Step-Build; Step-Verify; Step-Test }
    'Run'    { Step-Build; Step-Verify; Step-Run }
    'All'    { Step-Build; Step-Verify }
}
