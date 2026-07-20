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

# Download zip and checksums
$Zip = "enbu_${Version}_windows_amd64.zip"
$BaseUrl = "https://github.com/$Repo/releases/download/v$Version"
$TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

try {
    Write-Host "Downloading enbu v$Version (windows/amd64)..."
    Invoke-WebRequest -Uri "$BaseUrl/$Zip" -OutFile (Join-Path $TmpDir $Zip) -UseBasicParsing
    Invoke-WebRequest -Uri "$BaseUrl/checksums.txt" -OutFile (Join-Path $TmpDir "checksums.txt") -UseBasicParsing

    # Verify checksum
    Write-Host "Verifying checksum..."
    $ChecksumsContent = Get-Content (Join-Path $TmpDir "checksums.txt")
    $ExpectedLine = $ChecksumsContent | Where-Object { $_ -match " $Zip$" }
    if (-not $ExpectedLine) {
        throw "Checksum not found for $Zip"
    }
    $Expected = ($ExpectedLine -split '\s+')[0]
    $Actual = (Get-FileHash (Join-Path $TmpDir $Zip) -Algorithm SHA256).Hash.ToLower()
    if ($Actual -ne $Expected) {
        throw "Checksum mismatch`n  expected: $Expected`n  actual:   $Actual"
    }
    Write-Host "Checksum OK"

    # Verify sigstore signature (optional, requires cosign)
    if (Get-Command cosign -ErrorAction SilentlyContinue) {
        Write-Host "Verifying sigstore signature..."
        Invoke-WebRequest -Uri "$BaseUrl/checksums.txt.sigstore.json" -OutFile (Join-Path $TmpDir "checksums.txt.sigstore.json") -UseBasicParsing
        cosign verify-blob `
            --bundle (Join-Path $TmpDir "checksums.txt.sigstore.json") `
            --certificate-identity-regexp "https://github.com/enbu-net/enbu/" `
            --certificate-oidc-issuer "https://token.actions.githubusercontent.com" `
            (Join-Path $TmpDir "checksums.txt")
        Write-Host "Sigstore verification OK"
    }

    # Extract and install
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
