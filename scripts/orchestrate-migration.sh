#!/bin/bash
################################################################################
# Script Name: orchestrate-migration.sh
# Description: Master migration orchestrator
# Process: Move OVE VMs between Namespaces
# Author: Marc Mitsialis
# Version: 0.9.0
# Last Edit: 2024/12/10
# License: MIT License
################################################################################

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source migration-functions.sh

echo "=== OpenShift VM Migration Orchestrator ==="
echo "Cluster: ros-sa-p-nl-ove-01"
echo ""

get_namespace_config || exit 1

echo ""
echo "Migration Configuration Loaded:"
echo "  Source: $SOURCE_NS"
echo "  Target: $TARGET_NS"

PS3="Select operation: "
options=(
    "1. Assess VMs"
    "2. Create VM list"
    "3. Validate VM list"
    "4. Stop VMs"
    "5. Clone PVCs"
    "6. Migrate resources"
    "7. Recreate VMs"
    "8. Start VMs"
    "9. Validate migration"
    "10. Cleanup source"
    "11. Run full migration"
    "12. Change namespaces"
    "Quit"
)

while true; do
    echo ""
    echo "Current: $SOURCE_NS → $TARGET_NS"
    select opt in "${options[@]}"; do
        case $opt in
            "1. Assess VMs") ./assess-vms.sh; break;;
            "2. Create VM list") ./create-migration-list.sh; break;;
            "3. Validate VM list") ./validate-migration-list.sh; break;;
            "4. Stop VMs") ./stop-vms.sh; break;;
            "5. Clone PVCs") ./clone-pvcs.sh; break;;
            "6. Migrate resources") ./migrate-resources.sh; break;;
            "7. Recreate VMs") ./recreate-vms.sh; break;;
            "8. Start VMs") ./start-and-verify-vms.sh; break;;
            "9. Validate migration") ./validate-migration.sh; break;;
            "10. Cleanup source") ./cleanup-source-vms.sh; break;;
            "11. Run full migration")
                echo "Running full migration..."
                ./stop-vms.sh && ./clone-pvcs.sh && ./migrate-resources.sh && ./recreate-vms.sh && ./start-and-verify-vms.sh
                break;;
            "12. Change namespaces") prompt_namespaces; break;;
            "Quit") echo "Exiting"; exit 0;;
            *) echo "Invalid option"; break;;
        esac
    done
    echo "Press Enter to continue..."
    read
done
