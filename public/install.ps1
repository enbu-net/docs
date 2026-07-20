$ErrorActionPreference = 'Stop'

$Repo = "enbu-net/enbu"
$Binary = "enbu.exe"

# Resolve install directory
if ($env:ENBU_INSTALL_DIR) {
    $InstallDir = $env:ENBU_INSTALL_DIR
} else {
    $InstallDir = Join-Path $env:LOCALAPPDATA "enbu\bin"
}

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

# Fetch latest version
$Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
$Version = $Release.tag_name -replace '^v', ''

if (-not $Version) {
    Write-Error "Failed to fetch latest version"
    exit 1
}

# Download and extract
$Zip = "enbu_${Version}_windows_amd64.zip"
$Url = "https://github.com/$Repo/releases/download/v$Version/$Zip"
$TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

try {
    Write-Host "Downloading enbu v$Version (windows/amd64)..."
    Invoke-WebRequest -Uri $Url -OutFile (Join-Path $TmpDir $Zip) -UseBasicParsing
    Expand-Archive -Path (Join-Path $TmpDir $Zip) -DestinationPath $TmpDir
    Copy-Item (Join-Path $TmpDir $Binary) (Join-Path $InstallDir $Binary) -Force
} finally {
    Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}

# Add to PATH if needed
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$UserPath;$InstallDir", "User")
    $env:PATH = "$env:PATH;$InstallDir"
    Write-Host "Added $InstallDir to PATH"
    Write-Host "Open a new terminal to use enbu"
}

Write-Host "enbu v$Version installed to $InstallDir\$Binary"
