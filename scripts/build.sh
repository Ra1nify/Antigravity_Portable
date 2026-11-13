#!/usr/bin/env bash
set -eo pipefail

VERSION="$1"
BASE_URL="$2"

if [ -z "$VERSION" ] || [ -z "$BASE_URL" ] || [ "$BASE_URL" = "url:" ]; then
    echo "Error: Invalid parameters!"
    echo "Usage: ./scripts/build.sh <VERSION> <BASE_URL>"
    echo "Received VERSION: '$VERSION'"
    echo "Received BASE_URL: '$BASE_URL'"
    exit 1
fi

echo "=============================================="
echo " Building Antigravity Portable v${VERSION}"
echo " Base URL: ${BASE_URL}"
echo "=============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_FILE="${SCRIPT_DIR}/portable_hook.js"
DIST_DIR="$(pwd)/dist"
WORK_DIR="$(pwd)/work"

rm -rf "$DIST_DIR" "$WORK_DIR"
mkdir -p "$DIST_DIR" "$WORK_DIR"

if [ ! -f "$HOOK_FILE" ]; then
    echo "Error: portable_hook.js not found at $HOOK_FILE"
    exit 1
fi

patch_asar() {
    local asar_file="$1"
    echo "  [Hook] Patching asar: $asar_file"
    
    if [ ! -f "$asar_file" ]; then
        echo "  [Error] asar file not found: $asar_file"
        exit 1
    fi

    rm -rf "${WORK_DIR}/asar_extracted"
    npx --yes @electron/asar extract "$asar_file" "${WORK_DIR}/asar_extracted"

    local target_js="${WORK_DIR}/asar_extracted/dist/main.js"
    if [ ! -f "$target_js" ]; then
        echo "  [Error] dist/main.js not found inside $asar_file"
        exit 1
    fi

    cat "$HOOK_FILE" "$target_js" > "${target_js}.tmp"
    mv "${target_js}.tmp" "$target_js"

    npx --yes @electron/asar pack "${WORK_DIR}/asar_extracted" "$asar_file"
    rm -rf "${WORK_DIR}/asar_extracted"
    echo "  [Hook] Successfully injected and repacked asar."
}

