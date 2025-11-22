#!/bin/sh

# Colors - ANSI escape codes for visual hierarchy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Banner
print_banner() {
    printf "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║       PASSIVE SUBDOMAIN ENUMERATION v2.0              ║
║       Cloud-Aware Recon Wrapper                       ║
╚═══════════════════════════════════════════════════════╝
EOF
    printf "${NC}\n"
}

# Usage
usage() {
    printf "${WHITE}Usage:${NC} $0 <domain>\n\n"
    printf "${YELLOW}Arguments:${NC}\n"
    printf "  ${GREEN}<domain>${NC}        Target domain (e.g., tesla.com)\n\n"
    printf "${YELLOW}Example:${NC}\n"
    printf "  $0 tesla.com\n\n"
    printf "${YELLOW}Sources:${NC}\n"
    printf "  • Subfinder (passive APIs)\n"
    printf "  • Assetfinder\n"
    printf "  • AnubisDB\n"
    printf "  • RapidDNS\n"
    printf "  • crt.sh (Certificate Transparency)\n"
    printf "  • DNSDumpster (via kaeferjaeger mirror)\n"
    printf "  • Cloud SNI Ranges (AWS, GCP, Azure, DO, Oracle)\n\n"
    exit 1
}

# Dependency check
check_dependencies() {
    printf "${BLUE}[*]${NC} Checking dependencies...\n"
    
    missing_deps=""
    [ ! -command -v subfinder >/dev/null 2>&1 ] && missing_deps="$missing_deps subfinder"
    [ ! -command -v assetfinder >/dev/null 2>&1 ] && missing_deps="$missing_deps assetfinder"
    [ ! -command -v anew >/dev/null 2>&1 ] && missing_deps="$missing_deps anew"
    [ ! -command -v curl >/dev/null 2>&1 ] && missing_deps="$missing_deps curl"
    [ ! -command -v jq >/dev/null 2>&1 ] && missing_deps="$missing_deps jq"
    
    if [ -n "$missing_deps" ]; then
        printf "${RED}[!] Missing dependencies:${NC}$missing_deps\n"
        printf "${YELLOW}[!] Install with: go install -v <tool>@latest${NC}\n"
        exit 1
    fi
    
    printf "${GREEN}[✓]${NC} All dependencies satisfied\n\n"
}

# RapidDNS enumeration
rapiddns() {
    domain=$1
    output=$2
    printf "${BLUE}[*]${NC} Running RapidDNS enumeration...\n"
    
    curl -s "https://rapiddns.io/subdomain/$domain?full=1" \
        | grep -oE "[\.a-zA-Z0-9-]+\.$domain" \
        | sort -u \
        | anew "$output" > /dev/null
    
    count=$(wc -l < "$output" 2>/dev/null || echo 0)
    printf "${GREEN}[✓]${NC} RapidDNS: ${MAGENTA}$count${NC} unique subdomains\n"
}

# crt.sh enumeration
crtsh() {
    domain=$1
    output=$2
    printf "${BLUE}[*]${NC} Running crt.sh certificate transparency logs...\n"
    
    curl -s "https://crt.sh/?q=%25.$domain" \
        | grep -oE "[\.a-zA-Z0-9-]+\.$domain" \
        | sort -u \
        | anew "$output" > /dev/null
    
    count=$(wc -l < "$output" 2>/dev/null || echo 0)
    printf "${GREEN}[✓]${NC} crt.sh: ${MAGENTA}$count${NC} unique subdomains\n"
}

# AnubisDB enumeration
anubisdb() {
    domain=$1
    output=$2
    printf "${BLUE}[*]${NC} Running AnubisDB enumeration...\n"
    
    curl -s "https://jldc.me/anubis/subdomains/$domain" \
        | jq -r '.[]' 2>/dev/null \
        | anew "$output" > /dev/null
    
    count=$(wc -l < "$output" 2>/dev/null || echo 0)
    printf "${GREEN}[✓]${NC} AnubisDB: ${MAGENTA}$count${NC} unique subdomains\n"
}

# Subfinder enumeration
run_subfinder() {
    domain=$1
    output=$2
    printf "${BLUE}[*]${NC} Running Subfinder (passive sources)...\n"
    
    subfinder -d "$domain" -all -silent 2>/dev/null | anew "$output" > /dev/null
    
    count=$(wc -l < "$output" 2>/dev/null || echo 0)
    printf "${GREEN}[✓]${NC} Subfinder: ${MAGENTA}$count${NC} unique subdomains\n"
}

# Assetfinder enumeration
run_assetfinder() {
    domain=$1
    output=$2
    printf "${BLUE}[*]${NC} Running Assetfinder...\n"
    
    assetfinder --subs-only "$domain" 2>/dev/null | anew "$output" > /dev/null
    
    count=$(wc -l < "$output" 2>/dev/null || echo 0)
    printf "${GREEN}[✓]${NC} Assetfinder: ${MAGENTA}$count${NC} unique subdomains\n"
}

