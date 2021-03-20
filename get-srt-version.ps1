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

  Get the version string of the SRT library.

 .PARAMETER BareVersion

  Use the "bare version" number from libsrt (in file version.h). This is the
  most recent official version number. Since there are likely some commits
  in the libsrt repository since the last commit, this may not be the most
  appropriate version number. By default, use a detailed version number
  (most recent version, number of commits since then, short commit SHA).

 .PARAMETER Windows

  Return a "version info" string for Windows executable.
#>
[CmdletBinding()]
param(
    [switch]$BareVersion = $false,
    [switch]$Windows = $false
)

if ($BareVersion) {
    # Identify from latest version.
    $VersionFile = "$PSScriptRoot\external\srt.build.x64\version.h"
    $Major = ((Get-Content $VersionFile | Select-String -Pattern "#define SRT_VERSION_MAJOR ").ToString() -replace "#define SRT_VERSION_MAJOR *","")
    $Minor = ((Get-Content $VersionFile | Select-String -Pattern "#define SRT_VERSION_MINOR ").ToString() -replace "#define SRT_VERSION_MINOR *","")
    $Patch = ((Get-Content $VersionFile | Select-String -Pattern "#define SRT_VERSION_PATCH ").ToString() -replace "#define SRT_VERSION_PATCH *","")
    $Version = "${Major}.${Minor}.${Patch}"
    $VersionInfo = "${Major}.${Minor}.${Patch}.0"
}
else {
    Push-Location "$PSScriptRoot\external\srt"
    $Version = (git describe --tags ) -replace '^v','' -replace '-g','-'
    Pop-Location
    # Split version string in pieces and make sure it has at least four elements.
    $VField = ($Version -split "[-\. ]") + @("0", "0", "0", "0") | Select-String -Pattern '^\d*$'
    $VersionInfo = "$($VField[0]).$($VField[1]).$($VField[2]).$($VField[3])"
}

if ($Windows) {
    Write-Output $VersionInfo
}
else {
    Write-Output $Version
}
