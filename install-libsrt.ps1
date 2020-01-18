﻿<#
 .SYNOPSIS

  Download and install the libsrt library for Windows.
  This script is provided as an example for Windows applications using
  libsrt which want to automate their build.

 .PARAMETER ForceDownload

  Force a download even if the package is already downloaded.

 .PARAMETER NoInstall

  Do not install the package. By default, libsrt is installed.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$ForceDownload = $false,
    [switch]$NoInstall = $false,
    [switch]$NoPause = $false
)

Write-Output "libsrt download and installation procedure"
$ReleasePage = "https://github.com/tsduck/srt-win-installer/releases/latest"

# A function to exit this script.
function Exit-Script([string]$Message = "")
{
    $Code = 0
    if ($Message -ne "") {
        Write-Host "ERROR: $Message"
        $Code = 1
    }
    if (-not $NoPause) {
        pause
    }
    exit $Code
}

# Local file names.
$RootDir = $PSScriptRoot
$ExtDir = "$RootDir\msvc\tmp"

# Create the directory for external products when necessary.
[void] (New-Item -Path $ExtDir -ItemType Directory -Force)

# Without this, Invoke-WebRequest is awfully slow.
$ProgressPreference = 'SilentlyContinue'

# Get the HTML page for latest libsrt release.
$status = 0
$message = ""
try {
    $response = Invoke-WebRequest -UseBasicParsing -UserAgent Download -Uri $ReleasePage
    $status = [int] [Math]::Floor($response.StatusCode / 100)
}
catch {
    $message = $_.Exception.Message
}

if ($status -ne 1 -and $status -ne 2) {
    # Error fetch NSIS download page.
    if ($message -eq "" -and (Test-Path variable:response)) {
        Exit-Script "Status code $($response.StatusCode), $($response.StatusDescription)"
    }
    else {
        Exit-Script "#### Error accessing ${ReleasePage}: $message"
    }
}

# Parse HTML page to locate the latest installer.
$Ref = $response.Links.href | Where-Object { $_ -like "*/libsrt-*.exe" } | Select-Object -First 1

if (-not $Ref) {
    Exit-Script "Could not find a reference to libsrt installer in ${ReleasePage}"
}

# Build the absolute URL's from base URL (the download page) and href links.
$Url = New-Object -TypeName 'System.Uri' -ArgumentList ([System.Uri]$ReleasePage, $Ref)
$InstallerName = (Split-Path -Leaf $Url.LocalPath)
$InstallerPath = "$ExtDir\$InstallerName"

# Download installer
if (-not $ForceDownload -and (Test-Path $InstallerPath)) {
    Write-Output "$InstallerName already downloaded, use -ForceDownload to download again"
}
else {
    Write-Output "Downloading $Url ..."
    Invoke-WebRequest -UseBasicParsing -UserAgent Download -Uri $Url -OutFile $InstallerPath
    if (-not (Test-Path $InstallerPath)) {
        Exit-Script "$Url download failed"
    }
}

# Install libsrt
if (-not $NoInstall) {
    Write-Output "Installing $InstallerName"
    Start-Process -FilePath $InstallerPath -ArgumentList @("/S") -Wait
}

Exit-Script