# DNSDumpster via kaeferjaeger mirror
dnsdumpster() {
    domain=$1
    output=$2
    printf "${BLUE}[*]${NC} Querying DNSDumpster (via kaeferjaeger mirror)...\n"
    
    curl -s "https://kaeferjaeger.github.io/dnsdumpster/data/${domain}.json" \
        | jq -r '.[].domain' 2>/dev/null \
        | tr '[:upper:]' '[:lower:]' \
        | sort -u \
        | anew "$output" > /dev/null 2>&1 || true
    
    count=$(wc -l < "$output" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
        printf "${GREEN}[✓]${NC} DNSDumpster: ${MAGENTA}$count${NC} unique subdomains\n"
    else
        printf "${YELLOW}[!]${NC} DNSDumpster: No data available (not all domains indexed)\n"
    fi
}

# Kaeferjaeger SNI ranges (Cloud Provider reconnaissance)
kaeferjaeger_sni() {
    domain=$1
    output=$2
    printf "${BLUE}[*]${NC} Querying Cloud SNI ranges (AWS, GCP, Azure, DO, Oracle)...\n"
    
    temp_output="${output}.tmp"
    : > "$temp_output"
    
    # Cloud provider SNI range URLs
    urls="
https://kaeferjaeger.gay/sni-ip-ranges/amazon/ipv4_merged_sni.txt
https://kaeferjaeger.gay/sni-ip-ranges/digitalocean/ipv4_merged_sni.txt
https://kaeferjaeger.gay/sni-ip-ranges/google/ipv4_merged_sni.txt
https://kaeferjaeger.gay/sni-ip-ranges/microsoft/ipv4_merged_sni.txt
https://kaeferjaeger.gay/sni-ip-ranges/oracle/ipv4_merged_sni.txt
"
    
    for url in $urls; do
        provider=$(echo "$url" | grep -oP '(?<=ranges/)[^/]+')
        printf "${BLUE}  [→]${NC} Scanning ${CYAN}$provider${NC} ranges...\n"
        
        curl -s "$url" \
            | grep -F ".$domain" \
            | awk -F'-- ' '{for(i=2;i<=NF;i++) print $i}' \
            | tr ' ' '\n' \
            | tr -d '[]' \
            | grep -F ".$domain" \
            | tr '[:upper:]' '[:lower:]' >> "$temp_output" 2>/dev/null || true
    done
    
    # Deduplicate and merge
    sort -u "$temp_output" | anew "$output" > /dev/null 2>&1
    rm -f "$temp_output"
    
    count=$(wc -l < "$output" 2>/dev/null || echo 0)
    printf "${GREEN}[✓]${NC} Cloud SNI: ${MAGENTA}$count${NC} unique subdomains\n"
}

# Main execution flow
main() {
    # Parse arguments
    if [ -z "$1" ]; then
        print_banner
        usage
    fi
    
    domain=$1
    output="${domain}.subdomains.result"
    
    print_banner
    check_dependencies
    
    printf "${WHITE}[*] Target:${NC} ${GREEN}$domain${NC}\n"
    printf "${WHITE}[*] Mode:${NC} ${YELLOW}PASSIVE ENUMERATION${NC}\n"
    printf "${WHITE}[*] Output:${NC} ${CYAN}$output${NC}\n\n"
    
    # Create/reset output file
    : > "$output"
    
    # Run passive subdomain enumeration
    printf "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    printf "${WHITE}          PASSIVE SUBDOMAIN ENUMERATION                ${NC}\n"
    printf "${CYAN}═══════════════════════════════════════════════════════${NC}\n\n"
    
    run_subfinder "$domain" "$output"
    run_assetfinder "$domain" "$output"
    anubisdb "$domain" "$output"
    rapiddns "$domain" "$output"
    crtsh "$domain" "$output"
    
    printf "\n${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    printf "${WHITE}          CLOUD PROVIDER RECONNAISSANCE                ${NC}\n"
    printf "${CYAN}═══════════════════════════════════════════════════════${NC}\n\n"
    
    dnsdumpster "$domain" "$output"
    kaeferjaeger_sni "$domain" "$output"
    
    # Final count
    total=$(wc -l < "$output" 2>/dev/null || echo 0)
    printf "\n${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    printf "${GREEN}[✓] TOTAL UNIQUE SUBDOMAINS:${NC} ${WHITE}$total${NC}\n"
    printf "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    
    printf "\n${WHITE}[*] Results saved to:${NC} ${GREEN}$output${NC}\n\n"
}

# Execute
main "$@"
