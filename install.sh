#!/usr/bin/env bash
# Ultimate Downloader - Standalone installer for Linux / macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/Johni12M/ultimate-downloader/master/install.sh | bash
set -e

REPO_URL="https://github.com/Johni12M/ultimate-downloader.git"
INSTALL_DIR="$HOME/.local/share/ultimate-downloader"
BIN_DIR="$HOME/.local/bin"

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

install_deps() {
    local os="$1"
    if [ "$os" = "linux" ]; then
        echo "Installing system dependencies (sudo required)..."
        sudo apt-get update -q
        sudo apt-get install -y git curl imagemagick ffmpeg nodejs npm mupdf-tools
    elif [ "$os" = "macos" ]; then
        echo "Installing system dependencies via Homebrew..."
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew not found — installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Add brew to PATH for this session (Apple Silicon)
            eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
        fi
        brew install git node imagemagick ffmpeg mupdf-tools 2>/dev/null || true
    fi
}

ensure_bin_in_path() {
    local profile
    mkdir -p "$BIN_DIR"
    # Add ~/.local/bin to PATH in shell profile if not already there
    for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile"; do
        [ -f "$f" ] || continue
        if ! grep -q "$BIN_DIR" "$f" 2>/dev/null; then
            echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$f"
            profile="$f"
        fi
    done
    # Also export for this session
    export PATH="$PATH:$BIN_DIR"
}

main() {
    print_banner

    local os
    os="$(detect_os)"
    if [ "$os" = "unknown" ]; then
        echo "Error: Unsupported OS. Please use init.sh after manually cloning the repo."
        exit 1
    fi

    install_deps "$os"

    # Create a temp directory — deleted automatically on exit
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

    # Copy only runtime files — source clone is deleted on exit
    cp -r src             "$INSTALL_DIR/src"
    cp -r node_modules    "$INSTALL_DIR/node_modules"
    cp    package.json    "$INSTALL_DIR/package.json"
    cp    unifont-15.0.01.ttf "$INSTALL_DIR/unifont-15.0.01.ttf"
    cp -r d4sd/esm        "$INSTALL_DIR/d4sd/esm"
    cp -r d4sd/cjs        "$INSTALL_DIR/d4sd/cjs"
    cp -r d4sd/node_modules "$INSTALL_DIR/d4sd/node_modules"
    cp    d4sd/package.json "$INSTALL_DIR/d4sd/package.json"

    # Create the global wrapper script
    ensure_bin_in_path
    cat > "$BIN_DIR/ultimate-downloader" <<EOF
#!/bin/sh
exec node "$INSTALL_DIR/src/EbookDownloader.js" "\$@"
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
