    #!/bin/bash

    ################################################################################
    # Bug Bounty Subdomain Reconnaissance Tool (Bash Version)
    # A modular subdomain enumeration and HTTP probing tool
    #
    # Author: Your Name
    # Usage: ./recon.sh example.com              (passive only - default)
    #        ./recon.sh example.com --full-scan  (all phases)
    #        ./recon.sh --help
    ################################################################################

    set -euo pipefail

    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    NC='\033[0m'

    # Defaults
    DOMAIN=""
    OUTPUT_DIR="./recon_output"
    RESOLVERS=""
    WORDLIST=""
    RATE_LIMIT=2000
    THREADS=20
    MAX_RETRIES=5
    FULL_SCAN=false           # Default: passive only
    LIGHTWEIGHT=false

    log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
    log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
    log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
    log_error() { echo -e "${RED}[✗]${NC} $1"; }
    log_section() {
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}$1${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    }

    usage() {
        cat << EOF
    ${CYAN}Bug Bounty Subdomain Reconnaissance Tool (Bash Version)${NC}

    ${YELLOW}Usage:${NC}
        $0 <domain> [options]

    ${YELLOW}Modes:${NC}
        ${GREEN}Default (Passive):${NC}     Runs only passive enumeration (fast, safe)
        ${MAGENTA}--full-scan:${NC}          Runs ALL phases (passive + bruteforce + permutations + probing)

    ${YELLOW}Required:${NC}
        domain                  Target domain (e.g., example.com)

    ${YELLOW}Options:${NC}
        ${MAGENTA}--full-scan${NC}             Enable full reconnaissance (all phases)
        -r, --resolvers FILE    Path to DNS resolvers (required for --full-scan)
        -w, --wordlist FILE     Path to DNS wordlist (required for --full-scan)
        -o, --output-dir DIR    Output directory (default: ./recon_output)
        --rate-limit NUM        DNS rate limit (default: 2000)
        --threads NUM           HTTP probing threads (default: 20)
        --lightweight           Skip heavy tools like Amass (faster, less memory)
        -h, --help              Show this help message

    ${YELLOW}Examples:${NC}
        ${GREEN}# Passive enumeration only (default, fast)${NC}
        $0 example.com

        ${GREEN}# Passive with lightweight mode (no Amass)${NC}
        $0 example.com --lightweight

        ${MAGENTA}# Full scan with all phases${NC}
        $0 example.com --full-scan -r resolvers.txt -w wordlist.txt

        ${MAGENTA}# Full scan, lightweight mode${NC}
        $0 example.com --full-scan --lightweight -r resolvers.txt -w wordlist.txt

        ${GREEN}# Custom output directory${NC}
        $0 example.com -o ./my_recon

    ${YELLOW}What runs in each mode:${NC}
        ${GREEN}Passive (default):${NC}
            • subfinder
            • crt.sh (web + PostgreSQL)
            • Amass (unless --lightweight)
            • dnsdumpster
            • kaeferjaeger SNI ranges

        ${MAGENTA}Full Scan (--full-scan):${NC}
            • All passive enumeration
            • DNS bruteforce (puredns)
            • Subdomain permutations (ripgen, gotator, alterx)
            • Permutation resolution (puredns)
            • HTTP probing (httpx)

    EOF
        exit 0
    }

    parse_args() {
        [[ $# -eq 0 ]] && usage
        DOMAIN="$1"
        shift

        while [[ $# -gt 0 ]]; do
            case $1 in
                --full-scan)
                    FULL_SCAN=true
                    shift
                    ;;
                -r|--resolvers)
                    RESOLVERS="$2"
                    shift 2
                    ;;
                -w|--wordlist)
                    WORDLIST="$2"
                    shift 2
                    ;;
                -o|--output-dir)
                    OUTPUT_DIR="$2"
                    shift 2
                    ;;
                --rate-limit)
                    RATE_LIMIT="$2"
                    shift 2
                    ;;
                --threads)
                    THREADS="$2"
                    shift 2
                    ;;
                --lightweight)
                    LIGHTWEIGHT=true
                    shift
                    ;;
                -h|--help)
                    usage
                    ;;
                *)
                    log_error "Unknown option: $1"
                    echo ""
                    usage
                    ;;
            esac
        done

        OUTPUT_DIR="${OUTPUT_DIR}/${DOMAIN}"
        mkdir -p "$OUTPUT_DIR"

        # Validate full-scan requirements
        if [[ "$FULL_SCAN" == true ]]; then
            local missing_deps=false

            if [[ -z "$RESOLVERS" ]]; then
                log_error "Full scan requires --resolvers"
                missing_deps=true
            elif [[ ! -f "$RESOLVERS" ]]; then
                log_error "Resolvers file not found: $RESOLVERS"
                missing_deps=true
            fi

            if [[ -z "$WORDLIST" ]]; then
                log_error "Full scan requires --wordlist"
                missing_deps=true
            elif [[ ! -f "$WORDLIST" ]]; then
                log_error "Wordlist file not found: $WORDLIST"
                missing_deps=true
            fi

            if [[ "$missing_deps" == true ]]; then
                echo ""
                log_info "Example: $0 $DOMAIN --full-scan -r resolvers.txt -w wordlist.txt"
                exit 1
            fi
        fi
    }

    run_subfinder() {
        log_info "Running subfinder..."
        local output="${OUTPUT_DIR}/${DOMAIN}.subfinder.txt"

        if command -v subfinder &> /dev/null; then
            subfinder -d "$DOMAIN" -all -o "$output" &> "${OUTPUT_DIR}/subfinder.log"
            log_success "subfinder: Found $(wc -l < "$output" 2>/dev/null || echo "0") subdomains"
        else
            log_warning "subfinder not found, skipping"
        fi
    }

    run_crtsh_web() {
        log_info "Querying crt.sh web API..."
        local output="${OUTPUT_DIR}/${DOMAIN}.crtsh_web.txt"

        curl -s "https://crt.sh/?q=%.${DOMAIN}&output=json" |         jq -r '.[].name_value' 2>/dev/null |         sed 's/\*\.//g' |         grep -i "\.${DOMAIN}$" |         tr '[:upper:]' '[:lower:]' |         sort -u > "$output"

        log_success "crt.sh web: Found $(wc -l < "$output") subdomains"
    }

    run_crtsh_postgres() {
        log_info "Querying crt.sh PostgreSQL..."
        local output="${OUTPUT_DIR}/${DOMAIN}.crtsh_postgres.txt"

        if ! command -v psql &> /dev/null; then
            log_warning "psql not found, skipping"
            return
        fi

        local query="SELECT ci.NAME_VALUE FROM certificate_and_identities ci WHERE plainto_tsquery('certwatch', '${DOMAIN}') @@ identities(ci.CERTIFICATE)"

        for attempt in $(seq 1 $MAX_RETRIES); do
            if echo "$query" | psql -t -h crt.sh -p 5432 -U guest certwatch 2>/dev/null |             sed 's/\*\.//g' |             grep -i "\.${DOMAIN}$" |             tr '[:upper:]' '[:lower:]' |             sort -u > "$output"; then
                log_success "crt.sh PostgreSQL: Found $(wc -l < "$output") subdomains"
                return
            fi
            log_warning "crt.sh PostgreSQL attempt $attempt/$MAX_RETRIES failed, retrying..."
            sleep 2
        done
        log_error "crt.sh PostgreSQL failed after $MAX_RETRIES attempts"
    }

    run_amass() {
        if [[ "$LIGHTWEIGHT" == true ]]; then
            log_info "Amass skipped (lightweight mode)"
            return
        fi

        log_info "Running Amass (this may take a while)..."
        local output="${OUTPUT_DIR}/${DOMAIN}.amass.txt"

        if command -v amass &> /dev/null; then
            timeout 2h amass enum -d "$DOMAIN" -o "$output" &> "${OUTPUT_DIR}/amass.log" || true
            log_success "Amass: Found $(wc -l < "$output" 2>/dev/null || echo "0") subdomains"
        else
            log_warning "Amass not found, skipping"
        fi
    }

    run_dnsdumpster() {
        log_info "Querying dnsdumpster..."
        local output="${OUTPUT_DIR}/${DOMAIN}.dnsdumpster.txt"

        curl -s "https://kaeferjaeger.github.io/dnsdumpster/data/${DOMAIN}.json" |         jq -r '.[].domain' 2>/dev/null |         tr '[:upper:]' '[:lower:]' |         sort -u > "$output" 2>/dev/null || true

        local count=$(wc -l < "$output" 2>/dev/null || echo "0")
        [[ $count -gt 0 ]] && log_success "dnsdumpster: Found $count subdomains" || log_info "dnsdumpster: No data available"
    }

    run_kaeferjaeger() {
        log_info "Querying kaeferjaeger SNI ranges..."
        local output="${OUTPUT_DIR}/${DOMAIN}.kaeferjaeger.txt"
        > "$output"

        local urls=(
            "https://kaeferjaeger.gay/sni-ip-ranges/amazon/ipv4_merged_sni.txt"
            "https://kaeferjaeger.gay/sni-ip-ranges/digitalocean/ipv4_merged_sni.txt"
            "https://kaeferjaeger.gay/sni-ip-ranges/google/ipv4_merged_sni.txt"
            "https://kaeferjaeger.gay/sni-ip-ranges/microsoft/ipv4_merged_sni.txt"
            "https://kaeferjaeger.gay/sni-ip-ranges/oracle/ipv4_merged_sni.txt"
        )

        for url in "${urls[@]}"; do
            curl -s "$url" |             grep -F ".${DOMAIN}" |             awk -F'-- ' '{for(i=2;i<=NF;i++) print $i}' |             tr ' ' '\n' | tr -d '[]' |             grep -F ".${DOMAIN}" |             tr '[:upper:]' '[:lower:]' >> "$output" || true
        done

        sort -u "$output" -o "$output"
        log_success "kaeferjaeger: Found $(wc -l < "$output") subdomains"
    }

    run_passive_enumeration() {
        log_section "[Phase 1] Passive Subdomain Enumeration"

        run_subfinder
        run_crtsh_web
        run_crtsh_postgres
        run_amass
        run_dnsdumpster
        run_kaeferjaeger

        local passive="${OUTPUT_DIR}/${DOMAIN}.passive_subdomains.txt"
        cat "${OUTPUT_DIR}/${DOMAIN}".*.txt 2>/dev/null |         grep -v '^$' |         sort -u > "$passive"

        echo ""
        log_success "Passive enumeration complete: $(wc -l < "$passive") unique subdomains found"
        log_info "Results saved to: $passive"
    }

    run_dns_bruteforce() {
        log_section "[Phase 2] DNS Bruteforce"

        if [[ "$FULL_SCAN" == false ]]; then
            log_info "Skipped (not in full scan mode)"
            return
        fi

        if ! command -v puredns &> /dev/null; then
            log_warning "puredns not found, skipping DNS bruteforce"
            return
        fi

        log_info "Running puredns bruteforce..."
        local output="${OUTPUT_DIR}/${DOMAIN}.dnsbrute.txt"

        puredns bruteforce "$WORDLIST" "$DOMAIN"         -r "$RESOLVERS" --rate-limit "$RATE_LIMIT"         --write "$output" &> "${OUTPUT_DIR}/dnsbrute.log" || true

        echo ""
        log_success "DNS bruteforce complete: $(wc -l < "$output" 2>/dev/null || echo "0") new subdomains found"
    }

    generate_permutations() {
        log_section "[Phase 3] Subdomain Permutations"

        if [[ "$FULL_SCAN" == false ]]; then
            log_info "Skipped (not in full scan mode)"
            return
        fi

        local input="${OUTPUT_DIR}/${DOMAIN}.current_subdomains.txt"
        cat "${OUTPUT_DIR}/${DOMAIN}".*.txt 2>/dev/null |         grep -v '^$' |         sort -u > "$input"

        # ripgen
        if command -v ripgen &> /dev/null; then
            log_info "Running ripgen..."
            ripgen -d "$input" --fast true > "${OUTPUT_DIR}/${DOMAIN}.ripgen.perm" 2>/dev/null || true
            log_success "ripgen: Generated $(wc -l < "${OUTPUT_DIR}/${DOMAIN}.ripgen.perm" 2>/dev/null || echo "0") permutations"
        else
            log_warning "ripgen not found, skipping"
        fi

        # gotator
        if command -v gotator &> /dev/null; then
            log_info "Running gotator..."
            gotator -sub "$input" -depth 2 -mindup > "${OUTPUT_DIR}/${DOMAIN}.gotator.perm" 2>/dev/null || true
            log_success "gotator: Generated $(wc -l < "${OUTPUT_DIR}/${DOMAIN}.gotator.perm" 2>/dev/null || echo "0") permutations"
        else
            log_warning "gotator not found, skipping"
        fi

        # alterx
        if command -v alterx &> /dev/null; then
            log_info "Running alterx..."
            alterx -l "$input" -o "${OUTPUT_DIR}/${DOMAIN}.alterx.perm" &> /dev/null || true
            log_success "alterx: Generated $(wc -l < "${OUTPUT_DIR}/${DOMAIN}.alterx.perm" 2>/dev/null || echo "0") permutations"
        else
            log_warning "alterx not found, skipping"
        fi

        local perms="${OUTPUT_DIR}/${DOMAIN}.all_perms.txt"
        cat "${OUTPUT_DIR}/${DOMAIN}".*.perm 2>/dev/null |         grep -v '^$' |         sort -u > "$perms"

        local perm_count=$(wc -l < "$perms" 2>/dev/null || echo "0")
        echo ""
        log_success "Generated $perm_count total permutations"

        # Resolve permutations
        if [[ $perm_count -gt 0 ]] && command -v puredns &> /dev/null; then
            log_info "Resolving permutations..."
            local resolved="${OUTPUT_DIR}/${DOMAIN}.resolved.txt"
            puredns resolve "$perms" -r "$RESOLVERS" --rate-limit "$RATE_LIMIT"             --write "$resolved" &> "${OUTPUT_DIR}/resolve.log" || true
            echo ""
            log_success "Resolved $(wc -l < "$resolved" 2>/dev/null || echo "0") permutations"
        fi
    }

    run_http_probing() {
        log_section "[Phase 4] HTTP Probing"

        if [[ "$FULL_SCAN" == false ]]; then
            log_info "Skipped (not in full scan mode)"
            log_info "Tip: Use --full-scan to enable HTTP probing"
            return
        fi

        if ! command -v httpx &> /dev/null; then
            log_warning "httpx not found, skipping HTTP probing"
            return
        fi

        local input="${OUTPUT_DIR}/${DOMAIN}.final_subdomains.txt"
        local output="${OUTPUT_DIR}/${DOMAIN}.httpx.json"
        local count=$(wc -l < "$input")

        log_info "Running httpx on $count subdomains..."
        httpx -l "$input" -silent -follow-redirects -status-code -title         -tech-detect -content-length -web-server -json         -mc 200,201,204,301,302,307,308,401,403,404,405,500,502,503         -t "$THREADS" -rl 40 -o "$output" 2>/dev/null || true

        echo ""
        log_success "HTTP probing complete: $(wc -l < "$output" 2>/dev/null || echo "0") live hosts found"
        log_info "Results saved to: $output"
    }

    finalize_results() {
        log_section "Finalizing Results"

        local final="${OUTPUT_DIR}/${DOMAIN}.final_subdomains.txt"
        cat "${OUTPUT_DIR}/${DOMAIN}".*.txt 2>/dev/null |         grep -v '^$' |         grep -i "\.${DOMAIN}$" |         sort -u > "$final"

        local total=$(wc -l < "$final")

        echo ""
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_success "Total subdomains discovered: $total"
        log_success "Final results saved to: $final"
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Send notification
        if command -v notify &> /dev/null; then
            echo "Recon completed for ${DOMAIN}. Total subdomains: ${total}" |             notify -silent -bulk -id "recon-${DOMAIN}" 2>/dev/null || true
        fi
    }

    main() {
        local start=$(date +%s)
        parse_args "$@"

        echo ""
        log_section "Bug Bounty Subdomain Reconnaissance Tool"
        echo ""
        echo -e "${CYAN}Target:${NC}        $DOMAIN"
        echo -e "${CYAN}Mode:${NC}          $(if [[ "$FULL_SCAN" == true ]]; then echo -e "${MAGENTA}Full Scan${NC}"; else echo -e "${GREEN}Passive Only${NC}"; fi)"
        echo -e "${CYAN}Profile:${NC}       $(if [[ "$LIGHTWEIGHT" == true ]]; then echo "Lightweight"; else echo "Standard"; fi)"
        echo -e "${CYAN}Output:${NC}        $OUTPUT_DIR"
        if [[ "$FULL_SCAN" == true ]]; then
            echo -e "${CYAN}Resolvers:${NC}     $RESOLVERS"
            echo -e "${CYAN}Wordlist:${NC}      $WORDLIST"
        fi
        echo ""

        if [[ "$FULL_SCAN" == false ]]; then
            echo -e "${YELLOW}ℹ Running in passive mode (default)${NC}"
            echo -e "${YELLOW}ℹ Use --full-scan for DNS bruteforce, permutations, and HTTP probing${NC}"
            echo ""
        fi

        # Run phases
        run_passive_enumeration

        if [[ "$FULL_SCAN" == true ]]; then
            run_dns_bruteforce
            generate_permutations
        fi

        finalize_results

        if [[ "$FULL_SCAN" == true ]]; then
            run_http_probing
        fi

        local elapsed=$(($(date +%s) - start))
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))

        echo ""
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_success "Reconnaissance completed in ${minutes}m ${seconds}s"
        if [[ "$FULL_SCAN" == false ]]; then
            echo -e "${YELLOW}ℹ This was a passive scan. For full recon, use: --full-scan${NC}"
        fi
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    }

    main "$@"
