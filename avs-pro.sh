#!/bin/bash
# =================================================================
# 🔥 AVS-Pro v4.0 - Universal Pentest Arsenal 2026
# =================================================================
# Dual-Mode: Kali Cloud (150 threads) + Termux iPhone (50 threads)
# 6-Phase Attack: Recon → Nuclei → XSS → Cloud → Loot → Report
# Output: BUG_BOUNTY_REPORT.md + PoC Archive (.tar.gz)
# Usage: sudo ./avs-pro.sh target.com --termux | ./avs-pro.sh target.com -T 150
# =================================================================

set -euo pipefail

# 🎨 Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

# 📊 Global Config
VERSION="4.0"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TARGET="${1:-}"
THREADS=${2:-50}
MODE="kali"  # auto-detect termux/kali
OUTPUT_DIR="scans/${TARGET//[^a-zA-Z0-9]/_}_${TIMESTAMP}"
MAX_THREADS_KALI=150
MAX_THREADS_TERMUX=50

# 🛡️ Validate Target
validate_target() {
    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}❌ Target required: ./avs-pro.sh target.com${NC}"
        exit 1
    fi
    if [[ ! "$TARGET" =~ ^https?:// ]]; then
        TARGET="https://$TARGET"
    fi
    echo -e "${GREEN}🎯 Target: $TARGET${NC}"
}

# 🔍 Auto-detect Mode (Termux/Kali)
detect_mode() {
    if command -v termux-info >/dev/null 2>&1; then
        MODE="termux"
        THREADS=$MAX_THREADS_TERMUX
        echo -e "${CYAN}📱 Termux iPhone Mode: $THREADS threads${NC}"
    else
        MODE="kali"
        THREADS=$MAX_THREADS_KALI
        echo -e "${BLUE}☁️  Kali Cloud Mode: $THREADS threads${NC}"
    fi
}

# 📦 Setup Output Directory
setup_output() {
    mkdir -p "$OUTPUT_DIR"/{screenshots,loots,reports,json}
    REPORT="$OUTPUT_DIR/BUG_BOUNTY_REPORT.md"
    echo -e "${GREEN}📁 Output: $OUTPUT_DIR${NC}"
}

# 🚀 Phase 1: Recon (Nmap + Gobuster + Httpx)
phase_recon() {
    echo -e "\n${PURPLE}🔍 PHASE 1/6: RECON${NC}"
    
    # Nmap Top-20 + Screenshot
    nmap -sV --top-ports 20 -oN "$OUTPUT_DIR/nmap.txt" "$TARGET" | tee "$OUTPUT_DIR/nmap_live.txt"
    httpx -l "$OUTPUT_DIR/nmap_live.txt" -s screenshot -threads $THREADS -o "$OUTPUT_DIR/httpx.txt" 2>/dev/null || true
    
    # Directory Fuzzing (Gobuster/FFUF fallback)
    if command -v gobuster >/dev/null 2>&1; then
        gobuster dir -u "$TARGET" -w config/wordlists/dirs.txt -t $THREADS -o "$OUTPUT_DIR/gobuster.txt"
    else
        ffuf -u "$TARGET/FUZZ" -w config/wordlists/dirs.txt -t $THREADS -o "$OUTPUT_DIR/ffuf.json"
    fi
    
    # Params Discovery
    gobuster dir -u "$TARGET" -w config/wordlists/params.txt -t $THREADS -o "$OUTPUT_DIR/params.txt"
    
    # Live URLs
    cat "$OUTPUT_DIR"/*.txt | grep -oE 'https?://[^[:space:]]+' | httpx -silent -o "$OUTPUT_DIR/live_urls.txt"
}

# 🧬 Phase 2: Nuclei (8000+ Templates + Custom S3)
phase_nuclei() {
    echo -e "\n${PURPLE}🧬 PHASE 2/6: NUCLEI SCAN${NC}"
    
    # Standard Nuclei
    nuclei -l "$OUTPUT_DIR/live_urls.txt" -t /root/nuclei-templates/ -c $THREADS -o "$OUTPUT_DIR/nuclei.txt" \
           -s critical,high,medium -json-export "$OUTPUT_DIR/nuclei.json"
    
    # Custom S3 Takeover
    nuclei -l "$OUTPUT_DIR/live_urls.txt" -t config/templates/nuclei/ -o "$OUTPUT_DIR/s3_takeover.txt"
    
    # Critical Alerts
    grep -i "critical\|high" "$OUTPUT_DIR/nuclei.txt" > "$OUTPUT_DIR/critical.txt" || true
}

# 💉 Phase 3: XSS Hunter
phase_xss() {
    echo -e "\n${PURPLE}💉 PHASE 3/6: XSS HUNTER${NC}"
    
    # Param Discovery + XSS Payloads
    cat config/wordlists/params.txt | xargs -I {} -P $THREADS sh -c "
        curl -s '$TARGET?{}=$1' | grep -i 'script\|onerror\|onload' >> '$OUTPUT_DIR/xss.txt' || true
    " "XSS-$(date +%s)"
    
    # DOM XSS via Httpx
    httpx -l "$OUTPUT_DIR/live_urls.txt" -xss -o "$OUTPUT_DIR/xss_results.json"
}

# ☁️ Phase 4: Cloud Enum (AWS S3/Azure/GCP)
phase_cloud() {
    echo -e "\n${PURPLE}☁️  PHASE 4/6: CLOUD ENUM${NC}"
    
    # S3 Bucket Takeover Check
    cat config/wordlists/common.txt | grep -E '\.s3\.amazonaws\.com$' | \
        httpx -silent -sc -o "$OUTPUT_DIR/s3_live.txt"
    
    # Custom Nuclei S3
    nuclei -l "$OUTPUT_DIR/s3_live.txt" -t config/templates/nuclei/s3-takeover.yaml -o "$OUTPUT_DIR/cloud_takeover.txt"
    
    # Azure/GCP via FFUF
    ffuf -u "https://FUZZ.blob.core.windows.net/" -w config/wordlists/common.txt -o "$OUTPUT_DIR/azure.json"
}

# 💰 Phase 5: Loot & Secrets
phase_loot() {
    echo -e "\n${PURPLE}💰 PHASE 5/6: LOOT HUNT${NC}"
    
    # .env, robots.txt, backups
    cat config/wordlists/common.txt | grep -E '\.env|\.bak|robots\.txt|config' | \
        xargs -I {} -P $THREADS sh -c "curl -s '$TARGET{}' >> '$OUTPUT_DIR/loot.txt'"
    
    # Secret Scanning
    trufflehog filesystem "$OUTPUT_DIR/" --json > "$OUTPUT_DIR/secrets.json" 2>/dev/null || true
}

# 📋 Phase 6: Report Generation
phase_report() {
    echo -e "\n${PURPLE}📋 PHASE 6/6: GENERATE REPORT${NC}"
    
    cat > "$REPORT" << EOF
# 🔥 AVS-Pro v4.0 Bug Bounty Report
**Target**: $TARGET  
**Date**: $(date)  
**Mode**: $MODE ($THREADS threads)  
**Output**: $OUTPUT_DIR  

## 🛡️ CRITICAL FINDINGS
\`\`\`
$(cat "$OUTPUT_DIR/critical.txt" | head -20 || echo "None")
\`\`\`

## 🎯 NUCLEI HITS (High/Crit)
$(wc -l < "$OUTPUT_DIR/nuclei.txt") vulnerabilities found

## ☁️ CLOUD TAKEOVERS
$(cat "$OUTPUT_DIR/cloud_takeover.txt" || echo "None")

## 💉 XSS VULNS
$(wc -l < "$OUTPUT_DIR/xss.txt") potential XSS

## 🔑 SECRETS FOUND
$(jq '.[] | select(.Verified==true)' "$OUTPUT_DIR/secrets.json" 2>/dev/null | wc -l || echo 0)

## 📁 FULL ARTIFACTS
\`\`\`
$(find "$OUTPUT_DIR" -type f | head -10)
\`\`\`

**Archive**: scans/${TARGET//[^a-zA-Z0-9]/_}_${TIMESTAMP}.tar.gz
EOF
    
    # Archive PoC
    tar -czf "${OUTPUT_DIR}.tar.gz" -C "$(dirname $OUTPUT_DIR)" "$(basename $OUTPUT_DIR)"
    echo -e "${GREEN}✅ Report: $REPORT${NC}"
    echo -e "${GREEN}📦 Archive: ${OUTPUT_DIR}.tar.gz${NC}"
}

# 🎯 Main Execution
main() {
    echo -e "${WHITE}🚀 AVS-Pro v$VERSION Starting...${NC}"
    validate_target
    detect_mode
    setup_output
    
    phase_recon
    phase_nuclei
    phase_xss
    phase_cloud
    phase_loot
    phase_report
    
    echo -e "\n${GREEN}🎉 SCAN COMPLETE! Check: $OUTPUT_DIR${NC}"
    echo -e "${YELLOW}💡 Bounty Tip: Submit ${OUTPUT_DIR}.tar.gz + Screenshots${NC}"
}

# 🛫 Launch
main "$@"