# ----------------------------------------------------------------------
# 1. Windows Packages (x64 / arm64)
# ----------------------------------------------------------------------
build_windows() {
    local arch="$1"      # x64 or arm64
    local subpath="$2"   # windows-x64/Antigravity-x64.exe or windows-arm/Antigravity-arm64.exe
    local pkg_name="Antigravity-Portable-v${VERSION}-windows-${arch}"

    echo ">>> Building Windows (${arch})..."
    local installer="${WORK_DIR}/installer-${arch}.exe"
    local extract_dir="${WORK_DIR}/win-${arch}"

    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"

    echo "  Downloading official installer: ${BASE_URL}/${subpath}"
    curl -f -sSL "${BASE_URL}/${subpath}" -o "$installer"

    echo "  Unpacking NSIS installer..."
    mkdir -p "${extract_dir}/tmp"
    7z x "$installer" -o"${extract_dir}/tmp" > /dev/null

    local inner_7z
    inner_7z=$(find "${extract_dir}/tmp" -type f -name "app-*.7z" | head -n 1)
    if [ -n "$inner_7z" ]; then
        echo "  Extracting nested 7z payload (${inner_7z})..."
        7z x "$inner_7z" -o"${extract_dir}/final" > /dev/null
        rm -rf "${extract_dir}/tmp"
        mv "${extract_dir}/final"/* "${extract_dir}/"
        rm -rf "${extract_dir}/final"
    else
        mv "${extract_dir}/tmp"/* "${extract_dir}/"
        rm -rf "${extract_dir}/tmp"
    fi

    # Clean up NSIS metadata
    rm -rf "${extract_dir}/\$"* "${extract_dir}/Uninstall"* "$installer"

    # Patch asar
    patch_asar "${extract_dir}/resources/app.asar"

    # Zip package
    echo "  Archiving ${pkg_name}.zip..."
    (cd "$extract_dir" && zip -rq "${DIST_DIR}/${pkg_name}.zip" .)
    rm -rf "$extract_dir"
    echo "  Finished Windows (${arch})."
}

# ----------------------------------------------------------------------
# 2. Linux Packages (x64 / arm64)
# ----------------------------------------------------------------------
build_linux() {
    local arch="$1"      # x64 or arm64
    local subpath="$2"   # linux-x64/Antigravity.tar.gz or linux-arm/Antigravity.tar.gz
    local pkg_name="Antigravity-Portable-v${VERSION}-linux-${arch}"

    echo ">>> Building Linux (${arch})..."
    local tarball="${WORK_DIR}/linux-${arch}.tar.gz"
    local extract_dir="${WORK_DIR}/linux-${arch}"

    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"

    echo "  Downloading official tarball: ${BASE_URL}/${subpath}"
    curl -f -sSL "${BASE_URL}/${subpath}" -o "$tarball"

    echo "  Extracting tarball..."
    tar -xzf "$tarball" -C "$extract_dir"
    rm -f "$tarball"

    # Patch asar
    patch_asar "${extract_dir}/resources/app.asar"

    # Ensure executable permissions
    if [ -f "${extract_dir}/Antigravity" ]; then
        chmod +x "${extract_dir}/Antigravity"
    fi

    # Tar package
    echo "  Archiving ${pkg_name}.tar.gz..."
    tar -czf "${DIST_DIR}/${pkg_name}.tar.gz" -C "$extract_dir" .
    rm -rf "$extract_dir"
    echo "  Finished Linux (${arch})."
}

# ----------------------------------------------------------------------
# 3. macOS Packages (Apple Silicon arm64 / Intel x64)
# ----------------------------------------------------------------------
build_macos() {
    local arch="$1"      # arm64 or x64
    local subpath="$2"   # darwin-arm/Antigravity.zip or darwin-x64/Antigravity.zip
    local pkg_name="Antigravity-Portable-v${VERSION}-macOS-${arch}"

    echo ">>> Building macOS (${arch})..."
    local mac_zip="${WORK_DIR}/mac-${arch}.zip"
    local extract_dir="${WORK_DIR}/mac-${arch}"

    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"

    echo "  Downloading official zip: ${BASE_URL}/${subpath}"
    curl -f -sSL "${BASE_URL}/${subpath}" -o "$mac_zip"

    echo "  Unpacking zip..."
    unzip -q "$mac_zip" -d "$extract_dir"
    rm -f "$mac_zip"

    # Patch asar
    patch_asar "${extract_dir}/Antigravity.app/Contents/Resources/app.asar"

    # Ensure binary is executable
    chmod -R +x "${extract_dir}/Antigravity.app/Contents/MacOS" 2>/dev/null || true

    # Zip package
    echo "  Archiving ${pkg_name}.zip..."
    (cd "$extract_dir" && zip -rq "${DIST_DIR}/${pkg_name}.zip" .)
    rm -rf "$extract_dir"
    echo "  Finished macOS (${arch})."
}

# Execute builds for all target platforms
build_windows "x64"   "windows-x64/Antigravity-x64.exe"
build_windows "arm64" "windows-arm/Antigravity-arm64.exe"

build_linux "x64"     "linux-x64/Antigravity.tar.gz"
build_linux "arm64"   "linux-arm/Antigravity.tar.gz"

build_macos "arm64"   "darwin-arm/Antigravity.zip"
build_macos "x64"     "darwin-x64/Antigravity.zip"

rm -rf "$WORK_DIR"

# Strict check that dist has files
if [ -z "$(ls -A "$DIST_DIR" 2>/dev/null)" ]; then
    echo "Error: Build failed! dist/ directory is empty."
    exit 1
fi

echo "=============================================="
echo " Build Completed Successfully! Artifacts:"
echo "=============================================="
ls -lh "$DIST_DIR"
