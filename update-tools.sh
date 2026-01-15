
```bash
#!/bin/bash
# 🔥 AVS-Pro v4.0 Update Tools - Kali/Termux Dual-Mode
# Usage: bash update-tools.sh | curl .../update-tools.sh | bash

set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${GREEN}🚀 Updating AVS-Pro v4.0 Tools...${NC}"

# 🔍 Auto-detect Mode
if command -v termux-info >/dev/null 2>&1; then
    MODE="termux"
    echo -e "${YELLOW}📱 Termux Mode${NC}"
    pkg update -y && pkg upgrade -y
else
    MODE="kali"
    echo -e "${YELLOW}☁️  Kali Mode${NC}"
    sudo apt update && sudo apt upgrade -y
fi

# 📥 Pull Latest Repo
if [ -d "AVS-Pro-v4.0" ]; then
    cd AVS-Pro-v4.0
    git pull origin main
else
    git clone https://github.com/Dante1245/The-powerful-hacker AVS-Pro-v4.0
    cd AVS-Pro-v4.0
fi

# 🔧 Install/Upgrade Core Tools
echo -e "${GREEN}📦 Installing Pentest Tools...${NC}"

# Universal (curl works everywhere)
curl -sSL https://raw.githubusercontent.com/Dante1245/The-powerful-hacker/main/install.sh | bash

# Kali-Specific (sudo)
if [ "$MODE" = "kali" ]; then
    sudo apt install -y nmap gobuster nuclei ffuf httpx trufflehog masscan
    nuclei -update-templates
else
    # Termux Fallbacks
    pkg install -y nmap python
    pip install httpx gobuster ffuf
fi

chmod +x *.sh
echo -e "${GREEN}✅ Updated! Run: ./avs-pro.sh target.com${NC}"
echo -e "${YELLOW}📁 Location: $(pwd)${NC}"
