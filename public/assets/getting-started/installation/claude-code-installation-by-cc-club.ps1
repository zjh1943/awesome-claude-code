# Claude Code Installation Script
# Usage: irm https://222.g99.ai/setup.ps1 | iex

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "   Claude Code Quick Setup         " -ForegroundColor White
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "[ERROR] PowerShell 3.0 or higher required" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Git Bash
Write-Host "[CHECK] Checking Git Bash..." -ForegroundColor Yellow
try {
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        $gitVersion = git --version 2>$null
        Write-Host "[OK] Git installed: $gitVersion" -ForegroundColor Green
        
        # Check if bash.exe exists
        $bashPath = Join-Path (Split-Path (Split-Path $gitPath.Source)) "bin\bash.exe"
        if (Test-Path $bashPath) {
            Write-Host "[OK] Git Bash found at: $bashPath" -ForegroundColor Green
            # Set environment variable for Claude Code
            [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $bashPath, "User")
        }
    } else {
        throw "Git not found"
    }
} catch {
    Write-Host "[WARNING] Git not installed" -ForegroundColor Yellow
    Write-Host "[INSTALL] Installing Git..." -ForegroundColor Cyan
    
    # Check if winget is available
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetInstalled) {
        Write-Host "[INFO] Installing Git via winget..." -ForegroundColor Yellow
        winget install Git.Git --accept-source-agreements --accept-package-agreements
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Set Git Bash path after installation
        $gitDefaultPath = "C:\Program Files\Git\bin\bash.exe"
        if (Test-Path $gitDefaultPath) {
            [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitDefaultPath, "User")
            Write-Host "[SUCCESS] Git installed and configured!" -ForegroundColor Green
        }
    } else {
        # Download and install Git manually
        Write-Host "[INFO] Downloading Git installer..." -ForegroundColor Yellow
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"
        $installerPath = "$env:TEMP\git-installer.exe"
        
        try {
            Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath
            Write-Host "[INFO] Installing Git..." -ForegroundColor Yellow
            Start-Process $installerPath -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS" -Wait
            Remove-Item $installerPath -Force
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Set Git Bash path
            $gitDefaultPath = "C:\Program Files\Git\bin\bash.exe"
            if (Test-Path $gitDefaultPath) {
                [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitDefaultPath, "User")
                Write-Host "[SUCCESS] Git installed and configured!" -ForegroundColor Green
            }
        } catch {
            Write-Host "[ERROR] Failed to install Git automatically" -ForegroundColor Red
            Write-Host "[INFO] Please install manually from: https://git-scm.com/downloads/win" -ForegroundColor Cyan
            Write-Host "[INFO] After installation, set CLAUDE_CODE_GIT_BASH_PATH environment variable" -ForegroundColor Yellow
        }
    }
}

