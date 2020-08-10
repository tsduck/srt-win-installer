## SRT Installer for Windows

[SRT](https://www.srtalliance.org/) is the Secure Reliable Transport protocol.

This repository contains scripts to build a binary installer for
[libsrt](https://github.com/Haivision/srt/) on Windows systems for
Visual Studio applications using SRT.

This repository does not contain any third-party source code, neither libsrt
nor any of its dependencies. It contains only scripts and configuration files
which download third-party source code when necessary and build it.

### Rationale

The SRT library is easily compiled on Unix systems. Most Linux distros already
include a package for libsrt or are about to do it. On macOS, libsrt is available
through Homebrew, the macOS installer for open-source projects.

But, on Windows systems, including libsrt in an application is a pain, a huge pain.
The intructions for building libsrt on Windows in the
[README file](https://github.com/Haivision/srt/blob/master/README.md)
are sloppy, not to say lousy.

However, serious software engineering requires build automation and continuous
integration. How can you setup build automation for a Windows application using
libsrt? The answer is simple, you can't.

This project tries to solves this issue by providing tools and scripts to build
a binary installer for a development environment for libsrt, namely C/C++ header
files and static libraries for 64 and 32 bits applications, in release and debug
configurations.

Why not providing libsrt DLL's in addition to static libraries? It is a choice which
may change. On Windows, libsrt relies on OpenSSL. If a Windows application is linked
against a libsrt DLL, deploying this application means embedding and deploying
at least two third-party DLL's in addition to libsrt DLL's. This complicates
the deployment and creates risks of inconsistencies. With static libraries, the
application is fully autonomous and no third party DLL is necessary.

### Building Windows applications with libsrt

After installing the libsrt binary, an environment variable named `LIBSRT` is
defined to the installation root (typically `C:\Program Files (x86)\libsrt`).

In this directory, there is a Visual Studio property file named `libsrt.props`.
Simply reference this property file in your Visual Studio project to use libsrt.

You can also do that manually by editing the application project file (the XML
file named with a `.vcxproj` extension). Add the following line just before
the end of the file:

~~~
  <Import Project="$(LIBSRT)\libsrt.props"/>
~~~

### Building the installer

The binary installers are available in the
[release](https://github.com/tsduck/srt-win-installer/releases)
section of this project.

If you want to rebuild the installer yourself, follow these instructions.
The first two steps need to be executed once only. Only the last step needs
to be repeated each time a new version of libsrt is available.

- Prerequisite 1: Install OpenSSL for Windows, both 64 and 32 bits.
  This can be done automatically by running the PowerShell script `install-openssl.ps1`.
- Prerequisite 2: Install NSIS, the NullSoft Installation Scripting system.
  This can be done automatically by running the PowerShell script `install-nsis.ps1`.
- Build the libsrt installer by running the PowerShell script `build-all.ps1`.

That's all. It's just automation...
