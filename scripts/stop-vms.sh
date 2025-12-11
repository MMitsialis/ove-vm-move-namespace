#!/bin/bash
################################################################################
# Script Name: stop-vms.sh
# Description: Stop VMs for namespace move
# Process: Move OVE VMs between Namespaces
# Authors: Marc Mitsialis
# Version: 0.10.0
# Last Edit: 2025/12/11
# License: MIT License
# Development Assistance: Claude.AI (Anthropic)
#
# Changelog:
#   0.10.0 (2025/12/11) - Changed terminology from "migration" to "move"
#                       - Changed "Author" to "Authors" in metadata
#                       - Added Changelog section to header
#                       - Updated reference to move-functions.sh
#   0.9.0 (2024/12/10)  - Initial release
################################################################################


set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/move-functions.sh" ]; then
    source "$SCRIPT_DIR/move-functions.sh"
elif [ -f "move-functions.sh" ]; then
    source move-functions.sh
else
    echo "ERROR: move-functions.sh not found"
    exit 1
fi

echo "=== Stop VMs for Namespace Move ==="
echo ""

get_namespace_config || exit 1

VM_LIST="vm-migration-list-validated.txt"

if [ ! -f "$VM_LIST" ]; then
    echo "ERROR: $VM_LIST not found"
    echo "Run validate-migration-list.sh first"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  Source: $SOURCE_NS"
echo "  VM List: $VM_LIST"
echo "  Date: $(date +'%Y/%m/%d %H:%M')"
echo ""

mapfile -t VMS_TO_STOP < <(get_vm_list "$VM_LIST")

if [ ${#VMS_TO_STOP[@]} -eq 0 ]; then
    echo "ERROR: No VMs found in list"
    exit 1
fi

echo "VMs to stop:"
printf '  %s\n' "${VMS_TO_STOP[@]}"
echo ""

read -p "Proceed with stopping these VMs in '$SOURCE_NS'? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted"
    exit 0
fi

for vm in "${VMS_TO_STOP[@]}"; do
    echo "Stopping VM: $vm"
    
    RUNNING=$(oc get vm "$vm" -n $SOURCE_NS -o jsonpath='{.spec.running}')
    
    if [ "$RUNNING" = "true" ]; then
        virtctl stop "$vm" -n $SOURCE_NS
        echo "  Stop command sent"
    else
        echo "  Already stopped"
    fi
done

echo ""
echo "Waiting for all VMs to stop..."
sleep 10

echo ""
echo "Verification:"
for vm in "${VMS_TO_STOP[@]}"; do
    if oc get vmi "$vm" -n $SOURCE_NS &>/dev/null; then
        echo "⚠ $vm - VMI still exists (stopping in progress)"
    else
        echo "✓ $vm - Stopped"
    fi
done

echo ""
echo "VM stop operation complete"
echo "Verify all VMIs are gone before proceeding with PVC cloning"

################################################################################
# End of stop-vms.sh
################################################################################
