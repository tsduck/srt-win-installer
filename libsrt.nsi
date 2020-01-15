; NSIS script to build the SRT binary installer for Windows.
; Do not invoke NSIS directly, use PowerShell script build-installer.ps1.
;
; Required command-line definitions:
; - Version : Product version.
; - VersionInfo : Product version info in Windows format.

Name "SRT"
Caption "SRT Libraries Installer"

!verbose push
!verbose 0
!include "MUI2.nsh"
!include "Sections.nsh"
!include "TextFunc.nsh"
!include "FileFunc.nsh"
!include "WinMessages.nsh"
!include "x64.nsh"
!verbose pop

!define ProductName   "libsrt"
!define InstallerDir  "installers"
!define RepoDir       "external\srt"
!define Build32Dir    "external\srt.build.Win32"
!define Build64Dir    "external\srt.build.x64"
!define PthreadBinDir "external\pthread-win32\bin"
!define SSL32Dir      "C:\Program Files (x86)\OpenSSL-Win32"
!define SSL64Dir      "C:\Program Files\OpenSSL-Win64"

VIProductVersion ${VersionInfo}
VIAddVersionKey ProductName "${ProductName}"
VIAddVersionKey ProductVersion "${Version}"
VIAddVersionKey Comments "The SRT static libraries for Visual C++ on Windows"
VIAddVersionKey FileVersion "${VersionInfo}"
VIAddVersionKey FileDescription "SRT Installer"

; Name of binary installer file.
OutFile "${InstallerDir}\${ProductName}-${Version}.exe"

; Registry key for environment variables
!define EnvironmentKey '"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

; Registry entry for product info and uninstallation info.
!define ProductKey "Software\${ProductName}"
!define UninstallKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ProductName}"

; Use XP manifest.
XPStyle on

; Request administrator privileges for Windows Vista and higher.
RequestExecutionLevel admin

; "Modern User Interface" (MUI) settings.
!define MUI_ABORTWARNING

; Default installation folder.
InstallDir "$PROGRAMFILES\${ProductName}"

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

    ; Visual Studio property files.
    SetOutPath "$INSTDIR"
    File "libsrt.props"

    ; Header files.
    CreateDirectory "$INSTDIR\include\srt"
    SetOutPath "$INSTDIR\include\srt"
    File "${RepoDir}\srtcore\logging_api.h"
    File "${RepoDir}\srtcore\platform_sys.h"
    File "${RepoDir}\srtcore\srt4udt.h"
    File "${RepoDir}\srtcore\srt.h"
    File "${RepoDir}\srtcore\udt.h"
    File "${Build64Dir}\version.h"

    ; Libraries.
    CreateDirectory "$INSTDIR\lib"
    
    CreateDirectory "$INSTDIR\lib\Release-x64"
    SetOutPath "$INSTDIR\lib\Release-x64"
    File /oname=srt.lib       "${Build64Dir}\Release\srt_static.lib"
    File /oname=pthread.lib   "${PthreadBinDir}\x64-Release\pthread_lib.lib"
    File /oname=libcrypto.lib "${SSL64Dir}\lib\VC\static\libcrypto64MD.lib"
    File /oname=libssl.lib    "${SSL64Dir}\lib\VC\static\libssl64MD.lib"

    CreateDirectory "$INSTDIR\lib\Debug-x64"
    SetOutPath "$INSTDIR\lib\Debug-x64"
    File /oname=srt.lib       "${Build64Dir}\Debug\srt_static.lib"
    File /oname=srt.pdb       "${Build64Dir}\Debug\srt_static.pdb"
    File /oname=pthread.lib   "${PthreadBinDir}\x64-Debug\pthread_lib.lib"
    File /oname=pthread.pdb   "${PthreadBinDir}\x64-Debug\pthread_lib.pdb"
    File /oname=libcrypto.lib "${SSL64Dir}\lib\VC\static\libcrypto64MDd.lib"
    File /oname=libssl.lib    "${SSL64Dir}\lib\VC\static\libssl64MDd.lib"

    CreateDirectory "$INSTDIR\lib\Release-Win32"
    SetOutPath "$INSTDIR\lib\Release-Win32"
    File /oname=srt.lib       "${Build32Dir}\Release\srt_static.lib"
    File /oname=pthread.lib   "${PthreadBinDir}\Win32-Release\pthread_lib.lib"
    File /oname=libcrypto.lib "${SSL32Dir}\lib\VC\static\libcrypto32MD.lib"
    File /oname=libssl.lib    "${SSL32Dir}\lib\VC\static\libssl32MD.lib"

    CreateDirectory "$INSTDIR\lib\Debug-Win32"
    SetOutPath "$INSTDIR\lib\Debug-Win32"
    File /oname=srt.lib       "${Build32Dir}\Debug\srt_static.lib"
    File /oname=srt.pdb       "${Build32Dir}\Debug\srt_static.pdb"
    File /oname=pthread.lib   "${PthreadBinDir}\Win32-Debug\pthread_lib.lib"
    File /oname=pthread.pdb   "${PthreadBinDir}\Win32-Debug\pthread_lib.pdb"
    File /oname=libcrypto.lib "${SSL32Dir}\lib\VC\static\libcrypto32MDd.lib"
    File /oname=libssl.lib    "${SSL32Dir}\lib\VC\static\libssl32MDd.lib"

    ; Add an environment variable to installation root.
    WriteRegStr HKLM ${EnvironmentKey} "LIBSRT" "$INSTDIR"

    ; Store installation folder in registry.
    WriteRegStr HKLM "${ProductKey}" "InstallDir" $INSTDIR

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
 
    ; Declare uninstaller in "Add/Remove Software" control panel
    WriteRegStr HKLM "${UninstallKey}" "DisplayName" "${ProductName}"
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

    ; Delete product registry entries
    DeleteRegKey HKCU "${ProductKey}"
    DeleteRegKey HKLM "${ProductKey}"
    DeleteRegKey HKLM "${UninstallKey}"
    DeleteRegValue HKLM ${EnvironmentKey} "LIBSRT"

    ; Delete product files.
    RMDir /r "$0\include"
    RMDir /r "$0\lib"
    Delete "$0\libsrt.props"
    Delete "$0\Uninstall.exe"
    RMDir "$0"

SectionEnd
