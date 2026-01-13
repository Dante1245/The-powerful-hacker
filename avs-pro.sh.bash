#!/bin/bash
# AVS Pro v4.0 Universal Pentest Engine
# https://github.com/Dante1245/The-powerful-hacker
# CPU Optimized • Kali Cloud + Termux

set -euo pipefail

MAX_THREADS=100
TARGET="" OUTPUT_DIR="" MODE="auto" VERBOSE=0
RED='\033[0;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

banner() {
    clear 2>/dev/null || true
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════════╗
║  🔥 AVS PRO v4.0 • Dante1245/The-powerful-hacker 🔥                                    ║
║  📱 Termux iPhone ☁️ Kali Cloud • 8000+ Vulns • CPU Optimized                        ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
EOF
}

detect_mode() {
    if command -v termux-setup-storage >/dev/null 2>&1; then
        MODE="termux"; MAX_THREADS=50; echo -e "${CYAN}[📱 TERMUX]${NC}"
    elif [[ "$EUID" == "0" ]]; then
        MODE="kali"; MAX_THREADS=150; echo -e "${CYAN}[☁️ KALI CLOUD]${NC}"
    else
        MODE="linux"; MAX_THREADS=100; echo -e "${CYAN}[💻 LINUX]${NC}"
    fi
}

args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t=*|--target=*) TARGET="${1#*=}";;
            -T=*|--threads=*) MAX_THREADS="${1#*=}";;
            -o=*|--output=*) OUTPUT_DIR="${1#*=}";;
            --termux) MODE="termux"; MAX_THREADS=50;;
            --kali) MODE="kali"; MAX_THREADS=150;;
            -v|--verbose) VERBOSE=1;;
            *) TARGET="$1";;
        esac; shift
    done
    [[ -z "$TARGET" ]] && { echo "${RED}Usage: $0 <target> [--termux]${NC}"; exit 1; }
    
    TARGET=$(echo "$TARGET" | sed 's|https\?://||g;s|/||g')
    OUTPUT_DIR="${OUTPUT_DIR:-~/AVS-Pro-v4.0/scans/$(date +%Y%m%d_%H%M%S)-$TARGET}"
    mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/screenshots"
}

