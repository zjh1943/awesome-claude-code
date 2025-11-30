#!/usr/bin/env zsh

# Claude Code Diagnostic Tool for macOS/Linux
# Diagnoses connectivity, authentication, and installation issues

set -o pipefail

# Configuration
API_SERVER="https://claude-code.club/api"
API_ENDPOINT="${API_SERVER}/v1/models"
EXPECTED_BASE_URL="https://claude-code.club/api"

# Global flags
VERBOSE=false
AUTO_FIX=false
OUTPUT_FILE=""
ISSUES_FOUND=()
RECOMMENDATIONS=()

# Colors disabled (plain text output)
RESET=""
RED=""
GREEN=""
YELLOW=""
BLUE=""

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

print_section() {
    echo ""
    echo "[$1] $2"
    echo "----------------------------------------"
}

print_check() {
    local check_status="$1"
    local message="$2"
    if [[ "$check_status" == "ok" ]]; then
        echo "✓ $message"
    elif [[ "$check_status" == "warn" ]]; then
        echo "⚠ $message"
        ISSUES_FOUND+=("WARNING: $message")
    elif [[ "$check_status" == "error" ]]; then
        echo "✗ $message"
        ISSUES_FOUND+=("ERROR: $message")
    else
        echo "  $message"
    fi
}

add_recommendation() {
    RECOMMENDATIONS+=("$1")
}

verbose_log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "  [VERBOSE] $1"
    fi
}

# ============================================================================
# Diagnostic Functions
# ============================================================================

check_environment() {
    print_section "1" "Environment Check"

    # Check for curl
    if command -v curl &> /dev/null; then
        local curl_version=$(curl --version | head -n1)
        print_check "ok" "curl: Found ($curl_version)"
        verbose_log "curl path: $(command -v curl)"
    else
        print_check "error" "curl: Not found (required for diagnostics)"
        add_recommendation "Install curl: brew install curl (macOS) or use your package manager"
        return 1
    fi

    # Check for jq (optional)
    if command -v jq &> /dev/null; then
        print_check "ok" "jq: Found (optional JSON parser)"
        verbose_log "jq path: $(command -v jq)"
    else
        print_check "info" "jq: Not found (optional, install for better output formatting)"
        verbose_log "Install jq: brew install jq"
    fi

    # Check shell
    print_check "info" "Shell: $SHELL"
    verbose_log "Shell version: $ZSH_VERSION"
}

