#!/bin/bash
################################################################################
# Script Name: validate-migration.sh
# Description: Validate migration results
# Process: Move OVE VMs between Namespaces
# Author: Marc Mitsialis
# Version: 0.9.0
# Last Edit: 2024/12/10
# License: MIT License
################################################################################

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/migration-functions.sh" || source migration-functions.sh

echo "=== VM Migration Validation ==="
get_namespace_config || exit 1

VM_LIST="vm-migration-list-validated.txt"
REPORT_FILE="migration-validation-report-$(date +%Y%m%d-%H%M%S).txt"
[ ! -f "$VM_LIST" ] && echo "ERROR: $VM_LIST not found" && exit 1

exec > >(tee "$REPORT_FILE")
exec 2>&1

echo "=== VM Migration Validation Report ==="
echo "Source Namespace: $SOURCE_NS"
echo "Target Namespace: $TARGET_NS"
echo "Generated: $(date +'%Y/%m/%d %H:%M')"

mapfile -t VMS_MIGRATED < <(get_vm_list "$VM_LIST")

PASSED=0
FAILED=0

for vm in "${VMS_MIGRATED[@]}"; do
    echo "========================================="
    echo "VM: $vm"
    
    if oc get vm "$vm" -n $TARGET_NS &>/dev/null; then
        echo "✓ Exists in target namespace '$TARGET_NS'"
        ((PASSED++))
        
        TARGET_STATUS=$(oc get vm "$vm" -n $TARGET_NS -o jsonpath='{.status.printableStatus}')
        echo "  Target Status: $TARGET_STATUS"
        
        if oc get vmi "$vm" -n $TARGET_NS &>/dev/null; then
            IP=$(oc get vmi "$vm" -n $TARGET_NS -o jsonpath='{.status.interfaces[0].ipAddress}')
            echo "  IP Address: $IP"
        fi
    else
        echo "✗ NOT FOUND in target namespace '$TARGET_NS'"
        ((FAILED++))
    fi
done

echo "========================================="
echo "Summary"
echo "Total VMs: ${#VMS_MIGRATED[@]}"
echo "Successfully migrated: $PASSED"
echo "Failed: $FAILED"

[ $FAILED -eq 0 ] && echo "✓ All VMs migrated successfully" || echo "⚠ Some VMs failed"

echo "Full report saved to: $REPORT_FILE"
