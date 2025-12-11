#!/bin/bash
################################################################################
# Script Name: start-and-verify-vms.sh
# Description: Start and verify moved VMs
# Process: Move OVE VMs between Namespaces
# Authors: Marc Mitsialis
# Version: 0.10.0
# Last Edit: 2025/12/11
# License: MIT License
#
# Changelog:
#   0.10.0 (2025/12/11) - Changed terminology from "migration" to "move"
#                       - Changed "Author" to "Authors" in metadata
#                       - Added Changelog section to header
#                       - Updated reference to move-functions.sh
#                       - Updated reference to vm-move-list-validated.txt
#   0.9.0 (2024/12/10)  - Initial release
################################################################################

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/move-functions.sh" || source move-functions.sh

echo "=== Start Moved VMs ==="
get_namespace_config || exit 1

VM_LIST="vm-move-list-validated.txt"
[ ! -f "$VM_LIST" ] && echo "ERROR: $VM_LIST not found" && exit 1

mapfile -t VMS_TO_MIGRATE < <(get_vm_list "$VM_LIST")

echo "Pre-flight check:"
ALL_EXIST=true
for vm in "${VMS_TO_MIGRATE[@]}"; do
    if oc get vm "$vm" -n $TARGET_NS &>/dev/null; then
        echo "  ✓ $vm exists in $TARGET_NS"
    else
        echo "  ✗ $vm NOT FOUND in $TARGET_NS"
        ALL_EXIST=false
    fi
done

! $ALL_EXIST && echo "ERROR: Not all VMs exist in target namespace" && exit 1

read -p "Start all VMs in '$TARGET_NS'? (yes/no): " confirm
[ "$confirm" != "yes" ] && echo "Aborted" && exit 0

for vm in "${VMS_TO_MIGRATE[@]}"; do
    echo "Starting VM: $vm"
    virtctl start "$vm" -n $TARGET_NS
    sleep 5
done

echo "Monitoring VM startup..."
TIMEOUT=300
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    [ $ELAPSED -gt $TIMEOUT ] && echo "Timeout reached" && break
    
    ALL_RUNNING=true
    for vm in "${VMS_TO_MIGRATE[@]}"; do
        STATUS=$(oc get vm "$vm" -n $TARGET_NS -o jsonpath='{.status.printableStatus}' 2>/dev/null || echo "Unknown")
        READY=$(oc get vm "$vm" -n $TARGET_NS -o jsonpath='{.status.ready}' 2>/dev/null || echo "false")
        
        [ "$STATUS" != "Running" ] || [ "$READY" != "true" ] && ALL_RUNNING=false
    done
    
    $ALL_RUNNING && echo "✓ All VMs are Running and Ready" && break
    sleep 10
done

echo "Startup monitoring complete"
