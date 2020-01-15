<#
 .SYNOPSIS

  Build the pthread library for Windows.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding()]
param([switch]$NoPause = $false)

Write-Output "Pthread-win32 build procedure"
$RepoUrl = "https://github.com/GerHobbelt/pthread-win32.git"

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
$RepoDir = "$ExtDir\pthread-win32"
$BinDir = "$RepoDir\bin"

# Create the directory for external products when necessary.
[void] (New-Item -Path $ExtDir -ItemType Directory -Force)

# Clone pthread-win32 or update it.
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

# The repo contains solutions and project files for different specific versions of
# Visual Studio, but none for recent versions. So, we build a generic multi-version
# one, using the VS2015 files as templates.

Write-Output "Updating Visual Studio project files for multi-version ..."
$SlnIn = "$RepoDir\pthread.2015.sln"
$SlnOut = "$RepoDir\pthread.multiversion.sln"

# 1) Create the multiversion solution file.
Get-Content $SlnIn |
    ForEach-Object { $_ -replace '(.*)\.2015\.(vcxproj.*)','$1.multiversion.$2' } |
    Out-File $SlnOut -Encoding ascii

# 2) Create the multiversion project files.
Select-String -Path $SlnIn -Pattern '".*\.2015\.vcxproj"' |
    ForEach-Object {
        $ProjIn = $_ -replace '.*"([^"]*\.2015\.vcxproj)".*','$1'
        $ProjOut = $ProjIn -replace '\.2015\.','.multiversion.'
        Write-Output "$ProjIn -> $ProjOut"
        Get-Content "$RepoDir\$ProjIn" |
            ForEach-Object {
                if ($_ -match ' *<Import *Project=".*\\Microsoft.Cpp.Default.props".*') {
                    # Insert a reference to the multiversion property sheet.
                    $_
                    '  <Import Project="..\..\visualstudio.multiversion.props"/>'
                }
                elseif (-not ($_ -match ' *<PlatformToolset>v1.*</PlatformToolset> *')) {
                    # Delete lines specifying a specific PlatformToolset version.
                    # Make sure that binary directories are not named after MSVC2015.
                    $_ -replace '_MSVC2015.','-'
                }
            } |
            Out-File "$RepoDir\$ProjOut" -Encoding ascii
    }

# Locate MSBuild.exe, regardless of Visual Studio version.
Write-Output "Searching MSBuild ..."
$MSRoots = @("C:\Program Files*\MSBuild", "C:\Program Files*\Microsoft Visual Studio")
$MSBuild = Get-ChildItem -Recurse -Path $MSRoots -Include MSBuild.exe -ErrorAction Ignore |
    ForEach-Object { (Get-Command $_).FileVersionInfo } |
    Sort-Object -Unique -Property FileVersion |
    ForEach-Object { $_.FileName} |
    Select-Object -Last 1
if (-not $MSBuild) {
    Exit-Script "MSBuild not found"
}

# Build the static libraries only.
Write-Output "Building pthread static libraries ..."
foreach ($Conf in @("Release", "Debug")) {
    foreach ($Platform in @("x64", "Win32")) {
        & $MSBuild $SlnOut /nologo /maxcpucount /property:Configuration=$Conf /property:Platform=$Platform /target:pthread_lib
    }
}

# Verify the presence of compiled libraries.
Write-Output "Checking compiled libraries ..."
$Missing = 0
foreach ($Conf in @("Release", "Debug")) {
    foreach ($Platform in @("x64", "Win32")) {
        $Path = "$RepoDir\bin\$Platform-$Conf\pthread_lib.lib"
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