check_tools() {
    command -v nmap >/dev/null 2>&1 || { echo "${RED}Install nmap${NC}"; exit 1; }
    command -v curl >/dev/null 2>&1 || { echo "${RED}Install curl${NC}"; exit 1; }
    
    TOOLS=($(command -v nuclei katana naabu httpx ffuf gobuster 2>/dev/null | xargs -n1 basename))
    [[ ${#TOOLS[@]} -gt 0 ]] && echo "${GREEN}[+] Advanced tools: ${TOOLS[*]}${NC}"
}

log() { echo -e "[$(date +%H:%M:%S)] $@" | tee -a "$OUTPUT_DIR/scan.log"; }

recon() {
    log "${BLUE}[PHASE 1/6] 🔍 RECON${NC}"
    START=$SECONDS
    
    # Tech detection
    timeout 15s whatweb -v "https://$TARGET" > "$OUTPUT_DIR/tech.txt" 2>/dev/null || \
        curl -s -A "Mozilla/5.0" "https://$TARGET" | grep -iE "(server|wordpress|nginx)" > "$OUTPUT_DIR/tech.txt"
    
    # Ports
    timeout 25s nmap -sV --top-ports 15 "$TARGET" -oN "$OUTPUT_DIR/ports.txt" 2>/dev/null || \
        echo "[!] Port scan limited" > "$OUTPUT_DIR/ports.txt"
    
    # Dirs (if gobuster)
    command -v gobuster >/dev/null 2>&1 && {
        timeout 45s gobuster dir -u "https://$TARGET" -w ~/AVS-Pro-v4.0/config/wordlists/dirs.txt -t $MAX_THREADS -q -o "$OUTPUT_DIR/gobuster.txt" &
    }
    
    wait
    log "${GREEN}[+] Recon complete: $((SECONDS-START))s${NC}"
}

nuclei_scan() {
    command -v nuclei >/dev/null 2>&1 || return
    log "${BLUE}[PHASE 2/6] 🔥 NUCLEI (8000+ templates)${NC}"
    START=$SECONDS
    
    nuclei -u "https://$TARGET" -c $MAX_THREADS -severity critical,high -o "$OUTPUT_DIR/nuclei.txt" -silent 2>/dev/null &
    wait
    log "${GREEN}[+] Nuclei: $((SECONDS-START))s${NC}"
}

xss_sql_hunt() {
    log "${BLUE}[PHASE 3/6] 🕷️ XSS + PARAMS${NC}"
    START=$SECONDS
    
    # Params
    command -v ffuf >/dev/null 2>&1 && {
        timeout 40s ffuf -u "https://$TARGET/FUZZ" -w ~/AVS-Pro-v4.0/config/wordlists/params.txt -t $MAX_THREADS -o "$OUTPUT_DIR/params.json" -silent &
    }
    
    # XSS test
    for payload in '"><script>alert(1)</script>' '%3Cscript%3Ealert(1)%3C/script%3E'; do
        curl -s "https://$TARGET/?test=$payload" | grep -i "script\|alert" >> "$OUTPUT_DIR/xss.txt" 2>/dev/null
    done &
    
    wait
    log "${GREEN}[+] XSS/Params: $((SECONDS-START))s${NC}"
}

cloud_hunter() {
    log "${BLUE}[PHASE 4/6] ☁️ CLOUD BUCKETS${NC}"
    START=$SECONDS
    
    BUCKET="${TARGET//./-}"
    curl -s "https://$BUCKET.s3.amazonaws.com" | grep -qi "NoSuchBucket" && \
        echo "🚨 S3 TAKEOVER: $BUCKET.s3.amazonaws.com" >> "$OUTPUT_DIR/cloud.txt"
    
    curl -s "https://storage.googleapis.com/$TARGET" | grep -qi "NoSuchBucket" && \
        echo "🚨 GCP BUCKET: storage.googleapis.com/$TARGET" >> "$OUTPUT_DIR/cloud.txt"
    
    log "${GREEN}[+] Cloud: $((SECONDS-START))s${NC}"
}

loot_extract() {
    log "${BLUE}[PHASE 5/6] 💎 LOOT EXTRACTION${NC}"
    
    grep -r -iE "(critical|high|RCE|XSS|SQL|bucket)" "$OUTPUT_DIR/" > "$OUTPUT_DIR/CRITICAL.txt" 2>/dev/null || true
    wc -l "$OUTPUT_DIR/CRITICAL.txt" >> "$OUTPUT_DIR/summary.txt"
}

report() {
    log "${BLUE}[PHASE 6/6] 📊 BOUNTY REPORT${NC}"
    
    CRIT=$(grep -c "critical\|high" "$OUTPUT_DIR"/*.txt 2>/dev/null || echo 0)
    
cat > "$OUTPUT_DIR/FINAL-REPORT.md" << EOF
# 🎯 AVS Pro v4.0 Pentest Report
**Target:** $TARGET | **Mode:** $MODE | **Repo:** https://github.com/Dante1245/The-powerful-hacker

## 📊
**Critical Findings:** $CRIT | **Estimated Bounty:** \$$((CRIT * 1500))+

## 🚨 Criticals
\`\`\`
$(head -20 "$OUTPUT_DIR/CRITICAL.txt")
\`\`\`

**Full scan:** $OUTPUT_DIR/
EOF

    tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR/" 2>/dev/null || zip -r "$OUTPUT_DIR.zip" "$OUTPUT_DIR/" 2>/dev/null
    log "${GREEN}✅ REPORT: $OUTPUT_DIR/FINAL-REPORT.md${NC}"
    log "${GREEN}✅ ARCHIVE: $OUTPUT_DIR.tar.gz${NC}"
}

main() {
    banner
    detect_mode
    args "$@"
    check_tools
    
    recon
    nuclei_scan
    xss_sql_hunt
    cloud_hunter
    loot_extract
    report
    
    log "${CYAN}🎉 MISSION COMPLETE - Dante1245/The-powerful-hacker${NC}"
}

main "$@"
