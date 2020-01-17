<#
 .SYNOPSIS

  Build everything for the SRT static libraries installer for Windows.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding()]
param([switch]$NoPause = $false)

& "$PSScriptRoot\build-pthread.ps1" -NoPause
& "$PSScriptRoot\build-srt.ps1" -NoPause
& "$PSScriptRoot\build-installer.ps1" -NoPause

if (-not $NoPause) {
    pause
}
