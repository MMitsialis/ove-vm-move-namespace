#!/bin/bash
################################################################################
# Script Name: cleanup-source-vms.sh
# Description: Remove moved VMs from source namespace
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

echo "=== CLEANUP WARNING ==="
get_namespace_config || exit 1

VM_LIST="vm-move-list-validated.txt"
[ ! -f "$VM_LIST" ] && echo "ERROR: $VM_LIST not found" && exit 1

echo ""
echo "This will DELETE the following VMs from '$SOURCE_NS':"
mapfile -t VMS_TO_CLEANUP < <(get_vm_list "$VM_LIST")
printf '  %s\n' "${VMS_TO_CLEANUP[@]}"

echo ""
echo "This action cannot be undone!"
read -p "Have you verified all VMs are working in '$TARGET_NS'? (yes/no): " verified
[ "$verified" != "yes" ] && echo "Aborted" && exit 0

read -p "Type 'DELETE' to confirm cleanup from '$SOURCE_NS': " confirm
[ "$confirm" != "DELETE" ] && echo "Aborted" && exit 0

echo "Proceeding with cleanup..."

for vm in "${VMS_TO_CLEANUP[@]}"; do
    echo "Removing VM: $vm from $SOURCE_NS"
    oc delete vm "$vm" -n $SOURCE_NS --wait=true
    
    PVCS=$(oc get pvc -n $SOURCE_NS -l kubevirt.io/vm=$vm -o name 2>/dev/null)
    for pvc in $PVCS; do
        oc delete $pvc -n $SOURCE_NS
    done
    
    echo "  ✓ $vm removed"
done

echo "Cleanup complete"
echo "Remaining VMs in $SOURCE_NS:"
oc get vms -n $SOURCE_NS
