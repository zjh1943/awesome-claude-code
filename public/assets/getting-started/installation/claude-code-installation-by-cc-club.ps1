# Claude Code 安装脚本
# 使用方法: irm https://academy.claude-code.club/assets/getting-started/installation/claude-code-installation-by-cc-club.ps1 | iex

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "   Claude Code 快速安装         " -ForegroundColor White
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 检查 PowerShell 版本
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "[错误] 需要 PowerShell 3.0 或更高版本" -ForegroundColor Red
    Read-Host "按 Enter 键退出"
    exit 1
}

# 检查 Git Bash
Write-Host "[检查] 正在检查 Git Bash..." -ForegroundColor Yellow
try {
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        $gitVersion = git --version 2>$null
        Write-Host "[成功] Git 已安装：$gitVersion" -ForegroundColor Green

        # 检查 bash.exe 是否存在
        $bashPath = Join-Path (Split-Path (Split-Path $gitPath.Source)) "bin\bash.exe"
        if (Test-Path $bashPath) {
            Write-Host "[成功] Git Bash 路径：$bashPath" -ForegroundColor Green
            # 为 Claude Code 设置环境变量
            [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $bashPath, "User")
        }
    } else {
        throw "Git not found"
    }
} catch {
    Write-Host "[警告] Git 未安装" -ForegroundColor Yellow
    Write-Host "[安装] 正在安装 Git..." -ForegroundColor Cyan
    
    # 检查 winget 是否可用
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetInstalled) {
        Write-Host "[信息] 通过 winget 安装 Git..." -ForegroundColor Yellow
        winget install Git.Git --accept-source-agreements --accept-package-agreements

        # 刷新 PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        # 安装后设置 Git Bash 路径
        $gitDefaultPath = "C:\Program Files\Git\bin\bash.exe"
        if (Test-Path $gitDefaultPath) {
            [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitDefaultPath, "User")
            Write-Host "[成功] Git 已安装并配置！" -ForegroundColor Green
        }
    } else {
        # 手动下载并安装 Git
        Write-Host "[信息] 正在下载 Git 安装程序..." -ForegroundColor Yellow
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"
        $installerPath = "$env:TEMP\git-installer.exe"
        
        try {
            Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath
            Write-Host "[信息] 正在安装 Git..." -ForegroundColor Yellow
            Start-Process $installerPath -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS" -Wait
            Remove-Item $installerPath -Force

            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            # 设置 Git Bash 路径
            $gitDefaultPath = "C:\Program Files\Git\bin\bash.exe"
            if (Test-Path $gitDefaultPath) {
                [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitDefaultPath, "User")
                Write-Host "[成功] Git 已安装并配置！" -ForegroundColor Green
            }
        } catch {
            Write-Host "[错误] 自动安装 Git 失败" -ForegroundColor Red
            Write-Host "[信息] 请手动从以下地址安装：https://git-scm.com/downloads/win" -ForegroundColor Cyan
            Write-Host "[信息] 安装后，设置 CLAUDE_CODE_GIT_BASH_PATH 环境变量" -ForegroundColor Yellow
        }
    }
}

