#!/bin/bash
################################################################################
# Script Name: recreate-vms.sh
# Description: Recreate VMs in target namespace
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

echo "=== Recreate VMs in Target Namespace ==="
get_namespace_config || exit 1

VM_LIST="vm-move-list-validated.txt"
[ ! -f "$VM_LIST" ] && echo "ERROR: $VM_LIST not found" && exit 1

read -p "Proceed with VM recreation? (yes/no): " confirm
[ "$confirm" != "yes" ] && echo "Aborted" && exit 0

mapfile -t VMS_TO_MIGRATE < <(get_vm_list "$VM_LIST")

mkdir -p target-vm-manifests
cd target-vm-manifests

for vm in "${VMS_TO_MIGRATE[@]}"; do
    echo "Processing VM: $vm"
    
    if oc get vm "$vm" -n $TARGET_NS &>/dev/null; then
        echo "  ⚠ VM already exists in target namespace"
        read -p "  Overwrite? (yes/no): " overwrite
        [ "$overwrite" != "yes" ] && echo "  Skipping" && continue
        oc delete vm "$vm" -n $TARGET_NS --wait=false
        sleep 2
    fi
    
    oc get vm "$vm" -n $SOURCE_NS -o yaml | \
        sed "s/namespace: $SOURCE_NS/namespace: $TARGET_NS/g" | \
        grep -v "creationTimestamp:\|resourceVersion:\|uid:\|generation:" | \
        sed '/^status:/,$ d' > "${vm}-target.yaml"
    
    echo "  Creating in $TARGET_NS..."
    oc apply -f "${vm}-target.yaml"
    
    [ $? -eq 0 ] && echo "  ✓ VM $vm created successfully" || echo "  ✗ Failed to create VM $vm"
done

echo "VM recreation complete"
