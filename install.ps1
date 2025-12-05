# PowerShell installation script for codex-wrapper on Windows
# This script compiles codex-wrapper from source and installs it to ~/bin

$ErrorActionPreference = "Stop"

Write-Host "======================================"
Write-Host "codex-wrapper Windows Installation"
Write-Host "======================================"
Write-Host ""

# Check if Go is installed
Write-Host "Checking Go installation..."
try {
    $goVersion = & go version 2>&1
    Write-Host "Found Go: $goVersion"
} catch {
    Write-Host "ERROR: Go is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Go from https://go.dev/dl/" -ForegroundColor Yellow
    exit 1
}

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$codexWrapperDir = Join-Path $scriptDir "codex-wrapper"

# Check if codex-wrapper source directory exists
if (-not (Test-Path $codexWrapperDir)) {
    Write-Host "ERROR: codex-wrapper source directory not found at: $codexWrapperDir" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Compiling codex-wrapper from source..."
Push-Location $codexWrapperDir

try {
    # Compile the binary
    & go build -o codex-wrapper.exe .
    if ($LASTEXITCODE -ne 0) {
        throw "Go build failed with exit code $LASTEXITCODE"
    }

    if (-not (Test-Path "codex-wrapper.exe")) {
        throw "Build succeeded but codex-wrapper.exe was not created"
    }

    Write-Host "Compilation successful!" -ForegroundColor Green

} catch {
    Write-Host "ERROR: Failed to compile codex-wrapper: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Create ~/bin directory
$binDir = Join-Path $env:USERPROFILE "bin"
Write-Host ""
Write-Host "Installing to: $binDir"

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    Write-Host "Created directory: $binDir"
}

# Move the binary
$targetPath = Join-Path $binDir "codex-wrapper.exe"
try {
    Move-Item -Path "codex-wrapper.exe" -Destination $targetPath -Force
    Write-Host "Installed codex-wrapper.exe to: $targetPath" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to move binary to $targetPath : $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Verify installation
Write-Host ""
Write-Host "Verifying installation..."
try {
    $version = & $targetPath --version 2>&1
    Write-Host "Installation verified: $version" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Installation verification failed" -ForegroundColor Red
    exit 1
}

# Check if ~/bin is in PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$binDirNormalized = $binDir.TrimEnd('\')

if ($userPath -notlike "*$binDirNormalized*") {
    Write-Host ""
    Write-Host "WARNING: $binDir is not in your PATH" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To add it permanently, run the following command in PowerShell (as Administrator):"
    Write-Host ""
    Write-Host "    `$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')" -ForegroundColor Cyan
    Write-Host "    [Environment]::SetEnvironmentVariable('Path', `"`$currentPath;$binDir`", 'User')" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or add it manually through System Properties > Environment Variables"
    Write-Host ""
    Write-Host "After adding to PATH, restart your terminal for changes to take effect."
} else {
    Write-Host ""
    Write-Host "PATH is already configured correctly." -ForegroundColor Green
}

Write-Host ""
Write-Host "======================================"
Write-Host "Installation completed successfully!"
Write-Host "======================================"

exit 0
