#!/bin/bash
set -e

# Configuration
REGION="cn-shenzhen"
INSTANCE_NAME="test-claude-installer-persistent" # Fixed name for easier finding
STATE_FILE=".aliyun_test_env"
PS_SCRIPT_ORIGINAL="public/assets/getting-started/installation/claude-code-installation-by-cc-club.ps1"
PS_SCRIPT_TEST="scripts/temp_test_installer.ps1"
LOG_FILE="scripts/test_run.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Usage Help
usage() {
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  run (default)  : Provision VM (if needed) and run the test."
    echo "  destroy        : Destroy the test VM and clean up."
    echo "  ssh            : (Optional) Attempt to SSH into the VM if configured."
    exit 1
}

CMD=${1:-run}

# Dependency Checks
check_deps() {
    for tool in aliyun jq gzip base64; do
        if ! command -v $tool &> /dev/null; then
            error "$tool not found. Please install it."
            exit 1
        fi
    done
}

# ----------------------------------------------------------------
# Resource Management
# ----------------------------------------------------------------

get_instance_id() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    fi
}

check_instance_status() {
    local iid=$1
    if [ -z "$iid" ]; then echo "Missing"; return; fi
    
    local status
    status=$(aliyun ecs DescribeInstanceStatus --RegionId $REGION --InstanceId $iid 2>/dev/null | jq -r '.InstanceStatuses.InstanceStatus[0].Status')
    
    if [ -z "$status" ] || [ "$status" == "null" ]; then
        echo "Missing"
    else
        echo "$status"
    fi
}

provision_resources() {
    local iid=$(get_instance_id)
    local status=$(check_instance_status "$iid")
    
    if [ "$status" == "Running" ]; then
        log "Using existing running instance: $iid"
        INSTANCE_ID=$iid
        return
    elif [ "$status" == "Stopped" ]; then
        log "Starting existing instance: $iid"
        aliyun ecs StartInstance --RegionId $REGION --InstanceId $iid
        INSTANCE_ID=$iid
    elif [ "$status" != "Missing" ]; then
        log "Instance $iid is in state $status. Waiting..."
        INSTANCE_ID=$iid
    else
        if [ ! -z "$iid" ]; then
            warn "Stored instance $iid not found or terminated. Creating new one..."
        fi
        create_new_instance
    fi
    
    wait_for_running "$INSTANCE_ID"
}

create_new_instance() {
    log "Resolving resources in $REGION..."
    
    # Image
    log "Finding Windows Server 2022 Image..."
    IMAGE_JSON=$(aliyun ecs DescribeImages --RegionId $REGION --ImageOwnerAlias system --ImageName "win2022*en-us*" --PageSize 10 2>/dev/null)
    IMAGE_ID=$(echo "$IMAGE_JSON" | jq -r '.Images.Image[0].ImageId')
    if [ -z "$IMAGE_ID" ] || [ "$IMAGE_ID" == "null" ]; then
        IMAGE_JSON=$(aliyun ecs DescribeImages --RegionId $REGION --ImageOwnerAlias system --ImageName "win2022*" --PageSize 10)
        IMAGE_ID=$(echo "$IMAGE_JSON" | jq -r '.Images.Image[0].ImageId')
    fi
    [ -z "$IMAGE_ID" ] && { error "Image not found"; exit 1; }
    
    # Network
    VPC_JSON=$(aliyun ecs DescribeVpcs --RegionId $REGION --PageSize 1)
    VPC_ID=$(echo "$VPC_JSON" | jq -r '.Vpcs.Vpc[0].VpcId')
    [ -z "$VPC_ID" ] && { error "VPC not found"; exit 1; }
    
    VSWITCH_JSON=$(aliyun ecs DescribeVSwitches --RegionId $REGION --VpcId $VPC_ID --PageSize 1)
    VSWITCH_ID=$(echo "$VSWITCH_JSON" | jq -r '.VSwitches.VSwitch[0].VSwitchId')
    [ -z "$VSWITCH_ID" ] && { error "VSwitch not found"; exit 1; }
    
    SG_JSON=$(aliyun ecs DescribeSecurityGroups --RegionId $REGION --VpcId $VPC_ID --PageSize 1)
    SG_ID=$(echo "$SG_JSON" | jq -r '.SecurityGroups.SecurityGroup[0].SecurityGroupId')
    [ -z "$SG_ID" ] && { error "Security Group not found"; exit 1; }

    # Launch
    PASSWORD="TestPassword123_$(date +%s)"
    log "Launching Spot Instance (ecs.e-c1m2.large)..."
    
    RUN_JSON=$(aliyun ecs RunInstances \
        --RegionId $REGION \
        --ImageId $IMAGE_ID \
        --InstanceType "ecs.e-c1m2.large" \
        --SecurityGroupId $SG_ID \
        --VSwitchId $VSWITCH_ID \
        --InstanceName $INSTANCE_NAME \
        --InstanceChargeType PostPaid \
        --SpotStrategy "SpotWithPriceLimit" \
        --SpotPriceLimit 0.5 \
        --InternetMaxBandwidthOut 1 \
        --SystemDisk.Category cloud_essd \
        --SystemDisk.Size 50 \
        --Password $PASSWORD)
        
    INSTANCE_ID=$(echo $RUN_JSON | jq -r '.InstanceIdSets.InstanceIdSet[0]')
    
    if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "null" ]; then
        error "Failed to create instance. Response: $RUN_JSON"
        exit 1
    fi
    
    log "Instance Created: $INSTANCE_ID"
    
    # Save initial state with password
    echo "{\"InstanceId\": \"$INSTANCE_ID\", \"Password\": \"$PASSWORD\"}" > "$STATE_FILE"
}

