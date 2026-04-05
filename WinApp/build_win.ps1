param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Standalone", "Lightweight")]
    [string]$Mode = "Standalone"
)

# VTubeLink Windows Build & Packaging Script
$AppName = "VTubeLink"
$DistDir = "..\dist"
$IconSource = "app_icon.png"
$IconOutput = "app_icon.ico"

Write-Host "=== Building VTubeLink (Mode: $Mode) ===" -ForegroundColor Cyan

# 1. Generate Multi-Resolution Icon
if (Test-Path $IconSource) {
    Write-Host "Generating multi-resolution icon..." -ForegroundColor Yellow
    
    $TempDir = "icon_gen_temp"
    if (Test-Path $TempDir) { Remove-Item -Recurse -Force $TempDir }
    New-Item -ItemType Directory -Path $TempDir | Out-Null
    
    Copy-Item "Helpers\icon_gen.cs" "$TempDir\Program.cs"
    
    $ProjContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0-windows</TargetFramework>
    <UseWindowsForms>true</UseWindowsForms>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
"@
    $ProjContent | Out-File "$TempDir\icon_gen.csproj" -Encoding utf8
    
    Copy-Item $IconSource "$TempDir\$IconSource"
    dotnet run --project $TempDir
    
    if (Test-Path "$TempDir\$IconOutput") {
        Copy-Item "$TempDir\$IconOutput" "."
        Write-Host "Icon generated successfully." -ForegroundColor Green
    }
    
    Remove-Item -Recurse -Force $TempDir
}

# 2. Build and Publish
if (Test-Path $DistDir) { Remove-Item -Recurse -Force $DistDir }

$PublishArgs = @("publish", "-c", "Release", "-o", $DistDir)

if ($Mode -eq "Standalone") {
    Write-Host "Mode: Standalone (Self-Contained Single File)..." -ForegroundColor Yellow
    $PublishArgs += "-r", "win-x64"
    $PublishArgs += "--self-contained", "true"
    $PublishArgs += "-p:PublishSingleFile=true"
    $PublishArgs += "-p:IncludeNativeLibrariesForSelfExtract=true"
} else {
    Write-Host "Mode: Lightweight (Framework Dependent Single File)..." -ForegroundColor Yellow
    $PublishArgs += "--self-contained", "false"
    $PublishArgs += "-p:PublishSingleFile=true"
}

# General optimizations
$PublishArgs += "-p:PublishReadyToRun=false"
$PublishArgs += "-p:DebugType=none"
$PublishArgs += "-p:DebugSymbols=false"

dotnet @PublishArgs

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green

if (Test-Path "$DistDir\VTubeLink.exe") {
    $fileSize = (Get-Item "$DistDir\VTubeLink.exe").Length / 1MB
    Write-Host "Executable: $(Get-Item $DistDir)\VTubeLink.exe" -ForegroundColor Cyan
    Write-Host "File Size:  $($fileSize.ToString("F2")) MB" -ForegroundColor Gray
} else {
    Write-Error "Build failed: VTubeLink.exe not found"
}