check_authentication() {
    print_section "2" "Authentication Diagnostics"

    # Check ANTHROPIC_AUTH_TOKEN
    if [[ -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
        local token_preview="${ANTHROPIC_AUTH_TOKEN:0:10}...${ANTHROPIC_AUTH_TOKEN: -4}"
        print_check "ok" "ANTHROPIC_AUTH_TOKEN: Set ($token_preview)"
        verbose_log "Token length: ${#ANTHROPIC_AUTH_TOKEN}"
    else
        print_check "error" "ANTHROPIC_AUTH_TOKEN: Not set (required)"
        add_recommendation "Set ANTHROPIC_AUTH_TOKEN: export ANTHROPIC_AUTH_TOKEN='your-token-here'"
        add_recommendation "Add to ~/.zshrc for persistence: echo 'export ANTHROPIC_AUTH_TOKEN=\"your-token\"' >> ~/.zshrc"
    fi

    # Check for incorrect ANTHROPIC_API_KEY
    if [[ -n "$ANTHROPIC_API_KEY" ]]; then
        print_check "warn" "ANTHROPIC_API_KEY: Detected (should NOT be used with claude-code.club)"
        add_recommendation "Remove ANTHROPIC_API_KEY from your environment (check ~/.zshrc, ~/.bashrc, ~/.profile)"

        if [[ "$AUTO_FIX" == true ]]; then
            verbose_log "Auto-fix: Would unset ANTHROPIC_API_KEY (implementation pending)"
        fi
    else
        print_check "ok" "ANTHROPIC_API_KEY: Not set (correct)"
    fi

    # Check ANTHROPIC_BASE_URL
    if [[ -n "$ANTHROPIC_BASE_URL" ]]; then
        if [[ "$ANTHROPIC_BASE_URL" == "$EXPECTED_BASE_URL" ]]; then
            print_check "ok" "ANTHROPIC_BASE_URL: Correctly set to $ANTHROPIC_BASE_URL"
        else
            print_check "warn" "ANTHROPIC_BASE_URL: Set to '$ANTHROPIC_BASE_URL' (expected: $EXPECTED_BASE_URL)"
            add_recommendation "Update ANTHROPIC_BASE_URL: export ANTHROPIC_BASE_URL='$EXPECTED_BASE_URL'"
        fi
    else
        print_check "info" "ANTHROPIC_BASE_URL: Not set (optional, defaults to claude-code.club)"
    fi

    # Check for official Anthropic Console cache
    local console_cache_locations=(
        "$HOME/.config/claude"
        "$HOME/.anthropic"
        "$HOME/Library/Application Support/Claude"
    )

    for cache_dir in "${console_cache_locations[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            print_check "warn" "Official Console cache detected: $cache_dir (may cause conflicts)"
            verbose_log "Contents: $(ls -la "$cache_dir" 2>/dev/null || echo 'Permission denied')"
            add_recommendation "Consider backing up and removing: $cache_dir"
        fi
    done
}

check_network() {
    print_section "3" "Network Diagnostics"

    local domain="claude-code.club"

    # DNS Resolution
    verbose_log "Testing DNS resolution for $domain..."
    if host "$domain" &> /dev/null 2>&1 || nslookup "$domain" &> /dev/null 2>&1; then
        local ip_address=$(host "$domain" 2>/dev/null | grep "has address" | head -n1 | awk '{print $NF}' || echo "unknown")
        print_check "ok" "DNS Resolution: $domain → $ip_address"
        verbose_log "DNS lookup successful"
    else
        print_check "error" "DNS Resolution: Failed to resolve $domain"
        add_recommendation "Check DNS settings. Try: sudo dscacheutil -flushcache (macOS) or check /etc/resolv.conf"
        add_recommendation "Test with: host $domain or nslookup $domain"
    fi

    # TLS/SSL Test
    verbose_log "Testing TLS handshake..."
    local tls_test=$(echo | openssl s_client -connect "${domain}:443" -servername "$domain" 2>&1)

    if echo "$tls_test" | grep -q "Verify return code: 0"; then
        print_check "ok" "TLS Handshake: Successful"
        verbose_log "Certificate verification passed"
    else
        if echo "$tls_test" | grep -qi "certificate"; then
            print_check "error" "TLS Handshake: Certificate verification failed"
            add_recommendation "Check system certificates. Try: security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain (macOS)"
        else
            print_check "warn" "TLS Handshake: Unable to verify (may be blocked)"
            add_recommendation "Check firewall settings and network connectivity"
        fi
        verbose_log "OpenSSL output: $tls_test"
    fi

    # API Connectivity Test
    verbose_log "Testing API endpoint: $API_ENDPOINT"

    if [[ -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
        local curl_output
        local http_code

        if [[ "$VERBOSE" == true ]]; then
            print_check "info" "Running verbose curl test..."
            curl_output=$(curl -v "$API_ENDPOINT" \
                --header "x-api-key: $ANTHROPIC_AUTH_TOKEN" \
                --header "anthropic-version: 2023-06-01" \
                --max-time 10 \
                2>&1)

            http_code=$(echo "$curl_output" | grep "< HTTP" | tail -n1 | awk '{print $3}')
            echo "  --- Curl Output ---"
            echo "$curl_output"
            echo "  --- End Curl Output ---"
        else
            curl_output=$(curl -s -w "\n%{http_code}" "$API_ENDPOINT" \
                --header "x-api-key: $ANTHROPIC_AUTH_TOKEN" \
                --header "anthropic-version: 2023-06-01" \
                --max-time 10 \
                2>&1)
            http_code=$(echo "$curl_output" | tail -n1)
        fi

        verbose_log "HTTP Status Code: $http_code"

        case "$http_code" in
            200)
                print_check "ok" "API Connection: Successful (HTTP $http_code)"
                ;;
            401)
                print_check "error" "API Connection: Authentication failed (HTTP 401)"
                add_recommendation "Verify ANTHROPIC_AUTH_TOKEN is valid and not expired"
                ;;
            403)
                print_check "error" "API Connection: Access forbidden (HTTP 403)"
                add_recommendation "Check if your token has proper permissions"
                ;;
            404)
                print_check "error" "API Connection: Endpoint not found (HTTP 404)"
                add_recommendation "Verify API endpoint URL: $API_ENDPOINT"
                ;;
            000|"")
                print_check "error" "API Connection: Connection failed (timeout or network error)"
                add_recommendation "Check network connectivity and firewall settings"
                if [[ "$curl_output" =~ "Could not resolve host" ]]; then
                    add_recommendation "DNS resolution failed - check your DNS settings"
                elif [[ "$curl_output" =~ "Connection refused" ]]; then
                    add_recommendation "Connection refused - service may be down or blocked"
                elif [[ "$curl_output" =~ "SSL" ]] || [[ "$curl_output" =~ "certificate" ]]; then
                    add_recommendation "SSL/TLS error - check certificates and system time"
                fi
                ;;
            *)
                print_check "warn" "API Connection: Unexpected response (HTTP $http_code)"
                verbose_log "Response: $curl_output"
                ;;
        esac
    else
        print_check "info" "API Connection: Skipped (no ANTHROPIC_AUTH_TOKEN set)"
    fi
}

