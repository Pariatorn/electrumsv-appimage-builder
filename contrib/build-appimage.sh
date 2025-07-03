#!/bin/bash
set -ex

# --- AppImage-related variables ---
APP=ElectrumSV
LOWER_APP_NAME=electrumsv
ARCH=$(uname -m)

# We can parameterise this if we want to build for other architectures.
if [ "$ARCH" = "x86_64" ]; then
    LINUXDEPLOY_ARCH="x86_64"
    PYTHON_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    LINUXDEPLOY_ARCH="aarch64"
    PYTHON_ARCH="aarch64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# We can change this to a commit hash if we want to pin to a specific version.
LINUXDEPLOY_VERSION="continuous"
LINUXDEPLOY_PLUGIN_QT_VERSION="continuous"

# Standalone Python version to bundle.
PYTHON_VERSION="3.9.16"
PYTHON_DOWNLOAD_URL="https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-${PYTHON_VERSION}+20230507-x86_64-unknown-linux-gnu-install_only.tar.gz"


# --- Build-related variables ---
BUILD_DIR="$(pwd)/build/appimage"
APPDIR="$BUILD_DIR/$APP.AppDir"


# --- Functions ---

# Download and make linuxdeploy and the qt plugin executable.
# We expect to be in the WORKSPACE_ROOT.
download_linuxdeploy_tools() {
    if [ ! -d "build" ]; then
        mkdir build
    fi
    if [ ! -d "build/appimage" ]; then
        mkdir build/appimage
    fi
    if [ ! -d "$BUILD_DIR/bin" ]; then
        mkdir -p "$BUILD_DIR/bin"
    fi

    pushd "$BUILD_DIR/bin"

    echo "--- Downloading linuxdeploy ---"
    if [ ! -f "linuxdeploy-${LINUXDEPLOY_ARCH}.AppImage" ]; then
        wget -c "https://github.com/linuxdeploy/linuxdeploy/releases/download/${LINUXDEPLOY_VERSION}/linuxdeploy-${LINUXDEPLOY_ARCH}.AppImage"
        chmod +x "linuxdeploy-${LINUXDEPLOY_ARCH}.AppImage"
    fi

    popd
}

# Download and install a standalone python build into the AppDir.
install_python() {
    if [ ! -d "$APPDIR/usr/python" ]; then
        echo "--- Downloading Python ---"
        wget -c "$PYTHON_DOWNLOAD_URL" -O "$BUILD_DIR/python.tar.gz"

        echo "--- Installing Python ---"
        tar -xzf "$BUILD_DIR/python.tar.gz" -C "$BUILD_DIR"
        mv "$BUILD_DIR/python" "$APPDIR/usr/python"
        rm "$BUILD_DIR/python.tar.gz"
    fi
}

install_dependencies() {
    echo "--- Installing dependencies ---"
    "$APPDIR/usr/python/bin/python3" -m pip install --upgrade pip
    "$APPDIR/usr/python/bin/python3" -m pip install cython
    "$APPDIR/usr/python/bin/python3" -m pip install --require-hashes -r contrib/deterministic-build/linux-py3.9-requirements-electrumsv-no-hw.txt
}

install_app() {
    echo "--- Installing application ---"

    # Application code
    cp -r electrumsv "$APPDIR/usr/bin/"
    # Main entry point
    cp electrum-sv "$APPDIR/usr/bin/"
    # Data files
    cp -r data_in "$APPDIR/usr/bin/"
    # Licence and release notes
    cp LICENCE "$APPDIR/usr/bin/"
    cp RELEASE-NOTES "$APPDIR/usr/bin/"

    # Desktop entry
    cp electrum-sv.desktop "$APPDIR/usr/share/applications/"
    # Icon
    cp electrumsv/data/icons/electrum-sv.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/"

    # Create AppRun
    echo '#!/bin/bash
HERE=$(dirname $(readlink -f "${0}"))
export PYTHONPATH="$HERE/usr/bin:$HERE/usr/python/lib/python3.9/site-packages"
export PYTHONHOME="$HERE/usr/python"
export QT_PLUGIN_PATH="$HERE/usr/plugins"
cd "$HERE/usr/bin"
exec "$HERE/usr/python/bin/python3" electrum-sv "$@"' > "$APPDIR/AppRun"
    chmod +x "$APPDIR/AppRun"
}

package_appimage() {
    echo "--- Packaging AppImage ---"

    export UPD_INFO="gh-releases-zsync|Electrum-SV|ElectrumSV|latest|ElectrumSV-*-${ARCH}.AppImage.zsync"
    export OUTPUT="ElectrumSV-${ARCH}.AppImage"

    pushd "$BUILD_DIR"

    # We need to run this from the build dir so the relative paths to the tools are correct.
    ./bin/linuxdeploy-${LINUXDEPLOY_ARCH}.AppImage --appdir="$APPDIR" --output appimage

    popd
}


# --- Main script ---

# Clean up previous build artefacts.
if [ -d "$APPDIR" ]; then
    rm -rf "$APPDIR"
fi
if [ -d "$BUILD_DIR/$APP-$VERSION-$ARCH.AppImage" ]; then
    rm -f "$BUILD_DIR/$APP-$VERSION-$ARCH.AppImage"
fi

mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"


download_linuxdeploy_tools
install_python
install_dependencies
install_app
package_appimage 