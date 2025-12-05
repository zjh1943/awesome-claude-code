# Claude Code Diagnostic Tool for Windows
# Diagnoses connectivity, authentication, and installation issues

param(
    [switch]$Verbose,
    [switch]$Fix,
    [string]$Output = "",
    [switch]$Help
)

# Configuration
$API_SERVER = "https://claude-code.club/api"
$API_ENDPOINT = "$API_SERVER/v1/models"
$EXPECTED_BASE_URL = "https://claude-code.club/api"

# Global state
$script:IssuesFound = @()
$script:Recommendations = @()
$script:VerboseMode = $Verbose
$script:AutoFix = $Fix

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================"
    Write-Host $Message
    Write-Host "========================================"
}

function Write-Section {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host "[$Number] $Title"
    Write-Host "----------------------------------------"
}

function Write-Check {
    param(
        [string]$Status,
        [string]$Message
    )

    switch ($Status) {
        "ok" {
            Write-Host "[OK] $Message"
        }
        "warn" {
            Write-Host "[WARN] $Message"
            $script:IssuesFound += "WARNING: $Message"
        }
        "error" {
            Write-Host "[FAIL] $Message"
            $script:IssuesFound += "ERROR: $Message"
        }
        default {
            Write-Host "  $Message"
        }
    }
}

function Add-Recommendation {
    param([string]$Message)
    $script:Recommendations += $Message
}

function Write-VerboseLog {
    param([string]$Message)
    if ($script:VerboseMode) {
        Write-Host "  [VERBOSE] $Message"
    }
}

# ============================================================================
# Diagnostic Functions
# ============================================================================

function Test-Environment {
    Write-Section "1" "Environment Check"

    # Check for curl.exe specifically to avoid PowerShell alias issues
    $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curlCmd) {
        try {
            $curlVersion = & curl.exe --version 2>&1 | Select-Object -First 1
            Write-Check "ok" "curl: Found ($curlVersion)"
            Write-VerboseLog "curl path: $($curlCmd.Source)"
        } catch {
            Write-Check "warn" "curl: Found but unable to get version"
        }
    } else {
        Write-Check "error" "curl: Not found `(required for diagnostics`)"
        Add-Recommendation "Install curl: Download from https://curl.se/windows/ or use 'winget install curl'"
        return $false
    }

    # Check for jq (optional)
    $jqCmd = Get-Command jq -ErrorAction SilentlyContinue
    if ($jqCmd) {
        Write-Check "ok" "jq: Found `(optional JSON parser`)"
        Write-VerboseLog "jq path: $($jqCmd.Source)"
    } else {
        Write-Check "info" "jq: Not found `(optional, install for better output formatting`)"
        Write-VerboseLog "Install jq: winget install jqlang.jq"
    }

    # Check PowerShell version
    Write-Check "info" "PowerShell: $($PSVersionTable.PSVersion)"
    Write-VerboseLog "PowerShell Edition: $($PSVersionTable.PSEdition)"

    return $true
}

