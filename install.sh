#!/usr/bin/env bash
# Ultimate Downloader - Standalone installer for Linux / macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/Johni12M/ultimate-downloader/master/install.sh | bash
set -e

REPO_URL="https://github.com/Johni12M/ultimate-downloader.git"
INSTALL_DIR="$HOME/.local/share/ultimate-downloader"
BIN_DIR="$HOME/.local/bin"
NODE_VERSION="20.18.3"

print_banner() {
    echo ""
    echo "========================================"
    echo "  Ultimate Downloader Installer"
    echo "========================================"
    echo ""
}

detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux"  ;;
        Darwin*) echo "macos"  ;;
        *)       echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64)          echo "x64"   ;;
        aarch64|arm64)   echo "arm64" ;;
        armv7l)          echo "armv7l" ;;
        *)               echo "x64"   ;;
    esac
}

install_node() {
    local os="$1" arch="$2"
    local platform
    [ "$os" = "linux" ] && platform="linux" || platform="darwin"

    local tarball="node-v${NODE_VERSION}-${platform}-${arch}.tar.gz"
    local url="https://nodejs.org/dist/v${NODE_VERSION}/${tarball}"

    echo "Downloading Node.js v${NODE_VERSION} (${platform}-${arch})..."
    curl -fsSL "$url" -o "$tmpwork/${tarball}"
    tar -xzf "$tmpwork/${tarball}" -C "$tmpwork"

    mkdir -p "$INSTALL_DIR/node/bin"
    cp "$tmpwork/node-v${NODE_VERSION}-${platform}-${arch}/bin/node" "$INSTALL_DIR/node/bin/node"
    chmod +x "$INSTALL_DIR/node/bin/node"
    echo "Node.js installed at $INSTALL_DIR/node/bin/node"
}

install_system_deps() {
    local os="$1"
    if [ "$os" = "linux" ]; then
        echo "Installing system dependencies (imagemagick, ffmpeg, mupdf-tools)..."
        sudo apt-get update -q
        sudo apt-get install -y git curl imagemagick ffmpeg mupdf-tools
    elif [ "$os" = "macos" ]; then
        echo "Installing system dependencies via Homebrew..."
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew not found — installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
        fi
        brew install imagemagick ffmpeg mupdf-tools 2>/dev/null || true
    fi
}

ensure_bin_in_path() {
    mkdir -p "$BIN_DIR"
    for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile"; do
        [ -f "$f" ] || continue
        if ! grep -q "$BIN_DIR" "$f" 2>/dev/null; then
            echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$f"
        fi
    done
    export PATH="$PATH:$BIN_DIR"
}

main() {
    print_banner

    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"

    if [ "$os" = "unknown" ]; then
        echo "Error: Unsupported OS."
        exit 1
    fi

    install_system_deps "$os"

    local tmpwork
    tmpwork="$(mktemp -d)"
    trap 'echo "" && echo "Cleaning up temporary files..." && rm -rf "$tmpwork"' EXIT

    echo ""
    echo "Downloading source (temporary)..."
    git clone --recurse-submodules "$REPO_URL" "$tmpwork/repo"
    cd "$tmpwork/repo"

    echo ""
    echo "Downloading font..."
    curl -fsSL \
        "http://www.unifoundry.com/pub/unifont/unifont-15.0.01/font-builds/unifont-15.0.01.ttf" \
        -o unifont-15.0.01.ttf

    echo ""
    echo "Installing Node.js dependencies..."
    # Use system node if available, otherwise use the one we'll install
    NODE_BIN="node"
    if ! command -v node >/dev/null 2>&1; then
        # Install node now to use for npm install, will be moved to INSTALL_DIR later
        local platform arch_tmp
        [ "$os" = "linux" ] && platform="linux" || platform="darwin"
        local tarball="node-v${NODE_VERSION}-${platform}-${arch}.tar.gz"
        curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/${tarball}" -o "$tmpwork/${tarball}"
        tar -xzf "$tmpwork/${tarball}" -C "$tmpwork"
        NODE_BIN="$tmpwork/node-v${NODE_VERSION}-${platform}-${arch}/bin/node"
        export PATH="$tmpwork/node-v${NODE_VERSION}-${platform}-${arch}/bin:$PATH"
    fi

    npm install

    echo ""
    echo "Building d4sd..."
    cd d4sd
    npm install
    npm audit fix || true
    ./node_modules/.bin/tsc --module es2022
    ./node_modules/.bin/tsc-alias
    ./node_modules/.bin/tsc --module commonjs --outDir cjs
    echo '{"type": "commonjs"}' > cjs/package.json
    cd ..

    echo ""
    echo "Installing to $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/d4sd"

    cp -r src             "$INSTALL_DIR/src"
    cp -r node_modules    "$INSTALL_DIR/node_modules"
    cp    package.json    "$INSTALL_DIR/package.json"
    cp    unifont-15.0.01.ttf "$INSTALL_DIR/unifont-15.0.01.ttf"
    cp -r d4sd/esm        "$INSTALL_DIR/d4sd/esm"
    cp -r d4sd/cjs        "$INSTALL_DIR/d4sd/cjs"
    cp -r d4sd/node_modules "$INSTALL_DIR/d4sd/node_modules"
    cp    d4sd/package.json "$INSTALL_DIR/d4sd/package.json"

    # Install bundled Node.js (always use our own to guarantee version)
    install_node "$os" "$arch"

    # Install Chrome for Puppeteer into a known location
    echo ""
    echo "Installing Chrome browser for Puppeteer (may take a few minutes)..."
    PUPPETEER_CACHE_DIR="$INSTALL_DIR/browser-cache" \
        "$INSTALL_DIR/node/bin/node" "$INSTALL_DIR/d4sd/node_modules/puppeteer/install.mjs" || true

    # Create the global wrapper using bundled node
    ensure_bin_in_path
    cat > "$BIN_DIR/ultimate-downloader" <<EOF
#!/bin/sh
export PUPPETEER_CACHE_DIR="$INSTALL_DIR/browser-cache"
exec "$INSTALL_DIR/node/bin/node" "$INSTALL_DIR/src/EbookDownloader.js" "\$@"
EOF
    chmod +x "$BIN_DIR/ultimate-downloader"

    echo ""
    echo "========================================"
    echo "  Setup complete!"
    echo "  You can now run the tool with:"
    echo ""
    echo "    ultimate-downloader"
    echo ""
    echo "  (Restart your terminal if the command"
    echo "   is not found yet)"
    echo "========================================"
    echo ""
}

main
