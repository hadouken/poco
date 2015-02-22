# Overview

This repository contains the build script to download, build and publish
Poco C++ libraries (incl. NetSSL_OpenSSL) for Hadouken on Windows.

The libraries are built with MSVC-12 (Visual Studio 2013).

## Building

```
PS> .\build.ps1
```

The output (including a NuGet package) is put in the `bin` folder.