function Test-Authentication {
    Write-Section "2" "Authentication Diagnostics"

    # Check ANTHROPIC_AUTH_TOKEN
    $authToken = $env:ANTHROPIC_AUTH_TOKEN
    if (-not [string]::IsNullOrEmpty($authToken)) {
        $tokenPreview = $authToken.Substring(0, [Math]::Min(10, $authToken.Length)) + "..." +
                       $authToken.Substring([Math]::Max(0, $authToken.Length - 4))
        Write-Check "ok" "ANTHROPIC_AUTH_TOKEN: Set ($tokenPreview)"
        Write-VerboseLog "Token length: $($authToken.Length)"
    } else {
        Write-Check "error" "ANTHROPIC_AUTH_TOKEN: Not set `(required`)"
        Add-Recommendation "Set ANTHROPIC_AUTH_TOKEN: `$env:ANTHROPIC_AUTH_TOKEN='your-token-here'"
        Add-Recommendation "For persistence, set in System Environment Variables via System Properties"
    }

    # Check for incorrect ANTHROPIC_API_KEY
    if (-not [string]::IsNullOrEmpty($env:ANTHROPIC_API_KEY)) {
        Write-Check "warn" "ANTHROPIC_API_KEY: Detected `(should NOT be used with claude-code.club`)"
        Add-Recommendation "Remove ANTHROPIC_API_KEY from environment variables"

        if ($script:AutoFix) {
            try {
                [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
                [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "Process")
                Write-Check "ok" "Auto-fix: Removed ANTHROPIC_API_KEY from User environment"
            } catch {
                Write-Check "error" "Auto-fix failed: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Check "ok" "ANTHROPIC_API_KEY: Not set `(correct`)"
    }

    # Check ANTHROPIC_BASE_URL
    $baseUrl = $env:ANTHROPIC_BASE_URL
    if (-not [string]::IsNullOrEmpty($baseUrl)) {
        if ($baseUrl -eq $EXPECTED_BASE_URL) {
            Write-Check "ok" "ANTHROPIC_BASE_URL: Correctly set to $baseUrl"
        } else {
            Write-Check "warn" "ANTHROPIC_BASE_URL: Set to '$baseUrl' `(expected: $EXPECTED_BASE_URL`)"
            Add-Recommendation "Update ANTHROPIC_BASE_URL: `$env:ANTHROPIC_BASE_URL='$EXPECTED_BASE_URL'"
        }
    } else {
        Write-Check "info" "ANTHROPIC_BASE_URL: Not set `(optional, defaults to claude-code.club`)"
    }

    # Check for official Anthropic Console cache
    $consoleCacheLocations = @(
        "$env:APPDATA\Claude",
        "$env:LOCALAPPDATA\Claude",
        "$env:USERPROFILE\.anthropic"
    )

    foreach ($cacheDir in $consoleCacheLocations) {
        if (Test-Path $cacheDir) {
            Write-Check "warn" "Official Console cache detected: $cacheDir `(may cause conflicts`)"
            Write-VerboseLog "Directory exists: $cacheDir"
            Add-Recommendation "Consider backing up and removing: $cacheDir"
        }
    }
}

function Test-Network {
    Write-Section "3" "Network Diagnostics"

    $domain = "claude-code.club"

    # DNS Resolution
    Write-VerboseLog "Testing DNS resolution for $domain..."
    try {
        $dnsResult = Resolve-DnsName -Name $domain -ErrorAction Stop
        $ipAddress = $dnsResult | Where-Object { $_.Type -eq "A" } | Select-Object -First 1 -ExpandProperty IPAddress
        Write-Check "ok" "DNS Resolution: $domain → $ipAddress"
        Write-VerboseLog "DNS lookup successful"
    } catch {
        Write-Check "error" "DNS Resolution: Failed to resolve $domain"
        Add-Recommendation "Check DNS settings. Try: ipconfig /flushdns or check network adapter DNS settings"
        Add-Recommendation "Test with: Resolve-DnsName $domain"
    }

    # TLS/SSL Test
    Write-VerboseLog "Testing TLS handshake..."
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($domain, 443)
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false)
        $sslStream.AuthenticateAsClient($domain)

        Write-Check "ok" "TLS Handshake: Successful"
        Write-VerboseLog "Certificate verification passed"

        $sslStream.Close()
        $tcpClient.Close()
    } catch {
        Write-Check "error" "TLS Handshake: Failed - $($_.Exception.Message)"
        Add-Recommendation "Check firewall settings and ensure TLS 1.2+ is enabled"
        Add-Recommendation "Verify system date/time is correct `(certificate validation depends on it`)"
        Write-VerboseLog "Error details: $($_.Exception)"
    }

    # API Connectivity Test
    Write-VerboseLog "Testing API endpoint: $API_ENDPOINT"

    if (-not [string]::IsNullOrEmpty($env:ANTHROPIC_AUTH_TOKEN)) {
        try {
            $headers = @{
                "x-api-key" = $env:ANTHROPIC_AUTH_TOKEN
                "anthropic-version" = "2023-06-01"
            }

            if ($script:VerboseMode) {
                Write-Check "info" "Running verbose curl test..."
                $curlArgs = @(
                    "-v",
                    $API_ENDPOINT,
                    "--header", "x-api-key: $env:ANTHROPIC_AUTH_TOKEN",
                    "--header", "anthropic-version: 2023-06-01",
                    "--max-time", "10"
                )

                $curlOutput = & curl.exe $curlArgs 2>&1 | Out-String
                # Mask sensitive token in curl output for security
                $maskedOutput = $curlOutput -replace "(x-api-key:\s*)([^\s]{10})[^\s]*([^\s]{4})", '$1$2***$3'
                Write-Host "  --- Curl Output ---"
                Write-Host $maskedOutput
                Write-Host "  --- End Curl Output ---"

                # Extract HTTP code from verbose output
                $httpCode = if ($curlOutput -match "< HTTP/[\d.]+ (\d+)") { $matches[1] } else { "000" }
            } else {
                $curlArgs = @(
                    "-s",
                    "-w", "`n%{http_code}",
                    $API_ENDPOINT,
                    "--header", "x-api-key: $env:ANTHROPIC_AUTH_TOKEN",
                    "--header", "anthropic-version: 2023-06-01",
                    "--max-time", "10"
                )

                $curlOutput = & curl.exe $curlArgs 2>&1 | Out-String
                $httpCode = ($curlOutput -split "`n")[-1].Trim()
            }

            Write-VerboseLog "HTTP Status Code: $httpCode"

            switch ($httpCode) {
                "200" {
                    Write-Check "ok" "API Connection: Successful (HTTP $httpCode)"
                }
                "401" {
                    Write-Check "error" "API Connection: Authentication failed (HTTP 401)"
                    Add-Recommendation "Verify ANTHROPIC_AUTH_TOKEN is valid and not expired"
                }
                "403" {
                    Write-Check "error" "API Connection: Access forbidden (HTTP 403)"
                    Add-Recommendation "Check if your token has proper permissions"
                }
                "404" {
                    Write-Check "error" "API Connection: Endpoint not found (HTTP 404)"
                    Add-Recommendation "Verify API endpoint URL: $API_ENDPOINT"
                }
                default {
                    if ([string]::IsNullOrEmpty($httpCode) -or $httpCode -eq "000") {
                        Write-Check "error" "API Connection: Connection failed (timeout or network error)"
                        Add-Recommendation "Check network connectivity and firewall settings"

                        if ($curlOutput -match "Could not resolve host") {
                            Add-Recommendation "DNS resolution failed - check your DNS settings"
                        }
                        if ($curlOutput -match "Connection refused") {
                            Add-Recommendation "Connection refused - service may be down or blocked"
                        }
                        if ($curlOutput -match "SSL|certificate") {
                            Add-Recommendation "SSL/TLS error - check certificates and system time"
                        }
                    } else {
                        Write-Check "warn" "API Connection: Unexpected response (HTTP $httpCode)"
                        Write-VerboseLog "Response: $curlOutput"
                    }
                }
            }
        } catch {
            Write-Check "error" "API Connection: Failed - $($_.Exception.Message)"
            Add-Recommendation "Check network connectivity and firewall settings"
            Write-VerboseLog "Error details: $($_.Exception)"
        }
    } else {
        Write-Check "info" "API Connection: Skipped `(no ANTHROPIC_AUTH_TOKEN set`)"
    }
}

