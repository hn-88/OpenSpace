#!/bin/bash
set -e

# Configuration
APP_NAME="OpenSpace"
DEPLOY_DIR="./deploy"
BUILD_DIR="./bin"
APPDIR="$DEPLOY_DIR/AppDir"
LINUXDEPLOYQT=linuxdeployqt # Assumed in PATH or adjust to full path

# Clean previous deployment
echo "Cleaning up previous deployment..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$APPDIR/usr/bin"

echo "Copying binary..."
cp "$BUILD_DIR/$APP_NAME" "$APPDIR/usr/bin/"

echo "Stripping binary..."
strip "$APPDIR/usr/bin/$APP_NAME"

echo "Copying required data..."
cp -r ./data "$APPDIR/usr/share/$APP_NAME/"
cp -r ./modules "$APPDIR/usr/share/$APP_NAME/"
cp -r ./docs "$APPDIR/usr/share/$APP_NAME/"
cp -r ./assets "$APPDIR/usr/share/$APP_NAME/" 2>/dev/null || true

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
chmod +x "$APPDIR/usr/bin/$APP_NAME"

echo "Running linuxdeployqt..."
"$LINUXDEPLOYQT" "$APPDIR/usr/share/applications/$APP_NAME.desktop" \
    -appimage \
    -bundle-non-qt-libs \
    -verbose=2 \
    -executable="$APPDIR/usr/bin/$APP_NAME"

# Move final AppImage to deploy dir (if generated)
if [ -f "$APP_NAME-x86_64.AppImage" ]; then
    mv "$APP_NAME-x86_64.AppImage" "$DEPLOY_DIR/"
    echo "AppImage created at $DEPLOY_DIR/$APP_NAME-x86_64.AppImage"
else
    echo "AppDir created at $APPDIR"
    echo "You can manually package this with linuxdeploy or other tools"
fi