wait_for_running() {
    local iid=$1
    log "Waiting for instance $iid to be Running..."
    while true; do
        STATUS_JSON=$(aliyun ecs DescribeInstanceStatus --RegionId $REGION --InstanceId $iid)
        STATUS=$(echo $STATUS_JSON | jq -r '.InstanceStatuses.InstanceStatus[0].Status')
        if [ "$STATUS" == "Running" ]; then
            break
        fi
        echo -n "."
        sleep 5
    done
    echo ""
    log "Instance is running."

    # Enrich state file with Public IP
    IP_JSON=$(aliyun ecs DescribeInstances --RegionId $REGION --InstanceIds "[\"$iid\"]")
    PUBLIC_IP=$(echo $IP_JSON | jq -r '.Instances.Instance[0].PublicIpAddress.IpAddress[0]')
    
    # Read existing state to preserve password
    if [ -f "$STATE_FILE" ]; then
        EXISTING_STATE=$(cat "$STATE_FILE")
        # Merge IP into JSON
        echo "$EXISTING_STATE" | jq --arg ip "$PUBLIC_IP" '. + {PublicIp: $ip}' > "$STATE_FILE"
    fi
    
    log "Instance Info saved to $STATE_FILE (ID: $iid, IP: $PUBLIC_IP)"
    
    # Extra wait for fresh instances
    log "Ensuring Cloud Assistant is ready (Waiting 30s)..."
    sleep 30
}

destroy_resources() {
    local iid=$(get_instance_id)
    if [ -z "$iid" ]; then
        warn "No instance ID found in $STATE_FILE"
        return
    fi
    
    log "Destroying instance $iid..."
    aliyun ecs DeleteInstance --RegionId $REGION --InstanceId $iid --Force true
    rm "$STATE_FILE" 2>/dev/null
    log "Cleanup complete."
}

# ----------------------------------------------------------------
# Resource Management Helpers
# ----------------------------------------------------------------

get_instance_id() {
    if [ -f "$STATE_FILE" ]; then
        jq -r '.InstanceId // empty' "$STATE_FILE"
    fi
}

prepare_script() {
    log "Preparing PowerShell script..."
    cp "$PS_SCRIPT_ORIGINAL" "$PS_SCRIPT_TEST"
    
    # Mock inputs for automation
    sed -i.bak 's/Read-Host "Press Enter to exit"//g' "$PS_SCRIPT_TEST"
    sed -i.bak 's/$apiToken = Read-Host/$apiToken = "sk-test-dummy-token-for-automation"/' "$PS_SCRIPT_TEST"
    sed -i.bak 's/$response = Read-Host/$response = "Y"/' "$PS_SCRIPT_TEST"
    
    # Add Verification Logic
    cat <<EOF >> "$PS_SCRIPT_TEST"

Write-Host "--------------------------------------------------"
Write-Host "[TEST_VERIFICATION_START]"
\$envPath = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", "User")
if (\$envPath) {
    Write-Host "FOUND_ENV_VAR: \$envPath"
    if (Test-Path \$envPath) {
        Write-Host "TEST_RESULT: PASS"
    } else {
        Write-Host "TEST_RESULT: FAIL_PATH_NOT_EXIST"
    }
} else {
    Write-Host "TEST_RESULT: FAIL_VAR_NOT_SET"
}
Write-Host "[TEST_VERIFICATION_END]"
EOF
}

