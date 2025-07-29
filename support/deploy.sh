#!/bin/bash
set -e

# Get appimagetool to automate finding dependencies
wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimagetool-.*-x86_64.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage

# Configuration
APP_NAME="OpenSpace"
DEPLOY_DIR="./OpenSpace-0.21.1rc1"
BUILD_DIR="../bin"
APPDIR="$DEPLOY_DIR/AppDir"
APPIMAGETOOL=./appimagetool-*.AppImage # or adjust to full path

# Clean previous deployment
echo "Cleaning up previous deployment..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$APPDIR/usr/bin"

echo "Copying binary..."
cp -v "$BUILD_DIR"/* "$APPDIR/usr/bin/"

echo "Stripping binaries..."
strip $APPDIR/usr/bin/*

echo "Copying required data..."
# The OpenSpace executable expects these files in the parent directory of its bin directory
cp -r ../{config/,modules/,data/,scripts/,shaders,/documentation/,openspace.cfg} $APPDIR/usr/

# delete source files from modules directory
find $APPDIR/usr/ -name '*.cpp' -print0 | xargs -0 -P2 rm
find $APPDIR/usr/ -name 'CMakeLists.txt'  -print0 | xargs -0 -P2 rm
find $APPDIR/usr/ -name '*.h' -print0 | xargs -0 -P2 rm
find $APPDIR/usr/ -name '*.cmake' -print0 | xargs -0 -P2 rm

# (Optional) add icon and desktop file if packaging AppImage
mkdir -p "$APPDIR/usr/share/applications"
cat > "$APPDIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=OpenSpace
Exec=$APP_NAME
Icon=openspace
Type=Application
Categories=Science;Education;Simulation;
EOF

# Provide icon (optional, PNG format)
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
cp ./support/linux/openspace-icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/openspace.png" 2>/dev/null || true

# Make binary executable
# chmod +x "$APPDIR/usr/bin/$APP_NAME"

echo "Running appimagetool..."
$APPIMAGETOOL deploy $APPDIR/usr/share/applications/*.desktop # Bundle everything except what comes with the base system

# Install libcef runtime dependencies (the "deploy" step has automatically found libcef.so
# thanks to dynamic linking information but can't guess some other dependencies)
cef_orig_dir=$(find ../build -path */Release/libcef.so | xargs dirname)
cef_install_dir=$(find $APPDIR -name libcef.so | xargs dirname)
cp -r $cef_orig_dir/* $cef_install_dir

# Strip libcef (libcef.so goes from 1.3GB to less than 200MB)
strip --strip-unneeded $cef_install_dir/*.so

# Move final AppImage to deploy dir (if generated)
if [ -f "$APP_NAME-x86_64.AppImage" ]; then
    mv "$APP_NAME-x86_64.AppImage" "$DEPLOY_DIR/"
    echo "AppImage created at $DEPLOY_DIR/$APP_NAME-x86_64.AppImage"
else
    echo "AppDir created at $APPDIR"
    echo "You can manually package this with linuxdeploy or other tools"
fi