check_proxy_vpn() {
    print_section "3.5" "Proxy & VPN Diagnostics"

    # Check proxy environment variables
    print_check "info" "Checking proxy environment variables..."
    local proxy_vars=(http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY)
    local proxy_found=false
    local proxy_values=()

    for var in "${proxy_vars[@]}"; do
        local var_value=$(eval echo \$$var)
        if [[ -n "$var_value" ]]; then
            proxy_found=true
            print_check "warn" "$var: $var_value"
            proxy_values+=("$var=$var_value")
            verbose_log "Proxy variable detected: $var"

            # Check if it's lowercase and uppercase both set
            if [[ "$var" == "http_proxy" ]] && [[ -n "$HTTP_PROXY" ]]; then
                if [[ "$var_value" != "$HTTP_PROXY" ]]; then
                    print_check "warn" "Conflicting proxy settings: http_proxy != HTTP_PROXY"
                fi
            fi
        fi
    done

    if [[ "$proxy_found" == false ]]; then
        print_check "ok" "No proxy environment variables set"
    else
        # Check if claude-code.club is in no_proxy
        local no_proxy_value="${no_proxy}${NO_PROXY}"
        if [[ ! "$no_proxy_value" =~ claude-code\.club ]]; then
            print_check "warn" "claude-code.club NOT in no_proxy list - proxy may block connection"
            add_recommendation "Add to no_proxy: export no_proxy=\"\$no_proxy,claude-code.club,.claude-code.club\""
            add_recommendation "For persistence, add to ~/.zshrc: echo 'export no_proxy=\"\$no_proxy,claude-code.club\"' >> ~/.zshrc"
        else
            print_check "ok" "claude-code.club is in no_proxy list"
        fi
    fi

    # Check system proxy settings (macOS)
    if command -v scutil &> /dev/null; then
        verbose_log "Checking macOS system proxy settings..."
        local proxy_info=$(scutil --proxy 2>/dev/null)

        if echo "$proxy_info" | grep -q "HTTPEnable.*1"; then
            local http_proxy_host=$(echo "$proxy_info" | grep 'HTTPProxy :' | awk '{print $3}')
            local http_proxy_port=$(echo "$proxy_info" | grep 'HTTPPort :' | awk '{print $3}')
            if [[ -n "$http_proxy_host" ]]; then
                print_check "warn" "System HTTP Proxy: $http_proxy_host:$http_proxy_port"
                verbose_log "macOS system HTTP proxy is enabled"
            fi
        else
            print_check "ok" "System HTTP Proxy: Disabled"
        fi

        if echo "$proxy_info" | grep -q "HTTPSEnable.*1"; then
            local https_proxy_host=$(echo "$proxy_info" | grep 'HTTPSProxy :' | awk '{print $3}')
            local https_proxy_port=$(echo "$proxy_info" | grep 'HTTPSPort :' | awk '{print $3}')
            if [[ -n "$https_proxy_host" ]]; then
                print_check "warn" "System HTTPS Proxy: $https_proxy_host:$https_proxy_port"
                verbose_log "macOS system HTTPS proxy is enabled"
            fi
        else
            print_check "ok" "System HTTPS Proxy: Disabled"
        fi
    fi

    # VPN Detection
    print_check "info" "Checking for active VPN connections..."
    local vpn_detected=false
    local vpn_interfaces=()
    local vpn_info=""

    # Method 1: Check for VPN interfaces
    local vpn_if_list=$(ifconfig 2>/dev/null | grep -E "^(utun|tun|tap|ppp)" | cut -d: -f1)
    if [[ -n "$vpn_if_list" ]]; then
        while IFS= read -r interface; do
            if ifconfig "$interface" 2>/dev/null | grep -q "inet"; then
                vpn_detected=true
                vpn_interfaces+=("$interface")
                local vpn_ip=$(ifconfig "$interface" 2>/dev/null | grep "inet " | awk '{print $2}')
                print_check "warn" "VPN Interface detected: $interface (IP: $vpn_ip)"
                verbose_log "VPN interface $interface is active with IP $vpn_ip"
                vpn_info="$interface"
            fi
        done <<< "$vpn_if_list"
    fi

    # Method 2: Check scutil for VPN connections (macOS)
    if command -v scutil &> /dev/null; then
        local vpn_connections=$(scutil --nc list 2>/dev/null | grep "Connected")
        if [[ -n "$vpn_connections" ]]; then
            vpn_detected=true
            print_check "warn" "Active VPN connection(s) detected"
            verbose_log "VPN connections: $vpn_connections"
        fi
    fi

    # Method 3: Check for common VPN processes
    local vpn_processes=$(ps aux 2>/dev/null | grep -iE "openvpn|cisco|anyconnect|wireguard|nordvpn|expressvpn|tunnelblick" | grep -v grep)
    if [[ -n "$vpn_processes" ]]; then
        vpn_detected=true
        verbose_log "VPN processes detected:"
        verbose_log "$vpn_processes"

        # Identify specific VPN software
        if echo "$vpn_processes" | grep -qi "cisco\|anyconnect"; then
            print_check "warn" "Cisco AnyConnect VPN detected"
        elif echo "$vpn_processes" | grep -qi "openvpn"; then
            print_check "warn" "OpenVPN detected"
        elif echo "$vpn_processes" | grep -qi "wireguard"; then
            print_check "warn" "WireGuard VPN detected"
        elif echo "$vpn_processes" | grep -qi "nordvpn"; then
            print_check "warn" "NordVPN detected"
        elif echo "$vpn_processes" | grep -qi "expressvpn"; then
            print_check "warn" "ExpressVPN detected"
        elif echo "$vpn_processes" | grep -qi "tunnelblick"; then
            print_check "warn" "Tunnelblick VPN detected"
        fi
    fi

    if [[ "$vpn_detected" == false ]]; then
        print_check "ok" "No active VPN detected"
    else
        add_recommendation "VPN detected - if experiencing connectivity issues, try disconnecting VPN temporarily"
        add_recommendation "If VPN is required, ensure claude-code.club is whitelisted/bypassed in VPN configuration"

        # Tunnel mode analysis
        print_check "info" "Analyzing VPN tunnel mode..."

        # Check for default route through VPN
        local default_route=$(netstat -rn 2>/dev/null | grep "^default\|^0.0.0.0" | head -n1)
        verbose_log "Default route: $default_route"

        local full_tunnel=false
        for vpn_if in "${vpn_interfaces[@]}"; do
            if echo "$default_route" | grep -q "$vpn_if"; then
                full_tunnel=true
                print_check "warn" "FULL TUNNEL detected: Default route goes through $vpn_if"
                verbose_log "All traffic is routed through VPN interface $vpn_if"
            fi
        done

        if [[ "$full_tunnel" == true ]]; then
            print_check "warn" "All network traffic routes through VPN (full tunnel mode)"
            add_recommendation "Full tunnel VPN detected - all traffic goes through VPN, including claude-code.club"
            add_recommendation "If blocked, contact network admin to whitelist claude-code.club domain"
            add_recommendation "Consider requesting split tunnel mode if permitted by your organization"
        else
            print_check "info" "Split tunnel mode detected (selective routing)"

            # Check specific route to claude-code.club
            local route_to_api=$(route -n get claude-code.club 2>/dev/null | grep "interface:" | awk '{print $2}')
            if [[ -n "$route_to_api" ]]; then
                verbose_log "Route to claude-code.club: $route_to_api"
                for vpn_if in "${vpn_interfaces[@]}"; do
                    if [[ "$route_to_api" == "$vpn_if" ]]; then
                        print_check "warn" "Route to claude-code.club goes through VPN ($vpn_if)"
                        add_recommendation "claude-code.club routes through VPN - may be blocked by corporate firewall"
                        add_recommendation "Add claude-code.club to VPN split tunnel bypass list"
                    fi
                done
            fi
        fi

        # Show routing table in verbose mode
        if [[ "$VERBOSE" == true ]]; then
            echo "  [VERBOSE] Routing table:"
            netstat -rn 2>/dev/null | grep -E "^default|^0\.0\.0\.0|utun|tun|tap|ppp" | sed 's/^/    /'
        fi
    fi
}