# Check Node.js
Write-Host "[CHECK] Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "[OK] Node.js installed: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "[WARNING] Node.js not installed" -ForegroundColor Yellow
    Write-Host "[INSTALL] Installing Node.js..." -ForegroundColor Cyan

    $nodeInstalled = $false

    # Try winget installation first
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetInstalled) {
        Write-Host "[INFO] Attempting to install Node.js 22 via winget..." -ForegroundColor Yellow

        try {
            # Try to install Node.js directly (winget will pick the latest stable version)
            Write-Host "[INFO] Installing OpenJS.NodeJS..." -ForegroundColor Yellow
            $result = winget install --id OpenJS.NodeJS --accept-source-agreements --accept-package-agreements 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[SUCCESS] Node.js installed via winget" -ForegroundColor Green
                $nodeInstalled = $true
            } else {
                Write-Host "[WARNING] Primary winget installation failed, trying alternative..." -ForegroundColor Yellow

                # Try alternative package ID
                $result = winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[SUCCESS] Node.js LTS installed via winget" -ForegroundColor Green
                    $nodeInstalled = $true
                } else {
                    Write-Host "[WARNING] Winget installation failed, will try manual installation" -ForegroundColor Yellow
                }
            }

            if ($nodeInstalled) {
                # Refresh PATH after winget installation
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                Write-Host "[INFO] Waiting for PATH to refresh..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        } catch {
            Write-Host "[WARNING] Winget installation error: $_" -ForegroundColor Yellow
            Write-Host "[INFO] Falling back to manual installation..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] Winget not available, using manual installation..." -ForegroundColor Yellow
    }

    # If winget installation failed or not available, use manual installation
    if (-not $nodeInstalled) {
        Write-Host "[INFO] Downloading Node.js 22 installer..." -ForegroundColor Yellow
        $nodeUrl = "https://nodejs.org/dist/v22.13.1/node-v22.13.1-x64.msi"
        $installerPath = "$env:TEMP\nodejs-installer.msi"

        try {
            # Download with progress
            Write-Host "[INFO] Downloading from: $nodeUrl" -ForegroundColor Gray
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -TimeoutSec 300
            $ProgressPreference = 'Continue'

            if (-not (Test-Path $installerPath)) {
                throw "Download failed - installer file not found"
            }

            Write-Host "[SUCCESS] Download completed" -ForegroundColor Green
            Write-Host "[INFO] Installing Node.js (this may take a few minutes)..." -ForegroundColor Yellow

            # Run MSI installer with proper error handling
            $installProcess = Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart", "/l*v", "`"$env:TEMP\nodejs-install.log`"" -Wait -PassThru

            if ($installProcess.ExitCode -eq 0) {
                Write-Host "[SUCCESS] Node.js installed successfully" -ForegroundColor Green
                $nodeInstalled = $true
            } elseif ($installProcess.ExitCode -eq 1603) {
                Write-Host "[WARNING] Installation error 1603 - trying alternative method..." -ForegroundColor Yellow

                # Try alternative installation method with /passive flag
                $altProcess = Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/passive", "/norestart", "ADDLOCAL=ALL" -Wait -PassThru

                if ($altProcess.ExitCode -eq 0) {
                    Write-Host "[SUCCESS] Node.js installed with alternative method" -ForegroundColor Green
                    $nodeInstalled = $true
                } else {
                    Write-Host "[ERROR] Alternative installation also failed (Exit code: $($altProcess.ExitCode))" -ForegroundColor Red
                }
            } else {
                Write-Host "[ERROR] MSI installer returned error code: $($installProcess.ExitCode)" -ForegroundColor Red

                # Show log file content if exists
                $logPath = "$env:TEMP\nodejs-install.log"
                if (Test-Path $logPath) {
                    Write-Host "[INFO] Last 20 lines of installation log:" -ForegroundColor Yellow
                    Get-Content $logPath -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                }
            }

            # Clean up installer
            if (Test-Path $installerPath) {
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            }

            if ($nodeInstalled) {
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

                Write-Host "[INFO] Waiting for Node.js to be available..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
        } catch {
            Write-Host "[ERROR] Failed to install Node.js automatically: $_" -ForegroundColor Red
            Write-Host "[INFO] Please install manually from: https://nodejs.org/" -ForegroundColor Cyan

            # Try to open the installer manually if it exists
            if (Test-Path $installerPath) {
                Write-Host "[INFO] Opening installer for manual installation..." -ForegroundColor Yellow
                Start-Process $installerPath
                Write-Host "[INFO] Please complete the installation manually and run this script again" -ForegroundColor Cyan
            }

            Read-Host "Press Enter to exit"
            exit 1
        }
    }

    # Verify installation
    Write-Host "[VERIFY] Verifying Node.js installation..." -ForegroundColor Yellow
    $verifyAttempts = 0
    $maxAttempts = 3
    $nodeVerified = $false

    while ($verifyAttempts -lt $maxAttempts -and -not $nodeVerified) {
        $verifyAttempts++

        try {
            # Refresh PATH before each attempt
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            $nodeVersion = node --version 2>$null
            $npmVersion = npm --version 2>$null

            if ($nodeVersion -and $npmVersion) {
                Write-Host "[SUCCESS] Node.js installed: $nodeVersion" -ForegroundColor Green
                Write-Host "[SUCCESS] npm installed: $npmVersion" -ForegroundColor Green
                $nodeVerified = $true
            } else {
                if ($verifyAttempts -lt $maxAttempts) {
                    Write-Host "[INFO] Verification attempt $verifyAttempts failed, retrying..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
        } catch {
            if ($verifyAttempts -lt $maxAttempts) {
                Write-Host "[INFO] Verification attempt $verifyAttempts failed, retrying..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }

    if (-not $nodeVerified) {
        Write-Host "[ERROR] Node.js installation could not be verified" -ForegroundColor Red
        Write-Host "[INFO] Node.js may have been installed but is not yet available in PATH" -ForegroundColor Yellow
        Write-Host "[INFO] Please try the following:" -ForegroundColor Cyan
        Write-Host "  1. Close this PowerShell window" -ForegroundColor White
        Write-Host "  2. Open a new PowerShell window" -ForegroundColor White
        Write-Host "  3. Run 'node --version' to verify installation" -ForegroundColor White
        Write-Host "  4. If Node.js is installed, run this script again" -ForegroundColor White
        Write-Host "  5. If Node.js is not installed, download from: https://nodejs.org/" -ForegroundColor White
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Function to backup Claude CLI configuration files
function Backup-ClaudeConfigs {
    Write-Host "[BACKUP] Backing up Claude CLI configuration files..." -ForegroundColor Yellow
    
    # Create backup directory with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$env:USERPROFILE\.claude-backup-$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "[INFO] Backup directory: $backupDir" -ForegroundColor Gray
    
    $filesBackedUp = 0
    $backupSuccess = $true
    
    # Define configuration file paths to backup
    $configFiles = @(
        "$env:USERPROFILE\.claude\settings.json",
        "$env:USERPROFILE\.claude\claude.json",
        ".\.claude\settings.json",
        ".\.claude\settings.local.json", 
        ".\.claude\claude.json",
        ".\claude.json",
        ".\配置.json"
    )
    
    # Backup user-level configuration directory
    $userClaudeDir = "$env:USERPROFILE\.claude"
    if (Test-Path $userClaudeDir) {
        Write-Host "[INFO] Backing up user-level configuration directory..." -ForegroundColor Gray
        $userBackupDir = "$backupDir\user-claude-config"
        try {
            Copy-Item -Path $userClaudeDir -Destination $userBackupDir -Recurse -Force
            Write-Host "[SUCCESS] Backed up: $userClaudeDir -> $userBackupDir" -ForegroundColor Green
            $filesBackedUp++
        } catch {
            Write-Host "[WARNING] Failed to backup: $userClaudeDir" -ForegroundColor Yellow
        }
    }
    
    # Backup project-level configuration directory
    $projectClaudeDir = ".\.claude"
    if (Test-Path $projectClaudeDir) {
        Write-Host "[INFO] Backing up project-level configuration directory..." -ForegroundColor Gray
        $projectBackupDir = "$backupDir\project-claude-config"
        try {
            Copy-Item -Path $projectClaudeDir -Destination $projectBackupDir -Recurse -Force
            Write-Host "[SUCCESS] Backed up: $projectClaudeDir -> $projectBackupDir" -ForegroundColor Green
            $filesBackedUp++
        } catch {
            Write-Host "[WARNING] Failed to backup: $projectClaudeDir" -ForegroundColor Yellow
        }
    }
    
    # Backup individual configuration files
    foreach ($configFile in $configFiles) {
        if (Test-Path $configFile) {
            $fileName = Split-Path $configFile -Leaf
            $sourceDir = Split-Path $configFile -Parent
            
            # Determine backup subdirectory
            $backupSubDir = "$backupDir\configs"
            if ($sourceDir -like "*$env:USERPROFILE\.claude*") {
                $backupSubDir = "$backupDir\user-configs"
            } elseif ($sourceDir -like "*.claude*") {
                $backupSubDir = "$backupDir\project-configs"
            }
            
            # Create subdirectory if it doesn't exist
            if (-not (Test-Path $backupSubDir)) {
                New-Item -ItemType Directory -Path $backupSubDir -Force | Out-Null
            }
            
            try {
                Copy-Item -Path $configFile -Destination "$backupSubDir\$fileName" -Force
                Write-Host "[SUCCESS] Backed up: $configFile -> $backupSubDir\$fileName" -ForegroundColor Green
                $filesBackedUp++
            } catch {
                Write-Host "[WARNING] Failed to backup: $configFile" -ForegroundColor Yellow
                $backupSuccess = $false
            }
        }
    }
    
    # Create backup info file
    if ($filesBackedUp -gt 0) {
        Write-Host "[SUCCESS] Backup completed: $filesBackedUp files backed up to $backupDir" -ForegroundColor Green
        
        $backupInfo = @"
Claude CLI Configuration Backup
===============================
Backup Time: $(Get-Date)
Backup Reason: Claude CLI reinstallation preparation
Original Path: $(Get-Location)

Backup Contents:
- user-claude-config/: Contents of ~/.claude/ directory
- project-claude-config/: Contents of .claude/ directory
- user-configs/: Configuration files from ~/.claude/
- project-configs/: Configuration files from .claude/
- configs/: Configuration files from current directory

Recovery Instructions:
1. After reinstalling Claude CLI
2. Copy configuration files back to their original locations
3. Restart PowerShell or reload environment variables
"@
        
        Set-Content -Path "$backupDir\backup-info.txt" -Value $backupInfo -Encoding UTF8
        Write-Host "[INFO] Backup information saved to: $backupDir\backup-info.txt" -ForegroundColor Gray
        
        return $true
    } else {
        Write-Host "[INFO] No configuration files found to backup" -ForegroundColor Gray
        # Remove empty backup directory
        Remove-Item -Path $backupDir -Force -ErrorAction SilentlyContinue
        return $false
    }
}

# Check and clean old config files with backup
Write-Host "[CHECK] Checking for old configuration files..." -ForegroundColor Yellow

$claudeConfigFile = "$env:USERPROFILE\.claude.json"
$claudeDir = "$env:USERPROFILE\.claude"
$settingsFile = "$claudeDir\settings.json"

$foundOldFiles = $false
$filesToDelete = @()

if (Test-Path $claudeConfigFile) {
    $foundOldFiles = $true
    $filesToDelete += $claudeConfigFile
}

if (Test-Path $settingsFile) {
    $foundOldFiles = $true
    $filesToDelete += $settingsFile
}

if ($foundOldFiles) {
    Write-Host "[WARNING] Old configuration files detected, deletion recommended to avoid runtime errors" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Found the following configuration files:" -ForegroundColor White
    foreach ($file in $filesToDelete) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "[INFO] Keeping old configuration files may cause Claude Code runtime errors" -ForegroundColor Yellow
    
    Write-Host -NoNewline "Delete these old configuration files? [Y/n]: "
    Write-Host -NoNewline "Y" -ForegroundColor Green
    [Console]::SetCursorPosition([Console]::CursorLeft - 1, [Console]::CursorTop)
    $response = Read-Host
    
    # Default to Y if user just presses Enter
    if ([string]::IsNullOrWhiteSpace($response) -or $response -eq 'Y' -or $response -eq 'y') {
        # Backup configuration files before deletion
        Write-Host ""
        $backupResult = Backup-ClaudeConfigs
        
        if ($backupResult) {
            Write-Host "[INFO] Configuration files have been safely backed up" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "[DELETE] Removing old configuration files..." -ForegroundColor Yellow
        foreach ($file in $filesToDelete) {
            Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
            Write-Host "[SUCCESS] Deleted $file" -ForegroundColor Green
        }
        
        # Remove empty .claude directory
        if ((Test-Path $claudeDir) -and (Get-ChildItem $claudeDir -Force | Measure-Object).Count -eq 0) {
            Remove-Item -Path $claudeDir -Force
            Write-Host "[INFO] Removed empty directory $claudeDir" -ForegroundColor Gray
        }
        
        Write-Host "[SUCCESS] Old configuration files cleaned up" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Keeping old configuration files" -ForegroundColor Gray
    }
}

Write-Host ""

# Install Claude Code
Write-Host "[INSTALL] Installing Claude Code..." -ForegroundColor Yellow
try {
    # Use npm.cmd instead of npm to avoid PowerShell execution policy issues
    & cmd /c "npm install -g @anthropic-ai/claude-code 2>&1"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Claude Code installed!" -ForegroundColor Green
    } else {
        throw "npm install failed"
    }
    Write-Host ""
    
    # Configure API
    Write-Host ""
    Write-Host "[CONFIG] API Configuration" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan
    
    # Input API Token
    Write-Host "Enter your API Token:" -ForegroundColor White
    $apiToken = Read-Host
    while ([string]::IsNullOrWhiteSpace($apiToken)) {
        Write-Host "[ERROR] API Token cannot be empty!" -ForegroundColor Red
        Write-Host "Enter your API Token:" -ForegroundColor White
        $apiToken = Read-Host
    }
    
    # Set default API URL
    $apiUrl = "https://claude-code.club/api"
    
    # Set environment variables
    Write-Host ""
    Write-Host "[CONFIG] Saving configuration..." -ForegroundColor Yellow
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $apiToken, "User")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $apiUrl, "User")
    # [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiToken, "User")
    
    # Only set environment variables, don't create config files
    Write-Host "[SUCCESS] Environment variables configured!" -ForegroundColor Green
    
    # Set execution policy for Claude CLI
    Write-Host ""
    Write-Host "[CONFIG] Setting PowerShell execution policy..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "[SUCCESS] Execution policy configured!" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not set execution policy automatically" -ForegroundColor Yellow
        Write-Host "[INFO] You may need to run manually:" -ForegroundColor Cyan
        Write-Host "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "1. Close and reopen PowerShell" -ForegroundColor White
    Write-Host "2. Type 'claude -i' to start interactive mode" -ForegroundColor White
    Write-Host "   Or 'claude \"your question\"' for direct questions" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
} catch {
    Write-Host "[ERROR] Installation failed: $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}