function Test-ProxyAndVpn {
    Write-Section "3.5" "Proxy & VPN Diagnostics"

    # Check proxy environment variables
    Write-Check "info" "Checking proxy environment variables..."
    $proxyVars = @("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY", "all_proxy", "ALL_PROXY", "no_proxy", "NO_PROXY")
    $proxyFound = $false
    $proxyValues = @()

    foreach ($var in $proxyVars) {
        $value = [Environment]::GetEnvironmentVariable($var, "Process")
        if (-not [string]::IsNullOrEmpty($value)) {
            $proxyFound = $true
            Write-Check "warn" "${var}: $value"
            $proxyValues += "$var=$value"
            Write-VerboseLog "Proxy variable detected: $var"

            # Check for conflicts
            if ($var -eq "http_proxy") {
                $upperValue = [Environment]::GetEnvironmentVariable("HTTP_PROXY", "Process")
                if (-not [string]::IsNullOrEmpty($upperValue) -and $value -ne $upperValue) {
                    Write-Check "warn" "Conflicting proxy settings: http_proxy != HTTP_PROXY"
                }
            }
        }
    }

    if (-not $proxyFound) {
        Write-Check "ok" "No proxy environment variables set"
    } else {
        # Check if claude-code.club is in no_proxy
        $noProxyValue = [Environment]::GetEnvironmentVariable("no_proxy", "Process") +
                       [Environment]::GetEnvironmentVariable("NO_PROXY", "Process")
        if ($noProxyValue -notmatch "claude-code\.club") {
            Write-Check "warn" "claude-code.club NOT in no_proxy list - proxy may block connection"
            Add-Recommendation "Add to no_proxy: `$env:no_proxy=`"`$env:no_proxy,claude-code.club,.claude-code.club`""
            Add-Recommendation "For persistence, add to System Environment Variables via System Properties"
        } else {
            Write-Check "ok" "claude-code.club is in no_proxy list"
        }
    }

    # Check system proxy settings (Windows)
    Write-VerboseLog "Checking Windows system proxy settings..."
    try {
        $proxySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction Stop

        if ($proxySettings.ProxyEnable -eq 1) {
            Write-Check "warn" "System Proxy Enabled: $($proxySettings.ProxyServer)"
            Write-VerboseLog "Windows system proxy is enabled"

            if (-not [string]::IsNullOrEmpty($proxySettings.ProxyOverride)) {
                Write-VerboseLog "Proxy bypass list: $($proxySettings.ProxyOverride)"
                if ($proxySettings.ProxyOverride -notmatch "claude-code\.club") {
                    Write-Check "warn" "claude-code.club NOT in proxy bypass list"
                    Add-Recommendation "Add claude-code.club to Internet Options > LAN Settings > Proxy > Bypass list"
                }
            }
        } else {
            Write-Check "ok" "System Proxy: Disabled"
        }
    } catch {
        Write-VerboseLog "Unable to check system proxy settings: $($_.Exception.Message)"
    }

    # Check WinHTTP proxy (used by curl)
    try {
        $winhttpProxy = netsh winhttp show proxy 2>&1 | Out-String
        if ($winhttpProxy -match "Direct access") {
            Write-Check "ok" "WinHTTP Proxy: Direct access `(no proxy`)"
        } elseif ($winhttpProxy -match "Proxy Server") {
            Write-Check "warn" "WinHTTP Proxy: Configured"
            Write-VerboseLog $winhttpProxy
        }
    } catch {
        Write-VerboseLog "Unable to check WinHTTP proxy"
    }

    # VPN Detection
    Write-Check "info" "Checking for active VPN connections..."
    $vpnDetected = $false
    $vpnAdapters = @()

    # Method 1: Check built-in VPN connections
    try {
        $vpnConnections = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq "Connected" }
        if ($vpnConnections) {
            $vpnDetected = $true
            foreach ($vpn in $vpnConnections) {
                Write-Check "warn" "VPN Connection: $($vpn.Name) `(Connected`)"
                Write-VerboseLog "VPN Server: $($vpn.ServerAddress)"
                $vpnAdapters += $vpn.Name
            }
        }
    } catch {
        Write-VerboseLog "Unable to check built-in VPN connections"
    }

    # Method 2: Check network adapters for VPN
    try {
        $suspectAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
            $_.InterfaceDescription -match "VPN|TAP|TUN|WireGuard|Cisco|Pulse|Palo Alto|AnyConnect|OpenVPN" -and
            $_.Status -eq "Up"
        }

        if ($suspectAdapters) {
            $vpnDetected = $true
            foreach ($adapter in $suspectAdapters) {
                Write-Check "warn" "VPN Adapter detected: $($adapter.Name) - $($adapter.InterfaceDescription)"
                Write-VerboseLog "Adapter Status: $($adapter.Status), Speed: $($adapter.LinkSpeed)"
                $vpnAdapters += $adapter.InterfaceAlias
            }
        }
    } catch {
        Write-VerboseLog "Unable to check network adapters"
    }

    # Method 3: Check for VPN processes
    try {
        $vpnProcesses = Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessName -match "vpnui|vpnagent|openvpn|wireguard|NordVPN|ExpressVPN|CiscoAnyConnect"
        }

        if ($vpnProcesses) {
            $vpnDetected = $true
            Write-VerboseLog "VPN processes detected:"

            # Identify specific VPN software
            foreach ($proc in $vpnProcesses) {
                if ($proc.ProcessName -match "cisco|vpn") {
                    Write-Check "warn" "Cisco AnyConnect VPN detected"
                    Write-VerboseLog "Process: $($proc.ProcessName) (PID: $($proc.Id))"
                    break
                } elseif ($proc.ProcessName -match "openvpn") {
                    Write-Check "warn" "OpenVPN detected"
                    Write-VerboseLog "Process: $($proc.ProcessName) (PID: $($proc.Id))"
                    break
                } elseif ($proc.ProcessName -match "wireguard") {
                    Write-Check "warn" "WireGuard VPN detected"
                    Write-VerboseLog "Process: $($proc.ProcessName) (PID: $($proc.Id))"
                    break
                } elseif ($proc.ProcessName -match "nord") {
                    Write-Check "warn" "NordVPN detected"
                    Write-VerboseLog "Process: $($proc.ProcessName) (PID: $($proc.Id))"
                    break
                } elseif ($proc.ProcessName -match "express") {
                    Write-Check "warn" "ExpressVPN detected"
                    Write-VerboseLog "Process: $($proc.ProcessName) (PID: $($proc.Id))"
                    break
                }
            }
        }
    } catch {
        Write-VerboseLog "Unable to check VPN processes"
    }

    if (-not $vpnDetected) {
        Write-Check "ok" "No active VPN detected"
    } else {
        Add-Recommendation "VPN detected - if experiencing connectivity issues, try disconnecting VPN temporarily"
        Add-Recommendation "If VPN is required, ensure claude-code.club is whitelisted/bypassed in VPN configuration"

        # Tunnel mode analysis
        Write-Check "info" "Analyzing VPN tunnel mode..."

        try {
            # Check for default route (0.0.0.0/0)
            $defaultRoutes = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
            Write-VerboseLog "Default routes found: $($defaultRoutes.Count)"

            $fullTunnel = $false
            foreach ($route in $defaultRoutes) {
                Write-VerboseLog "Default route via interface: $($route.InterfaceAlias), Metric: $($route.RouteMetric)"

                # Check if any default route goes through VPN adapter
                foreach ($vpnAdapter in $vpnAdapters) {
                    if ($route.InterfaceAlias -match $vpnAdapter) {
                        $fullTunnel = $true
                        Write-Check "warn" "FULL TUNNEL detected: Default route goes through $($route.InterfaceAlias)"
                        Write-VerboseLog "All traffic is routed through VPN interface"
                    }
                }
            }

            if ($fullTunnel) {
                Write-Check "warn" "All network traffic routes through VPN `(full tunnel mode`)"
                Add-Recommendation "Full tunnel VPN detected - all traffic goes through VPN, including claude-code.club"
                Add-Recommendation "If blocked, contact network admin to whitelist claude-code.club domain"
                Add-Recommendation "Consider requesting split tunnel mode if permitted by your organization"
            } else {
                Write-Check "info" "Split tunnel mode detected `(selective routing`)"

                # Check specific route to claude-code.club
                try {
                    $routeToApi = Find-NetRoute -RemoteIPAddress "claude-code.club" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($routeToApi) {
                        Write-VerboseLog "Route to claude-code.club via: $($routeToApi.InterfaceAlias)"

                        foreach ($vpnAdapter in $vpnAdapters) {
                            if ($routeToApi.InterfaceAlias -match $vpnAdapter) {
                                Write-Check "warn" "Route to claude-code.club goes through VPN ($($routeToApi.InterfaceAlias))"
                                Add-Recommendation "claude-code.club routes through VPN - may be blocked by corporate firewall"
                                Add-Recommendation "Add claude-code.club to VPN split tunnel bypass list"
                            }
                        }
                    }
                } catch {
                    Write-VerboseLog "Unable to determine route to claude-code.club: $($_.Exception.Message)"
                }
            }

            # Show routing table in verbose mode
            if ($script:VerboseMode) {
                Write-Host "  [VERBOSE] Routing table (default and VPN routes):"
                Get-NetRoute -ErrorAction SilentlyContinue |
                    Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" -or $_.InterfaceAlias -in $vpnAdapters } |
                    Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric |
                    Format-Table -AutoSize |
                    Out-String |
                    ForEach-Object { "    $_" }
            }
        } catch {
            Write-VerboseLog "Error analyzing tunnel mode: $($_.Exception.Message)"
        }
    }
}

