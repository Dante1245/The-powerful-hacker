#!/bin/bash
# AVS Pro v4.0 Universal Install - Kali Cloud + Termux
# Repo: https://github.com/Dante1245/The-powerful-hacker

set -euo pipefail

echo "🔥 Installing AVS Pro v4.0 from Dante1245/The-powerful-hacker..."

# Detect environment
if command -v termux-setup-storage >/dev/null 2>&1; then
    ENV="termux"; PREFIX="$HOME"
elif [[ -f /etc/kali-release ]] || [[ "${EUID:-0}" == "0" ]]; then
    ENV="kali"; PREFIX="/usr/local"
else
    ENV="linux"; PREFIX="$HOME/.local"
fi

echo "🤖 Environment: $ENV"

# Use sudo for package manager commands when not root and not termux
SUDO=""
if [[ "$ENV" != "termux" ]] && [[ "${EUID:-0}" -ne 0 ]]; then
    SUDO="sudo"
fi

# System update
if [[ "$ENV" == "termux" ]]; then
    pkg update -y && pkg upgrade -y
    pkg install -y git curl wget python nodejs golang nmap htop || true
else
    $SUDO apt update -qq && $SUDO apt upgrade -y -qq
    $SUDO apt install -y -qq git curl wget python3 python3-pip golang-go nmap htop tmux
fi

# Project directory
mkdir -p "$HOME/AVS-Pro-v4.0/config/wordlists" "$HOME/AVS-Pro-v4.0/config/templates" "$HOME/AVS-Pro-v4.0/scans" "$HOME/AVS-Pro-v4.0/logs"
cd "$HOME/AVS-Pro-v4.0"

# Go environment
export GOPATH="$HOME/go"
mkdir -p "$GOPATH/bin"
export PATH="$PATH:$GOPATH/bin:$PREFIX/bin"

# Essential tools
if [[ "$ENV" != "termux" ]]; then
    $SUDO apt install -y -qq masscan nikto gobuster whatweb ffuf sqlmap || true

    if command -v go >/dev/null 2>&1; then
        go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest || true
        go install github.com/projectdiscovery/katana/cmd/katana@latest || true
        go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest || true
        go install github.com/projectdiscovery/httpx/cmd/httpx@latest || true
        go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest || true
        go install github.com/hahwul/dalfox/v2@latest || true
    else
        echo "⚠️ go not found — skipping go-based installs"
    fi
else
    pip3 install --user httpx linkfinder || true
    if command -v npm >/dev/null 2>&1; then
        npm i -g nuclei@latest || true
    else
        echo "⚠️ npm not found — skipping npm-based installs"
    fi
fi

# Wordlists (elite)
curl -sL https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt -o config/wordlists/dirs.txt || true
curl -sL https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/burp-parameter-names.txt -o config/wordlists/params.txt || true
curl -sL https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o config/wordlists/common.txt || true

# Permissions: only chmod if there are matching files to avoid glob expansion error
if compgen -G "*.sh" > /dev/null; then
    chmod +x -- *.sh
fi

echo "🎉 ✅ AVS Pro v4.0 INSTALLED!"
echo ""
echo "🌐 Kali Cloud: sudo ~/AVS-Pro-v4.0/avs-pro.sh https://target.com"
echo "📱 Termux: ~/AVS-Pro-v4.0/avs-pro.sh https://target.com --termux"
echo "⭐ Thanks: https://github.com/Dante1245/The-powerful-hacker"
