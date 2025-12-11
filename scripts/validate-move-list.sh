#!/bin/bash
################################################################################
# Script Name: validate-move-list.sh
# Description: Validate VM namespace move list
# Process: Move OVE VMs between Namespaces
# Authors: Marc Mitsialis
# Version: 0.10.0
# Last Edit: 2025/12/11
# License: MIT License
# Development Assistance: Claude.AI (Anthropic)
#
# Changelog:
#   0.10.0 (2025/12/11) - Renamed from validate-migration-list.sh to validate-move-list.sh
#                       - Changed terminology from "migration" to "move"
#                       - Changed "Author" to "Authors" in metadata
#                       - Added Changelog section to header
#                       - Updated reference to move-functions.sh
#   0.9.0 (2024/12/10)  - Initial release
################################################################################


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/move-functions.sh" ]; then
    source "$SCRIPT_DIR/move-functions.sh"
elif [ -f "move-functions.sh" ]; then
    source move-functions.sh
else
    echo "ERROR: move-functions.sh not found"
    exit 1
fi

echo "=== Validate VM Namespace Move List ==="
echo ""

if [ -f "namespace-config.txt" ]; then
    source namespace-config.txt
else
    read -p "Enter SOURCE namespace: " SOURCE_NS
    read -p "Enter TARGET namespace: " TARGET_NS
    
    if [ -z "$SOURCE_NS" ] || [ -z "$TARGET_NS" ]; then
        echo "ERROR: Both namespaces are required"
        exit 1
    fi
fi

MIGRATION_LIST="vm-migration-list.txt"

if [ ! -f "$MIGRATION_LIST" ]; then
    echo "ERROR: $MIGRATION_LIST not found"
    echo "Run create-migration-list.sh first"
    exit 1
fi

if ! oc get namespace "$SOURCE_NS" &>/dev/null; then
    echo "ERROR: Source namespace '$SOURCE_NS' does not exist"
    exit 1
fi

echo "Configuration:"
echo "  Source: $SOURCE_NS"
echo "  Target: $TARGET_NS"
echo "  VM List: $MIGRATION_LIST"
echo ""

VALID_VMS=()
INVALID_VMS=()

while IFS= read -r vm || [ -n "$vm" ]; do
    [[ "$vm" =~ ^#.*$ ]] && continue
    [[ -z "$vm" ]] && continue
    
    vm=$(echo "$vm" | xargs)
    
    if oc get vm "$vm" -n $SOURCE_NS &>/dev/null; then
        echo "✓ $vm - EXISTS"
        VALID_VMS+=("$vm")
        
        STATUS=$(oc get vm "$vm" -n $SOURCE_NS -o jsonpath='{.status.printableStatus}')
        RUNNING=$(oc get vm "$vm" -n $SOURCE_NS -o jsonpath='{.spec.running}')
        echo "  Status: $STATUS, Running: $RUNNING"
    else
        echo "✗ $vm - NOT FOUND"
        INVALID_VMS+=("$vm")
    fi
done < "$MIGRATION_LIST"

echo ""
echo "Summary:"
echo "  Valid VMs: ${#VALID_VMS[@]}"
echo "  Invalid VMS: ${#INVALID_VMS[@]}"

if [ ${#INVALID_VMS[@]} -gt 0 ]; then
    echo ""
    echo "ERROR: The following VMs were not found in '$SOURCE_NS':"
    printf '  %s\n' "${INVALID_VMS[@]}"
    echo ""
    echo "Please correct vm-migration-list.txt before proceeding"
    exit 1
fi

if [ ${#VALID_VMS[@]} -eq 0 ]; then
    echo ""
    echo "ERROR: No valid VMs found in migration list"
    exit 1
fi

echo "${VALID_VMS[@]}" | tr ' ' '\n' > vm-migration-list-validated.txt
echo ""
echo "✓ All VMs validated successfully"
echo "Validated list saved to: vm-migration-list-validated.txt"
echo ""
echo "VMs ready for migration:"
printf '  %s\n' "${VALID_VMS[@]}"

################################################################################
# End of validate-migration-list.sh
################################################################################
