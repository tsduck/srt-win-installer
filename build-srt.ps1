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

  Build the SRT library for Windows.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding()]
param([switch]$NoPause = $false)

Write-Output "SRT build procedure"
$RepoUrl = "https://github.com/Haivision/srt.git"

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
$ExtDir = "$RootDir\external"
$RepoDir = "$ExtDir\srt"

# Create the directory for external products when necessary.
[void](New-Item -Path $ExtDir -ItemType Directory -Force)

# Locate pthread from local build dir.
$PthreadRoot = "$ExtDir\pthread-win32"
$PthreadInclude = $PthreadRoot
$PthreadHeader = "$PthreadInclude\pthread.h"
$PthreadLibrary = @{
    "x64" = "$PthreadRoot\bin\x64-Release\pthread_lib.lib";
    "Win32" = "$PthreadRoot\bin\Win32-Release\pthread_lib.lib"
}

# Locate OpenSSL root from local installation.
$SslRoot = @{
    "x64" = "C:\Program Files\OpenSSL-Win64";
    "Win32" = "C:\Program Files (x86)\OpenSSL-Win32"
}

# Verify a few files.
$Missing = 0
foreach ($file in @($PthreadHeader, $PthreadLibrary["x64"], $PthreadLibrary["Win32"], $SslRoot["x64"], $SslRoot["Win32"])) {
    if (-not (Test-Path $file)) {
        Write-Output "**** Missing $file"
        $Missing = $Missing + 1
    }
}
if ($Missing -gt 0) {
    Exit-Script "Missing $Missing files"
}

# Clone repository or update it.
if (Test-Path "$RepoDir\.git") {
    # The repo is already cloned, just update it.
    Write-Output "Updating repository ..."
    Push-Location $RepoDir
    git pull
}
else {
    # Clone the repo. Note that git clone outputs its log on stderr, so use --quiet.
    Write-Output "Cloning $RepoUrl ..."
    git clone --quiet $RepoUrl $RepoDir
    if (-not (Test-Path "$RepoDir\.git")) {
        Exit-Script "Failed to clone $RepoUrl"
    }
    Push-Location $RepoDir
}
Pop-Location

# Locate MSBuild and CMake, regardless of Visual Studio version.
Write-Output "Searching MSBuild and CMake ..."
$MSRoots = @("C:\Program Files*\MSBuild", "C:\Program Files*\Microsoft Visual Studio")
$MSBuild = Get-ChildItem -Recurse -Path $MSRoots -Include MSBuild.exe -ErrorAction Ignore |
    ForEach-Object { (Get-Command $_).FileVersionInfo } |
    Sort-Object -Unique -Property FileVersion |
    ForEach-Object { $_.FileName} |
    Select-Object -Last 1
if (-not $MSBuild) {
    Exit-Script "MSBuild not found"
}
$CMake = Get-ChildItem -Recurse -Path $MSRoots -Include cmake.exe -ErrorAction Ignore |
    ForEach-Object { (Get-Command $_).FileVersionInfo } |
    Sort-Object -Unique -Property FileVersion |
    ForEach-Object { $_.FileName} |
    Select-Object -Last 1
if (-not $CMake) {
    Exit-Script "CMake not found"
}

# Configure and build SRT library using CMake on two architectures.
foreach ($Platform in @("x64", "Win32")) {

    # Build directory:
    $SrtBuildDir = "$RepoDir.build.$Platform"
    [void](New-Item -Path $SrtBuildDir -ItemType Directory -Force)

    Write-Output "Configuring build for platform $Platform ..."
    $PLib = $PthreadLibrary[$Platform]
    $SRoot = $SslRoot[$Platform]
    & $CMake -S $RepoDir -B $SrtBuildDir -A $Platform `
        -DPTHREAD_INCLUDE_DIR="$PthreadInclude" `
        -DPTHREAD_LIBRARY="$Plib" `
        -DOPENSSL_ROOT_DIR="$SRoot" `        -DOPENSSL_LIBRARIES="$SRoot\lib\libssl_static.lib;$SRoot\lib\libcrypto_static.lib" `
        -DOPENSSL_INCLUDE_DIR="$SRoot\include"

    Write-Output "Building for platform $Platform ..."
    foreach ($Conf in @("Release", "Debug")) {
        & $MSBuild "$SrtBuildDir\SRT.sln" /nologo /maxcpucount /property:Configuration=$Conf /property:Platform=$Platform /target:srt_static
    }
}

# Verify the presence of compiled libraries.
Write-Output "Checking compiled libraries ..."
$Missing = 0
foreach ($Conf in @("Release", "Debug")) {
    foreach ($Platform in @("x64", "Win32")) {
        $Path = "$RepoDir.build.$Platform\$Conf\srt_static.lib"
        if (-not (Test-Path $Path)) {
            Write-Output "**** Missing $Path"
            $Missing = $Missing + 1
        }
    }
}
if ($Missing -gt 0) {
    Exit-Script "Missing $Missing files"
}

Exit-Script
