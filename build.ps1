# This script will download and build Poco C++ in both debug and
# release configurations.

$PACKAGES_DIRECTORY = Join-Path $PSScriptRoot "packages"
$OUTPUT_DIRECTORY   = Join-Path $PSScriptRoot "bin"
$VERSION            = "0.0.0"

$OPENSSL_PACKAGE_DIRECTORY = Join-Path $PACKAGES_DIRECTORY "hadouken.openssl.0.1.3"

if (Test-Path Env:\APPVEYOR_BUILD_VERSION) {
    $VERSION = $env:APPVEYOR_BUILD_VERSION
}

# Poco configuration section
$POCO_VERSION      = "1.6.0"
$POCO_DIRECTORY    = Join-Path $PACKAGES_DIRECTORY "poco-$POCO_VERSION"
$POCO_PACKAGE_FILE = "poco-$POCO_VERSION-release.zip"
$POCO_DOWNLOAD_URL = "https://github.com/pocoproject/poco/archive/$POCO_PACKAGE_FILE"

# Nuget configuration section
$NUGET_FILE         = "nuget.exe"
$NUGET_TOOL         = Join-Path $PACKAGES_DIRECTORY $NUGET_FILE
$NUGET_DOWNLOAD_URL = "https://nuget.org/$NUGET_FILE"

function Download-File {
    param (
        [string]$url,
        [string]$target
    )

    $webClient = new-object System.Net.WebClient
    $webClient.DownloadFile($url, $target)
}

function Extract-File {
    param (
        [string]$file,
        [string]$target
    )

    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($file, $target)
}

# Create packages directory if it does not exist
if (!(Test-Path $PACKAGES_DIRECTORY)) {
    New-Item -ItemType Directory -Path $PACKAGES_DIRECTORY | Out-Null
}

# Download Poco
if (!(Test-Path (Join-Path $PACKAGES_DIRECTORY $POCO_PACKAGE_FILE))) {
    Write-Host "Downloading $POCO_PACKAGE_FILE"
    Download-File $POCO_DOWNLOAD_URL (Join-Path $PACKAGES_DIRECTORY $POCO_PACKAGE_FILE)
}

# Download Nuget
if (!(Test-Path $NUGET_TOOL)) {
    Write-Host "Downloading $NUGET_FILE"
    Download-File $NUGET_DOWNLOAD_URL $NUGET_TOOL
}

# Unpack Poco
if (!(Test-Path $POCO_DIRECTORY)) {
    Write-Host "Unpacking $POCO_PACKAGE_FILE"
    Extract-File (Join-Path $PACKAGES_DIRECTORY $POCO_PACKAGE_FILE) $PACKAGES_DIRECTORY

    Rename-Item (Join-Path $PACKAGES_DIRECTORY poco-poco-$POCO_VERSION-release) $POCO_DIRECTORY

    # Move the modified build script to Poco directory
    Rename-Item (Join-Path $POCO_DIRECTORY "buildwin.ps1") (Join-Path $POCO_DIRECTORY "buildwin.ps1.old")
    Copy-Item ".\poco-1.6.0-buildwin.ps1" (Join-Path $POCO_DIRECTORY "buildwin.ps1")
}

# Install support package OpenSSL
& "$NUGET_TOOL" install hadouken.openssl -Version 0.1.3 -OutputDirectory "$PACKAGES_DIRECTORY"

function Compile-Poco {
    param (
        [string]$platform,
        [string]$configuration
    )

    Push-Location $POCO_DIRECTORY

    $openssl = (Join-Path $OPENSSL_PACKAGE_DIRECTORY "$platform/$configuration")
    .\buildwin.ps1 -Platform $platform -Omit Data/MySQL -config $configuration -OpenSSL $openssl

    Pop-Location
}

function Output-Poco {
    param (
        [string]$platform,
        [string]$configuration
    )

    Push-Location $POCO_DIRECTORY

    # Copy output files
    xcopy /y "bin\*.dll" "$OUTPUT_DIRECTORY\$platform\bin\"
    xcopy /y "bin\*.pdb" "$OUTPUT_DIRECTORY\$platform\bin\"
    xcopy /y "lib\*.lib" "$OUTPUT_DIRECTORY\$platform\lib\"

    Pop-Location
}

Compile-Poco "win32" "debug"
Output-Poco  "win32" "debug"

Compile-Poco "win32" "release"
Output-Poco  "win32" "release"

# Copy include folders
xcopy /y "$POCO_DIRECTORY\Crypto\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\Data\ODBC\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\Data\SQLite\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\Foundation\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\JSON\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\MongoDB\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\Net\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\NetSSL_OpenSSL\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\PDF\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\Util\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\XML\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E
xcopy /y "$POCO_DIRECTORY\Zip\include\*" "$OUTPUT_DIRECTORY\win32\include\*" /E

# Package

copy hadouken.poco.nuspec $OUTPUT_DIRECTORY

pushd $OUTPUT_DIRECTORY
Start-Process "$NUGET_TOOL" -ArgumentList "pack hadouken.poco.nuspec -Properties version=$VERSION" -Wait -NoNewWindow
popd