function Test-Installation {
    Write-Section "5" "Installation Discovery"

    # Find Claude Code binary
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue

    if ($claudeCmd) {
        Write-Check "ok" "Claude Code: Found at $($claudeCmd.Source)"

        # Get version
        try {
            $version = & claude --version 2>&1
            Write-Check "info" "Version: $version"
            Write-VerboseLog "Binary path: $($claudeCmd.Source)"
        } catch {
            Write-Check "warn" "Unable to determine version"
        }

        # Detect installation method
        if ($claudeCmd.Source -match "npm") {
            Write-Check "info" "Installation method: npm"
        } else {
            Write-Check "info" "Installation method: Unknown `(manual or other`)"
        }

        # Verify PATH includes the directory
        $claudeDir = Split-Path -Parent $claudeCmd.Source
        Test-PathEnvironment -BinaryPath $claudeDir -BinaryName "claude"
    } else {
        Write-Check "error" "Claude Code: Not found in PATH"

        # Check common installation locations
        $commonLocations = @(
            "$env:APPDATA\npm",
            "$env:ProgramFiles\nodejs",
            "$env:LOCALAPPDATA\Programs\claude-code"
        )

        $foundLocations = @()
        foreach ($location in $commonLocations) {
            if (Test-Path "$location\claude.cmd") {
                $foundLocations += $location
                Write-Check "warn" "Claude Code found at: $location\claude.cmd `(NOT in PATH`)"
                Write-VerboseLog "Found installation outside PATH"
            }
        }

        if ($foundLocations.Count -gt 0) {
            Write-Check "error" "PATH environment variable does not include Claude Code directory"
            Add-Recommendation "The claude command was found but is not accessible because its directory is not in PATH"

            foreach ($location in $foundLocations) {
                Add-Recommendation "Add to PATH: `$env:Path += `";$location`""
                Add-Recommendation "For persistence: [Environment]::SetEnvironmentVariable`(`"Path`", `$env:Path, `"User`"`)"
                Add-Recommendation "Or add via System Properties > Environment Variables > Path > Edit > New > $location"
            }

            Add-Recommendation "After adding to PATH, restart PowerShell to apply changes"
        } else {
            Add-Recommendation "Install Claude Code: npm install -g @anthropic-ai/claude-code"
            Add-Recommendation "If already installed via npm, ensure npm global directory is in PATH"
        }
    }
}