check_installation() {
    print_section "5" "Installation Discovery"

    # Find Claude Code binary
    local claude_locations=(
        "/opt/homebrew/bin/claude"
        "/usr/local/bin/claude"
        "$HOME/.npm-global/bin/claude"
        "$HOME/.npm/bin/claude"
        "/usr/bin/claude"
    )

    local found_locations=()

    # Check PATH first
    if command -v claude &> /dev/null; then
        local claude_path=$(command -v claude)
        print_check "ok" "Claude Code: Found at $claude_path"
        found_locations+=("$claude_path")

        # Get version
        local version=$(claude --version 2>/dev/null || echo "unknown")
        print_check "info" "Version: $version"
        verbose_log "Binary path: $claude_path"

        # Detect installation method
        if [[ "$claude_path" =~ "homebrew" ]]; then
            print_check "info" "Installation method: Homebrew"
        elif [[ "$claude_path" =~ "npm" ]]; then
            print_check "info" "Installation method: npm"
        else
            print_check "info" "Installation method: Unknown (manual or other)"
        fi

        # Verify PATH includes the directory
        local claude_dir=$(dirname "$claude_path")
        check_path_environment "$claude_dir" "claude"
    else
        print_check "error" "Claude Code: Not found in PATH"

        # Check other known locations
        local not_in_path_locations=()
        for location in "${claude_locations[@]}"; do
            if [[ -f "$location" ]]; then
                not_in_path_locations+=("$location")
                print_check "warn" "Claude Code found at: $location (NOT in PATH)"
                verbose_log "Found installation outside PATH"
            fi
        done

        if [[ ${#not_in_path_locations[@]} -gt 0 ]]; then
            print_check "error" "PATH environment variable does not include Claude Code directory"
            add_recommendation "The claude command was found but is not accessible because its directory is not in PATH"

            for location in "${not_in_path_locations[@]}"; do
                local dir=$(dirname "$location")
                add_recommendation "Add to PATH: export PATH=\"\$PATH:$dir\""

                # Detect shell and provide persistent solution
                if [[ "$SHELL" =~ "zsh" ]]; then
                    add_recommendation "For persistence (zsh): echo 'export PATH=\"\$PATH:$dir\"' >> ~/.zshrc && source ~/.zshrc"
                elif [[ "$SHELL" =~ "bash" ]]; then
                    add_recommendation "For persistence (bash): echo 'export PATH=\"\$PATH:$dir\"' >> ~/.bashrc && source ~/.bashrc"
                else
                    add_recommendation "For persistence: Add 'export PATH=\"\$PATH:$dir\"' to your shell config file (~/.zshrc or ~/.bashrc)"
                fi
            done

            add_recommendation "After adding to PATH, restart your terminal or run: source ~/.zshrc (or ~/.bashrc)"
        else
            print_check "error" "No Claude Code installation found"
            add_recommendation "Install Claude Code: npm install -g @anthropic-ai/claude-code"
            add_recommendation "Or install via Homebrew: brew install claude-code"
            add_recommendation "If already installed via npm, ensure npm global bin directory is in PATH"
            add_recommendation "Check npm global bin: npm config get prefix (add <prefix>/bin to PATH)"
        fi
    fi

    # Check for multiple installations (only if claude is in PATH)
    if [[ ${#found_locations[@]} -gt 0 ]]; then
        for location in "${claude_locations[@]}"; do
            if [[ -f "$location" ]] && [[ ! " ${found_locations[@]} " =~ " ${location} " ]]; then
                print_check "warn" "Additional installation found: $location"
                verbose_log "Multiple installations detected - may cause version conflicts"
                add_recommendation "Multiple Claude Code installations found - consider removing duplicates"
            fi
        done
    fi
}

check_path_environment() {
    local binary_path="$1"
    local binary_name="$2"

    verbose_log "Checking if $binary_path is in PATH..."

    # Check if the directory is in PATH
    if echo "$PATH" | grep -q "$binary_path"; then
        print_check "ok" "PATH: $binary_path is in \$PATH"
        verbose_log "Found in current PATH environment"
    else
        print_check "warn" "PATH: $binary_path not found in \$PATH"
        verbose_log "Not found in current PATH"
        add_recommendation "PATH may not be persisted or not loaded in current session"
        add_recommendation "Add $binary_path to PATH: export PATH=\"\$PATH:$binary_path\""
    fi

    # Check shell configuration files for PATH persistence
    local shell_configs=()
    if [[ "$SHELL" =~ "zsh" ]]; then
        shell_configs=("$HOME/.zshrc" "$HOME/.zshenv")
    elif [[ "$SHELL" =~ "bash" ]]; then
        shell_configs=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    else
        shell_configs=("$HOME/.profile")
    fi

    local found_in_config=false
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]] && grep -q "$binary_path" "$config_file" 2>/dev/null; then
            print_check "ok" "PATH persistence: Found in $config_file"
            verbose_log "PATH entry found in shell config: $config_file"
            found_in_config=true
            break
        fi
    done

    if [[ "$found_in_config" == false ]]; then
        print_check "warn" "PATH persistence: $binary_path not found in shell configuration files"
        verbose_log "Not found in shell configs: ${shell_configs[*]}"

        if [[ "$SHELL" =~ "zsh" ]]; then
            add_recommendation "For persistent PATH, add to ~/.zshrc: echo 'export PATH=\"\$PATH:$binary_path\"' >> ~/.zshrc"
        elif [[ "$SHELL" =~ "bash" ]]; then
            add_recommendation "For persistent PATH, add to ~/.bashrc: echo 'export PATH=\"\$PATH:$binary_path\"' >> ~/.bashrc"
        else
            add_recommendation "For persistent PATH, add 'export PATH=\"\$PATH:$binary_path\"' to your shell config file"
        fi
    fi
}

check_configuration() {
    print_section "6" "Configuration Files"

    local config_locations=(
        "$HOME/.config/claude-code"
        "$HOME/.claude-code"
    )

    local env_files=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.profile"
        "$HOME/.zshenv"
    )

    # Check config directories
    local config_found=false
    for config_dir in "${config_locations[@]}"; do
        if [[ -d "$config_dir" ]]; then
            print_check "ok" "Config directory: $config_dir"
            verbose_log "Contents: $(ls -la "$config_dir" 2>/dev/null | tail -n +4)"
            config_found=true
        fi
    done

    if [[ "$config_found" == false ]]; then
        print_check "info" "No Claude Code config directories found"
    fi

    # Check environment files for Claude Code settings
    print_check "info" "Checking environment files for Claude Code variables..."
    for env_file in "${env_files[@]}"; do
        if [[ -f "$env_file" ]]; then
            if grep -q "ANTHROPIC" "$env_file" 2>/dev/null; then
                print_check "ok" "Found ANTHROPIC variables in: $env_file"
                if [[ "$VERBOSE" == true ]]; then
                    echo "  Relevant lines:"
                    grep "ANTHROPIC" "$env_file" | sed 's/^/    /'
                fi
            fi
        fi
    done
}

# ============================================================================
# Report Generation
# ============================================================================

generate_report() {
    print_header "Diagnostic Summary"

    echo ""
    if [[ ${#ISSUES_FOUND[@]} -eq 0 ]]; then
        echo "✓ No critical issues detected!"
    else
        echo "Issues Found: ${#ISSUES_FOUND[@]}"
        echo ""
        for issue in "${ISSUES_FOUND[@]}"; do
            echo "  • $issue"
        done
    fi

    if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
        echo ""
        print_header "Recommendations"
        echo ""
        local counter=1
        for rec in "${RECOMMENDATIONS[@]}"; do
            echo "$counter. $rec"
            ((counter++))
        done
    fi

    echo ""
    print_header "Diagnostic Complete"

    # Save to file if requested
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo ""
        echo "Saving diagnostic report to: $OUTPUT_FILE"
        # The report will be saved by redirecting stdout
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

show_help() {
    cat << EOF
Claude Code Diagnostic Tool

Usage: $0 [OPTIONS]

Diagnoses connectivity, authentication, and installation issues with Claude Code.

OPTIONS:
    --verbose           Enable detailed logging output
    --fix              Attempt to automatically fix common issues
    --output FILE      Save diagnostic report to FILE
    --help             Display this help message

EXAMPLES:
    $0                          # Run basic diagnostics
    $0 --verbose                # Run with detailed logging
    $0 --output report.txt      # Save results to file
    $0 --verbose --fix          # Run with auto-fix and detailed logging

For more information, visit: https://github.com/anthropics/claude-code

EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --fix|-f)
                AUTO_FIX=true
                shift
                ;;
            --output|-o)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Redirect output to file if requested
    if [[ -n "$OUTPUT_FILE" ]]; then
        exec > >(tee "$OUTPUT_FILE")
    fi

    # Run diagnostics
    print_header "Claude Code Diagnostic Tool"
    echo "Target API: $API_SERVER"
    echo "Date: $(date)"

    check_environment
    check_authentication
    check_network
    check_proxy_vpn
    check_installation
    check_configuration
    generate_report

    # Exit code based on issues found
    if [[ ${#ISSUES_FOUND[@]} -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
