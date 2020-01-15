; NSIS script to build the pthread-win32 binary installer for Windows.
; Do not invoke NSIS directly, use PowerShell script build-installer.ps1.
;
; Required command-line definitions:
; - Version : Product version.
; - VersionInfo : Product version info in Windows format.

Name "Pthread-Win32"
Caption "Pthread-Win32 Installer"

!verbose push
!verbose 0
!include "MUI2.nsh"
!include "Sections.nsh"
!include "TextFunc.nsh"
!include "FileFunc.nsh"
!include "WinMessages.nsh"
!include "x64.nsh"
!verbose pop

VIProductVersion ${VersionInfo}
VIAddVersionKey ProductName "Pthread-Win32"
VIAddVersionKey ProductVersion "${Version}"
VIAddVersionKey Comments "Pthread-Win32 - The pthread libraries for Visual C++ on Windows"
VIAddVersionKey FileVersion "${VersionInfo}"
VIAddVersionKey FileDescription "Pthread-Win32 Installer"

; Name of binary installer file.
OutFile "${InstallerDir}\Pthread-Win32-${Version}.exe"

; Registry key for environment variables
!define EnvironmentKey '"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

; Registry entry for product info and uninstallation info.
!define ProductKey "Software\Pthread-Win32"
!define UninstallKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\Pthread-Win32"

; Use XP manifest.
XPStyle on

; Request administrator privileges for Windows Vista and higher.
RequestExecutionLevel admin

; "Modern User Interface" (MUI) settings.
!define MUI_ABORTWARNING

; Default installation folder.
InstallDir "$PROGRAMFILES\Pthread-Win32"

; Get installation folder from registry if available from a previous installation.
InstallDirRegKey HKLM "${ProductKey}" "InstallDir"

; Installer pages.
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

; Uninstaller pages.
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages.
!insertmacro MUI_LANGUAGE "English"

; Installation initialization.
function .onInit
    ; In 64-bit installers, don't use registry redirection.
    ${If} ${RunningX64}
        SetRegView 64
    ${EndIf}
functionEnd

; Uninstallation initialization.
function un.onInit
    ; In 64-bit installers, don't use registry redirection.
    ${If} ${RunningX64}
        SetRegView 64
    ${EndIf}
functionEnd

; Installation section
Section "Install"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Header files.
    CreateDirectory "$INSTDIR\include"
    SetOutPath "$INSTDIR\include"
    File "pthread.h"

    ; Libraries.
    CreateDirectory "$INSTDIR\lib"
    
    CreateDirectory "$INSTDIR\lib\Release-x64"
    SetOutPath "$INSTDIR\lib\Release-x64"
    File "bin\x64_MSVC.Release\pthread_dll.dll"
    File "bin\x64_MSVC.Release\pthread_dll.lib"
    File "bin\x64_MSVC.Release\pthread_lib.lib"

    CreateDirectory "$INSTDIR\lib\Debug-x64"
    SetOutPath "$INSTDIR\lib\Debug-x64"
    File "bin\x64_MSVC.Debug\pthread_dll.dll"
    File "bin\x64_MSVC.Debug\pthread_dll.lib"
    File "bin\x64_MSVC.Debug\pthread_dll.pdb"
    File "bin\x64_MSVC.Debug\pthread_lib.lib"
    File "bin\x64_MSVC.Debug\pthread_lib.pdb"

    CreateDirectory "$INSTDIR\lib\Debug-Win32"
    SetOutPath "$INSTDIR\lib\Debug-Win32"
    File "bin\Win32_MSVC.Debug\pthread_dll.dll"
    File "bin\Win32_MSVC.Debug\pthread_dll.lib"
    File "bin\Win32_MSVC.Debug\pthread_dll.pdb"
    File "bin\Win32_MSVC.Debug\pthread_lib.lib"
    File "bin\Win32_MSVC.Debug\pthread_lib.pdb"

    CreateDirectory "$INSTDIR\lib\Release-Win32"
    SetOutPath "$INSTDIR\lib\Release-Win32"
    File "bin\Win32_MSVC.Release\pthread_dll.dll"
    File "bin\Win32_MSVC.Release\pthread_dll.lib"
    File "bin\Win32_MSVC.Release\pthread_lib.lib"

    ; Visual Studio property files.
    SetOutPath "$INSTDIR"
    File "${RootDir}\build\pthread-dll.props"
    File "${RootDir}\build\pthread-static.props"

    ; Add an environment variable to Pthread-Win32 root.
    WriteRegStr HKLM ${EnvironmentKey} "PTHREAD_WIN32" "$INSTDIR"

    ; Store installation folder in registry.
    WriteRegStr HKLM "${ProductKey}" "InstallDir" $INSTDIR

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
 
    ; Declare uninstaller in "Add/Remove Software" control panel
    WriteRegStr HKLM "${UninstallKey}" "DisplayName" "Pthread-Win32"
    WriteRegStr HKLM "${UninstallKey}" "DisplayVersion" "${Version}"
    WriteRegStr HKLM "${UninstallKey}" "DisplayIcon" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "${UninstallKey}" "UninstallString" "$INSTDIR\Uninstall.exe"

    ; Get estimated size of installed files
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "${UninstallKey}" "EstimatedSize" "$0"

    ; Notify applications of environment modifications
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

SectionEnd

; Uninstallation section
Section "Uninstall"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Get installation folder from registry
    ReadRegStr $0 HKLM "${ProductKey}" "InstallDir"

    ; Delete start menu entries  
    RMDir /r "$SMPROGRAMS\Pthread-Win32"

    ; Delete product registry entries
    DeleteRegKey HKCU "${ProductKey}"
    DeleteRegKey HKLM "${ProductKey}"
    DeleteRegKey HKLM "${UninstallKey}"
    DeleteRegValue HKLM ${EnvironmentKey} "PTHREAD_WIN32"

    ; Delete product files.
    RMDir /r "$0\include"
    RMDir /r "$0\lib"
    Delete "$0\pthread-dll.props"
    Delete "$0\pthread-static.props"
    Delete "$0\Uninstall.exe"
    RMDir "$0"

SectionEnd