function Test-PathEnvironment {
    param(
        [string]$BinaryPath,
        [string]$BinaryName
    )

    Write-VerboseLog "Checking if $BinaryPath is in PATH..."

    # Get current PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Process")

    # Check if binary path is in any PATH
    $inUserPath = $userPath -split ";" | Where-Object { $_ -eq $BinaryPath }
    $inSystemPath = $systemPath -split ";" | Where-Object { $_ -eq $BinaryPath }

    if ($inUserPath) {
        Write-Check "ok" "PATH: $BinaryPath is in User PATH"
        Write-VerboseLog "Found in User environment PATH"
    } elseif ($inSystemPath) {
        Write-Check "ok" "PATH: $BinaryPath is in System PATH"
        Write-VerboseLog "Found in System environment PATH"
    } else {
        Write-Check "warn" "PATH: $BinaryPath not found in environment PATH variables"
        Write-VerboseLog "Not found in User or System PATH"
        Add-Recommendation "PATH may not be persisted. Add $BinaryPath to User or System PATH for persistence"
        Add-Recommendation "Current session PATH: `$env:Path `(temporary, lost on restart`)"
        Add-Recommendation "For persistence: [Environment]::SetEnvironmentVariable`(`"Path`", `$env:Path + `";$BinaryPath`", `"User`"`)"
    }

    # Check if PATH is effective in current session
    if ($currentPath -split ";" | Where-Object { $_ -eq $BinaryPath }) {
        Write-Check "ok" "PATH `(Session`): $BinaryPath is accessible in current session"
    } else {
        Write-Check "warn" "PATH `(Session`): $BinaryPath not in current session PATH"
        Add-Recommendation "Reload environment: Restart PowerShell to apply PATH changes"
    }
}

