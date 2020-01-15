<#
 .SYNOPSIS

  Build the SRT static libraries installer for Windows.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding()]
param([switch]$NoPause = $false)

Write-Output "SRT libraries installer build procedure"

# Project directories.
$RootDir = $PSScriptRoot

# Get version strings.
$VersionFile = "$RootDir\external\srt.build.x64\version.h"
$Major = ((Get-Content $VersionFile | Select-String -Pattern "#define SRT_VERSION_MAJOR ").ToString() -replace "#define SRT_VERSION_MAJOR *","")
$Minor = ((Get-Content $VersionFile | Select-String -Pattern "#define SRT_VERSION_MINOR ").ToString() -replace "#define SRT_VERSION_MINOR *","")
$Patch = ((Get-Content $VersionFile | Select-String -Pattern "#define SRT_VERSION_PATCH ").ToString() -replace "#define SRT_VERSION_PATCH *","")
$Version = "${Major}.${Minor}.${Patch}"
$VersionInfo = "${Major}.${Minor}.${Patch}.0"
Write-Output "SRT version is $Version"

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

# Locate NSIS, the Nullsoft Scriptable Installation System.
Write-Output "Searching NSIS ..."
$NSIS = Get-Item "C:\Program Files*\NSIS\makensis.exe" | ForEach-Object { $_.FullName} | Select-Object -Last 1
if (-not $NSIS) {
    Exit-Script "NSIS not found"
}

# Create the directory for installers when necessary.
[void] (New-Item -Path "$RootDir\installers" -ItemType Directory -Force)

# Build the binary installer.
Write-Output "Building installer ..."
& $NSIS /V2 /DVersion=$Version /DVersionInfo=$VersionInfo "$RootDir\libsrt.nsi" 

Exit-Script -NoPause:$NoPause