# 检查 Node.js
Write-Host "[检查] 正在检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "[成功] Node.js 已安装：$nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "[警告] Node.js 未安装" -ForegroundColor Yellow
    Write-Host "[安装] 正在安装 Node.js..." -ForegroundColor Cyan

    $nodeInstalled = $false

    # 首先尝试 winget 安装
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetInstalled) {
        Write-Host "[信息] 尝试通过 winget 安装 Node.js 22..." -ForegroundColor Yellow

        try {
            # 尝试直接安装 Node.js（winget 会选择最新稳定版本）
            Write-Host "[信息] 正在安装 OpenJS.NodeJS..." -ForegroundColor Yellow
            $result = winget install --id OpenJS.NodeJS --accept-source-agreements --accept-package-agreements 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[成功] 通过 winget 安装 Node.js 成功" -ForegroundColor Green
                $nodeInstalled = $true
            } else {
                Write-Host "[警告] 主要安装方式失败，尝试备选方案..." -ForegroundColor Yellow

                # 尝试备选包 ID
                $result = winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[成功] 通过 winget 安装 Node.js LTS 成功" -ForegroundColor Green
                    $nodeInstalled = $true
                } else {
                    Write-Host "[警告] Winget 安装失败，将尝试手动安装" -ForegroundColor Yellow
                }
            }

            if ($nodeInstalled) {
                # winget 安装后刷新 PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                Write-Host "[信息] 等待 PATH 刷新..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        } catch {
            Write-Host "[警告] Winget 安装错误：$_" -ForegroundColor Yellow
            Write-Host "[信息] 回退到手动安装..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[信息] Winget 不可用，使用手动安装..." -ForegroundColor Yellow
    }

    # 如果 winget 安装失败或不可用，使用手动安装
    if (-not $nodeInstalled) {
        Write-Host "[信息] 正在下载 Node.js 22 安装程序..." -ForegroundColor Yellow
        $nodeUrl = "https://nodejs.org/dist/v22.13.1/node-v22.13.1-x64.msi"
        $installerPath = "$env:TEMP\nodejs-installer.msi"

        try {
            # 带进度下载
            Write-Host "[信息] 下载地址：$nodeUrl" -ForegroundColor Gray
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -TimeoutSec 300
            $ProgressPreference = 'Continue'

            if (-not (Test-Path $installerPath)) {
                throw "Download failed - installer file not found"
            }

            Write-Host "[成功] 下载完成" -ForegroundColor Green
            Write-Host "[信息] 正在安装 Node.js（可能需要几分钟）..." -ForegroundColor Yellow

            # 运行 MSI 安装程序并进行错误处理
            $installProcess = Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart", "/l*v", "`"$env:TEMP\nodejs-install.log`"" -Wait -PassThru

            if ($installProcess.ExitCode -eq 0) {
                Write-Host "[成功] Node.js 安装成功" -ForegroundColor Green
                $nodeInstalled = $true
            } elseif ($installProcess.ExitCode -eq 1603) {
                Write-Host "[警告] 安装错误 1603 - 尝试备选方案..." -ForegroundColor Yellow

                # 尝试使用 /passive 标志的备选安装方法
                $altProcess = Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/passive", "/norestart", "ADDLOCAL=ALL" -Wait -PassThru

                if ($altProcess.ExitCode -eq 0) {
                    Write-Host "[成功] 使用备选方法安装 Node.js 成功" -ForegroundColor Green
                    $nodeInstalled = $true
                } else {
                    Write-Host "[错误] 备选安装方法也失败了（退出代码：$($altProcess.ExitCode)）" -ForegroundColor Red
                }
            } else {
                Write-Host "[错误] MSI 安装程序返回错误代码：$($installProcess.ExitCode)" -ForegroundColor Red

                # 如果存在，显示日志文件内容
                $logPath = "$env:TEMP\nodejs-install.log"
                if (Test-Path $logPath) {
                    Write-Host "[信息] 安装日志最后 20 行：" -ForegroundColor Yellow
                    Get-Content $logPath -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                }
            }

            # 清理安装程序
            if (Test-Path $installerPath) {
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            }

            if ($nodeInstalled) {
                # 刷新 PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

                Write-Host "[信息] 等待 Node.js 可用..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
        } catch {
            Write-Host "[错误] 自动安装 Node.js 失败：$_" -ForegroundColor Red
            Write-Host "[信息] 请手动从以下地址安装：https://nodejs.org/" -ForegroundColor Cyan

            # 如果安装程序存在，尝试手动打开
            if (Test-Path $installerPath) {
                Write-Host "[信息] 正在打开安装程序以进行手动安装..." -ForegroundColor Yellow
                Start-Process $installerPath
                Write-Host "[信息] 请手动完成安装，然后再次运行此脚本" -ForegroundColor Cyan
            }

            Read-Host "按 Enter 键退出"
            exit 1
        }
    }

    # 验证安装
    Write-Host "[验证] 正在验证 Node.js 安装..." -ForegroundColor Yellow
    $verifyAttempts = 0
    $maxAttempts = 3
    $nodeVerified = $false

    while ($verifyAttempts -lt $maxAttempts -and -not $nodeVerified) {
        $verifyAttempts++

        try {
            # 每次尝试前刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            $nodeVersion = node --version 2>$null
            $npmVersion = npm --version 2>$null

            if ($nodeVersion -and $npmVersion) {
                Write-Host "[成功] Node.js 已安装：$nodeVersion" -ForegroundColor Green
                Write-Host "[成功] npm 已安装：$npmVersion" -ForegroundColor Green
                $nodeVerified = $true
            } else {
                if ($verifyAttempts -lt $maxAttempts) {
                    Write-Host "[信息] 验证尝试 $verifyAttempts 失败，重试中..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
        } catch {
            if ($verifyAttempts -lt $maxAttempts) {
                Write-Host "[信息] 验证尝试 $verifyAttempts 失败，重试中..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }

    if (-not $nodeVerified) {
        Write-Host "[错误] 无法验证 Node.js 安装" -ForegroundColor Red
        Write-Host "[信息] Node.js 可能已安装但尚未在 PATH 中生效" -ForegroundColor Yellow
        Write-Host "[信息] 请尝试以下操作：" -ForegroundColor Cyan
        Write-Host "  1. 关闭此 PowerShell 窗口" -ForegroundColor White
        Write-Host "  2. 打开新的 PowerShell 窗口" -ForegroundColor White
        Write-Host "  3. 运行 'node --version' 验证安装" -ForegroundColor White
        Write-Host "  4. 如果 Node.js 已安装，再次运行此脚本" -ForegroundColor White
        Write-Host "  5. 如果 Node.js 未安装，请从以下地址下载：https://nodejs.org/" -ForegroundColor White
        Read-Host "按 Enter 键退出"
        exit 1
    }
}

# 备份 Claude CLI 配置文件的函数
function Backup-ClaudeConfigs {
    Write-Host "[备份] 正在备份 Claude CLI 配置文件..." -ForegroundColor Yellow

    # 创建带时间戳的备份目录
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$env:USERPROFILE\.claude-backup-$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "[信息] 备份目录：$backupDir" -ForegroundColor Gray
    
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
    
    # 备份用户级配置目录
    $userClaudeDir = "$env:USERPROFILE\.claude"
    if (Test-Path $userClaudeDir) {
        Write-Host "[信息] 正在备份用户级配置目录..." -ForegroundColor Gray
        $userBackupDir = "$backupDir\user-claude-config"
        try {
            Copy-Item -Path $userClaudeDir -Destination $userBackupDir -Recurse -Force
            Write-Host "[成功] 已备份：$userClaudeDir -> $userBackupDir" -ForegroundColor Green
            $filesBackedUp++
        } catch {
            Write-Host "[警告] 备份失败：$userClaudeDir" -ForegroundColor Yellow
        }
    }

    # 备份项目级配置目录
    $projectClaudeDir = ".\.claude"
    if (Test-Path $projectClaudeDir) {
        Write-Host "[信息] 正在备份项目级配置目录..." -ForegroundColor Gray
        $projectBackupDir = "$backupDir\project-claude-config"
        try {
            Copy-Item -Path $projectClaudeDir -Destination $projectBackupDir -Recurse -Force
            Write-Host "[成功] 已备份：$projectClaudeDir -> $projectBackupDir" -ForegroundColor Green
            $filesBackedUp++
        } catch {
            Write-Host "[警告] 备份失败：$projectClaudeDir" -ForegroundColor Yellow
        }
    }
    
    # 备份单个配置文件
    foreach ($configFile in $configFiles) {
        if (Test-Path $configFile) {
            $fileName = Split-Path $configFile -Leaf
            $sourceDir = Split-Path $configFile -Parent

            # 确定备份子目录
            $backupSubDir = "$backupDir\configs"
            if ($sourceDir -like "*$env:USERPROFILE\.claude*") {
                $backupSubDir = "$backupDir\user-configs"
            } elseif ($sourceDir -like "*.claude*") {
                $backupSubDir = "$backupDir\project-configs"
            }

            # 如果子目录不存在，创建它
            if (-not (Test-Path $backupSubDir)) {
                New-Item -ItemType Directory -Path $backupSubDir -Force | Out-Null
            }

            try {
                Copy-Item -Path $configFile -Destination "$backupSubDir\$fileName" -Force
                Write-Host "[成功] 已备份：$configFile -> $backupSubDir\$fileName" -ForegroundColor Green
                $filesBackedUp++
            } catch {
                Write-Host "[警告] 备份失败：$configFile" -ForegroundColor Yellow
                $backupSuccess = $false
            }
        }
    }

    # 创建备份信息文件
    if ($filesBackedUp -gt 0) {
        Write-Host "[成功] 备份完成：已将 $filesBackedUp 个文件备份到 $backupDir" -ForegroundColor Green
        
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
        Write-Host "[信息] 备份信息已保存到：$backupDir\backup-info.txt" -ForegroundColor Gray

        return $true
    } else {
        Write-Host "[信息] 未找到需要备份的配置文件" -ForegroundColor Gray
        # 删除空的备份目录
        Remove-Item -Path $backupDir -Force -ErrorAction SilentlyContinue
        return $false
    }
}

# 检查并清理旧配置文件（带备份）
Write-Host "[检查] 正在检查旧配置文件..." -ForegroundColor Yellow

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
    Write-Host "[警告] 检测到旧配置文件，建议删除以避免运行错误" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "发现以下配置文件：" -ForegroundColor White
    foreach ($file in $filesToDelete) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "[信息] 保留旧配置文件可能导致 Claude Code 运行错误" -ForegroundColor Yellow

    Write-Host -NoNewline "删除这些旧配置文件？[Y/n]： "
    Write-Host -NoNewline "Y" -ForegroundColor Green
    [Console]::SetCursorPosition([Console]::CursorLeft - 1, [Console]::CursorTop)
    $response = Read-Host

    # 如果用户只按 Enter，默认为 Y
    if ([string]::IsNullOrWhiteSpace($response) -or $response -eq 'Y' -or $response -eq 'y') {
        # 删除前备份配置文件
        Write-Host ""
        $backupResult = Backup-ClaudeConfigs

        if ($backupResult) {
            Write-Host "[信息] 配置文件已安全备份" -ForegroundColor Cyan
        }

        Write-Host ""
        Write-Host "[删除] 正在删除旧配置文件..." -ForegroundColor Yellow
        foreach ($file in $filesToDelete) {
            Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
            Write-Host "[成功] 已删除 $file" -ForegroundColor Green
        }

        # 删除空的 .claude 目录
        if ((Test-Path $claudeDir) -and (Get-ChildItem $claudeDir -Force | Measure-Object).Count -eq 0) {
            Remove-Item -Path $claudeDir -Force
            Write-Host "[信息] 已删除空目录 $claudeDir" -ForegroundColor Gray
        }

        Write-Host "[成功] 旧配置文件已清理" -ForegroundColor Green
    } else {
        Write-Host "[信息] 保留旧配置文件" -ForegroundColor Gray
    }
}

Write-Host ""

# 安装 Claude Code
Write-Host "[安装] 正在安装 Claude Code..." -ForegroundColor Yellow
try {
    # 使用 npm.cmd 而不是 npm 以避免 PowerShell 执行策略问题
    & cmd /c "npm install -g @anthropic-ai/claude-code 2>&1"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[成功] Claude Code 已安装！" -ForegroundColor Green
    } else {
        throw "npm install failed"
    }
    Write-Host ""

    # 配置 API
    Write-Host ""
    Write-Host "[配置] API 配置" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan

    # 输入 API Token
    Write-Host "请输入您的 API Token：" -ForegroundColor White
    $apiToken = Read-Host
    while ([string]::IsNullOrWhiteSpace($apiToken)) {
        Write-Host "[错误] API Token 不能为空！" -ForegroundColor Red
        Write-Host "请输入您的 API Token：" -ForegroundColor White
        $apiToken = Read-Host
    }

    # 设置默认 API URL
    $apiUrl = "https://claude-code.club/api"

    # 设置环境变量
    Write-Host ""
    Write-Host "[配置] 正在保存配置..." -ForegroundColor Yellow
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $apiToken, "User")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $apiUrl, "User")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiToken, "User")

    # 仅设置环境变量，不创建配置文件
    Write-Host "[成功] 环境变量已配置！" -ForegroundColor Green

    # 设置 Claude CLI 的执行策略
    Write-Host ""
    Write-Host "[配置] 正在设置 PowerShell 执行策略..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "[成功] 执行策略已配置！" -ForegroundColor Green
    } catch {
        Write-Host "[警告] 无法自动设置执行策略" -ForegroundColor Yellow
        Write-Host "[信息] 您可能需要手动运行：" -ForegroundColor Cyan
        Write-Host "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "使用方法：" -ForegroundColor Cyan
    Write-Host "1. 关闭并重新打开 PowerShell" -ForegroundColor White
    Write-Host "2. 输入 'claude -i' 启动交互模式" -ForegroundColor White
    Write-Host "   或者 'claude \"你的问题\"' 直接提问" -ForegroundColor White
    Write-Host ""
    Read-Host "按 Enter 键退出"
} catch {
    Write-Host "[错误] 安装失败：$_" -ForegroundColor Red
    Write-Host ""
    Read-Host "按 Enter 键退出"
    exit 1
}