function Test-Configuration {
    Write-Section "6" "Configuration Files"

    $configLocations = @(
        "$env:APPDATA\claude-code",
        "$env:LOCALAPPDATA\claude-code",
        "$env:USERPROFILE\.claude-code"
    )

    # Check config directories
    $configFound = $false
    foreach ($configDir in $configLocations) {
        if (Test-Path $configDir) {
            Write-Check "ok" "Config directory: $configDir"
            Write-VerboseLog "Contents: $(Get-ChildItem $configDir -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)"
            $configFound = $true
        }
    }

    if (-not $configFound) {
        Write-Check "info" "No Claude Code config directories found"
    }

    # Check environment variables via registry
    Write-Check "info" "Checking environment variables for Claude Code settings..."

    $envPaths = @(
        "HKCU:\Environment",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    )

    foreach ($path in $envPaths) {
        try {
            $envVars = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            $anthropicVars = $envVars.PSObject.Properties | Where-Object { $_.Name -like "ANTHROPIC*" }

            if ($anthropicVars) {
                Write-Check "ok" "Found ANTHROPIC variables in registry: $path"
                if ($script:VerboseMode) {
                    Write-Host "  Relevant variables:"
                    foreach ($var in $anthropicVars) {
                        # Mask sensitive token values for security
                        $displayValue = $var.Value
                        if ($var.Name -match "AUTH_TOKEN|API_KEY" -and $var.Value.Length -gt 14) {
                            $displayValue = $var.Value.Substring(0, 10) + "***" + $var.Value.Substring($var.Value.Length - 4)
                        }
                        Write-Host "    $($var.Name) = $displayValue"
                    }
                }
            }
        } catch {
            Write-VerboseLog "Unable to read registry path: $path"
        }
    }
}

