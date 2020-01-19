#-----------------------------------------------------------------------------
#
#  SRT library build procedures for Windows
#  Copyright (c) 2020, Thierry Lelegard
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
#  THE POSSIBILITY OF SUCH DAMAGE.
#
#-----------------------------------------------------------------------------

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
