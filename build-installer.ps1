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

 .PARAMETER BareVersion

  Use the "bare version" number from libsrt (in file version.h). This is the
  most recent official version number. Since there are likely some commits
  in the libsrt repository since the last commit, this may not be the most
  appropriate version number. By default, use a detailed version number
  (most recent version, number of commits since then, short commit SHA).

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding()]
param(
    [switch]$BareVersion = $false,
    [switch]$NoPause = $false
)

Write-Output "SRT libraries installer build procedure"

# Project directories.
$RootDir = $PSScriptRoot

# Get version strings.
$Version = (& "$PSScriptRoot\get-srt-version.ps1" -BareVersion:$BareVersion)
$VersionInfo = (& "$PSScriptRoot\get-srt-version.ps1" -BareVersion:$BareVersion -Windows)
Write-Output "SRT version is $Version, Windows version info is $VersionInfo"

# A function to exit this script.
function Exit-Script([string]$Message = "")
{
    $Code = 0
    if ($Message -ne "") {
        Write-Output "ERROR: $Message"
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
