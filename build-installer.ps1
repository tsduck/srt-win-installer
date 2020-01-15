<#
 .SYNOPSIS

  Build the pthread-win32 binary installer for Windows.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding()]
param([switch]$NoPause = $false)

# Project directories.
$RootDir = $PSScriptRoot
$BinDir = "$RootDir\bin"

# Get version strings.
$VersionInfo = ((Get-Content "$RootDir\pthread.h" | Select-String -Pattern "#define PTW32_VERSION ").ToString() -replace "#define PTW32_VERSION *","" -replace ",",".")
$Version = $VersionInfo -replace "\.0$",""

# A function to exit this script.
function Exit-Script
{
    param(
        [Parameter(Mandatory=$false,Position=1)][String] $Message = "",
        [switch]$NoPause = $false
    )

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
$NSIS = Get-Item "C:\Program Files*\NSIS\makensis.exe" | ForEach-Object { $_.FullName} | Select-Object -Last 1
if (-not $NSIS) {
    Exit-Script -NoPause:$NoPause "NSIS not found"
}

# Locate MSBuild.exe, regardless of Visual Studion version.
$MSRoots = @("C:\Program Files*\MSBuild", "C:\Program Files*\Microsoft Visual Studio")
$MSBuild = Get-ChildItem -Recurse -Path $MSRoots -Include MSBuild.exe -ErrorAction Ignore |
    ForEach-Object { (Get-Command $_).FileVersionInfo } |
    Sort-Object -Unique -Property FileVersion |
    ForEach-Object { $_.FileName} |
    Select-Object -Last 1
if (-not $MSBuild) {
    Exit-Script -NoPause:$NoPause "MSBuild not found"
}

# Build libraries for one configuration and platform.
function Build-Library ([string] $Configuration, [string] $Platform)
{
    & $MSBuild "$RootDir\pthread.multiversion.sln" /nologo /maxcpucount /property:Configuration=$Configuration /property:Platform=$Platform /target:"pthread_dll;pthread_lib"
}

# Build libraries
Build-Library Release x64
Build-Library Release Win32
Build-Library Debug x64
Build-Library Debug Win32

# Build the binary installer.
& $NSIS /V2 /DVersion=$Version /DVersionInfo=$VersionInfo "$RootDir\pthread-win32.nsi" 

Exit-Script -NoPause:$NoPause