run_test() {
    local iid=$1
    log "Processing script payload..."
    
    # Compress
    gzip -c "$PS_SCRIPT_TEST" > "${PS_SCRIPT_TEST}.gz"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        GZIP_B64=$(base64 < "${PS_SCRIPT_TEST}.gz" | tr -d '\n')
    else
        GZIP_B64=$(base64 -w 0 < "${PS_SCRIPT_TEST}.gz")
    fi
    
    # Loader Script Construction (String Concatenation approach)
    # This avoids sed replacement issues with large strings or special chars
    
    # 1. Write Header
    echo "\$b64 = '$GZIP_B64'" > scripts/loader.ps1
    
    # 2. Append Logic (using single-quoted heredoc to prevent expansion)
    cat <<'EOF' >> scripts/loader.ps1
$bytes = [System.Convert]::FromBase64String($b64)
$ms = New-Object System.IO.MemoryStream(,$bytes)
$gs = New-Object System.IO.Compression.GzipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
$sr = New-Object System.IO.StreamReader($gs)
$cmd = $sr.ReadToEnd()
$sr.Close(); $gs.Close(); $ms.Close()
Invoke-Expression $cmd
EOF

    rm "${PS_SCRIPT_TEST}.gz" 2>/dev/null

    if [[ "$OSTYPE" == "darwin"* ]]; then
        LOADER_B64=$(base64 < scripts/loader.ps1 | tr -d '\n')
    else
        LOADER_B64=$(base64 -w 0 < scripts/loader.ps1)
    fi
    rm scripts/loader.ps1
    
    log "Sending command to $iid..."
    RUN_CMD_JSON=$(aliyun ecs RunCommand \
        --RegionId $REGION \
        --CommandContent "$LOADER_B64" \
        --Type "RunPowerShellScript" \
        --ContentEncoding "Base64" \
        --Timeout 600 \
        --InstanceId.1 $iid)
        
    COMMAND_ID=$(echo $RUN_CMD_JSON | jq -r '.CommandId')
    log "Command ID: $COMMAND_ID"
    
    log "Polling execution status..."
    while true; do
        sleep 5
        RESULT_JSON=$(aliyun ecs DescribeInvocationResults --RegionId $REGION --CommandId $COMMAND_ID --InstanceId $iid)
        STATUS=$(echo $RESULT_JSON | jq -r '.Invocation.InvocationResults.InvocationResult[0].InvocationStatus')
        
        if [ "$STATUS" == "Finished" ]; then
            log "Execution Finished."
            OUTPUT_B64=$(echo $RESULT_JSON | jq -r '.Invocation.InvocationResults.InvocationResult[0].Output')
            
            if [[ "$OSTYPE" == "darwin"* ]]; then
                OUTPUT=$(echo "$OUTPUT_B64" | base64 -D)
            else
                OUTPUT=$(echo "$OUTPUT_B64" | base64 -d)
            fi
            
            echo -e "\n=== OUTPUT START ==="
            echo "$OUTPUT"
            echo -e "=== OUTPUT END ===\n"
            
            if echo "$OUTPUT" | grep -q "TEST_RESULT: PASS"; then
                log "✅ TEST PASSED"
            else
                error "❌ TEST FAILED"
                exit 1
            fi
            break
        elif [ "$STATUS" == "Failed" ] || [ "$STATUS" == "Stopped" ] || [ "$STATUS" == "Error" ] || [ "$STATUS" == "Timeout" ]; then
             error "Script execution failed: $STATUS"
             
             OUTPUT_B64=$(echo $RESULT_JSON | jq -r '.Invocation.InvocationResults.InvocationResult[0].Output')
            
             if [[ "$OSTYPE" == "darwin"* ]]; then
                 OUTPUT=$(echo "$OUTPUT_B64" | base64 -D)
             else
                 OUTPUT=$(echo "$OUTPUT_B64" | base64 -d)
             fi
            
             echo -e "\n=== FAILURE OUTPUT START ==="
             echo "$OUTPUT"
             echo -e "=== FAILURE OUTPUT END ===\n"
             
             exit 1
        fi
        echo -n "."
    done
}

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------

check_deps

case "$CMD" in
    run)
        prepare_script
        provision_resources
        run_test "$INSTANCE_ID"
        log "Done. Instance $INSTANCE_ID is kept running for debugging."
        log "To clean up, run: $0 destroy"
        ;;
    destroy)
        destroy_resources
        ;;
    *)
        usage
        ;;
esac