# ============================================================================
# Report Generation
# ============================================================================

function Write-Report {
    Write-Header "Diagnostic Summary"

    Write-Host ""
    if ($script:IssuesFound.Count -eq 0) {
        Write-Host "[OK] No critical issues detected!"
    } else {
        Write-Host "Issues Found: $($script:IssuesFound.Count)"
        Write-Host ""
        foreach ($issue in $script:IssuesFound) {
            Write-Host "  * $issue"
        }
    }

    if ($script:Recommendations.Count -gt 0) {
        Write-Host ""
        Write-Header "Recommendations"
        Write-Host ""
        $counter = 1
        foreach ($rec in $script:Recommendations) {
            Write-Host "$counter. $rec"
            $counter++
        }
    }

    Write-Host ""
    Write-Header "Diagnostic Complete"
}

# ============================================================================
# Main Execution
# ============================================================================

function Show-Help {
    @"
Claude Code Diagnostic Tool

Usage: .\diagnose.ps1 [OPTIONS]

Diagnoses connectivity, authentication, and installation issues with Claude Code.

OPTIONS:
    -Verbose           Enable detailed logging output
    -Fix              Attempt to automatically fix common issues
    -Output FILE      Save diagnostic report to FILE
    -Help             Display this help message

EXAMPLES:
    .\diagnose.ps1                          # Run basic diagnostics
    .\diagnose.ps1 -Verbose                 # Run with detailed logging
    .\diagnose.ps1 -Output report.txt       # Save results to file
    .\diagnose.ps1 -Verbose -Fix            # Run with auto-fix and detailed logging

For more information, visit: https://github.com/anthropics/claude-code

"@
}

function Main {
    if ($Help) {
        Show-Help
        exit 0
    }

    # Setup output redirection if requested
    if (-not [string]::IsNullOrEmpty($Output)) {
        Start-Transcript -Path $Output -Force | Out-Null
    }

    try {
        # Run diagnostics
        Write-Header "Claude Code Diagnostic Tool"
        Write-Host "Target API: $API_SERVER"
        $dateFormat = "yyyy-MM-dd HH:mm:ss"
        Write-Host "Date: $(Get-Date -Format $dateFormat)"

        $envOk = Test-Environment
        if ($envOk) {
            Test-Authentication
            Test-Network
            Test-ProxyAndVpn
            Test-Installation
            Test-Configuration
            Write-Report
        } else {
            Write-Host ""
            Write-Host "Cannot proceed with diagnostics due to missing required tools."
            exit 1
        }

        # Exit code based on issues found
        if ($script:IssuesFound.Count -gt 0) {
            exit 1
        } else {
            exit 0
        }
    } finally {
        if (-not [string]::IsNullOrEmpty($Output)) {
            Stop-Transcript | Out-Null
            Write-Host ""
            Write-Host "Diagnostic report saved to: $Output"
        }
    }
}

# Entry point
Main
