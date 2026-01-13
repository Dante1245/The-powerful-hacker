#!/bin/bash
# 🔥 AVS Pro v4.0 → YOUR GitHub (COMPLETE 20+ FILES)

set -e

echo "🔥 AVS Pro v4.0 COMPLETE GitHub Repository Creator"
echo "📱 Works on Termux iPhone + ☁️ Google Cloud Kali"
echo

# User input
read -p "GitHub Username: " GITHUB_USER
read -sp "GitHub Token: " GITHUB_TOKEN
echo
read -p "Repo Name [avs-pro-v4.0]: " REPO_NAME
REPO_NAME=${REPO_NAME:-avs-pro-v4.0}

REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
TEMP_DIR="/tmp/avs-pro-$(date +%s)"

echo "🚀 Creating repo: $REPO_URL"

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# 1. CREATE GITHUB REPO
echo "📤 Creating GitHub repository..."
curl -s -X DELETE "https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}" \
  -H "Authorization: token $GITHUB_TOKEN" 2>/dev/null || true

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{\"name\":\"${REPO_NAME}\",\"description\":\"AVS Pro v4.0 Universal Bug Bounty Scanner\",\"private\":false,\"auto_init\":true}" \
  https://api.github.com/user/repos > /dev/null

# 2. CLONE REPO
git clone "$REPO_URL" . || git clone "$REPO_URL" repo && cd repo

echo "📁 Creating 20+ files..."

# ==================== CORE FILES ====================

# README.md
cat > README.md << 'EOF'
# 🔥 AVS Pro v4.0 - Universal Bug Bounty Scanner

[![GitHub stars](https://img.shields.io/github/stars/%REPO_USER%/avs-pro-v4.0?style=social)](https://github.com/%REPO_USER%/avs-pro-v4.0)
[![Kali Linux](https://img.shields.io/badge/Kali-Cloud-black?logo=kali-linux)](https://www.kali.org)
[![Termux](https://img.shields.io/badge/Termux-iPhone-green?logo=android)](https://termux.com)
[![CPU Optimized](https://img.shields.io/badge/CPU-Optimized-blue)](https://github.com/%REPO_USER%/avs-pro-v4.0)

**⚡ <90s DEPLOY → $10K+ Bug Bounty Reports**
**📱 Termux iPhone + ☁️ Google Cloud Kali**

## 🚀 1-Click Install

### Kali Linux / Google Cloud
```bash
curl -sSL https://raw.githubusercontent.com/%REPO_USER%/avs-pro-v4.0/main/install.sh | bash
sudo ./avs-pro.sh example.com
