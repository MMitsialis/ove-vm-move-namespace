#!/bin/bash
################################################################################
# Script Name: orchestrate-move.sh
# Description: Master namespace move orchestrator
# Process: Move OVE VMs between Namespaces
# Authors: Marc Mitsialis
# Version: 0.10.0
# Last Edit: 2025/12/11
# License: MIT License
#
# Changelog:
#   0.10.0 (2025/12/11) - Renamed from orchestrate-migration.sh to orchestrate-move.sh
#                       - Changed terminology from "migration" to "move"
#                       - Changed "Author" to "Authors" in metadata
#                       - Added Changelog section to header
#                       - Updated script references to renamed files
#   0.9.0 (2024/12/10)  - Initial release
################################################################################

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source move-functions.sh

echo "=== OpenShift VM Namespace Move Orchestrator ==="
echo "Cluster: ros-sa-p-nl-ove-01"
echo ""

get_namespace_config || exit 1

echo ""
echo "Namespace Move Configuration Loaded:"
echo "  Source: $SOURCE_NS"
echo "  Target: $TARGET_NS"

PS3="Select operation: "
options=(
    "1. Assess VMs"
    "2. Create VM list"
    "3. Validate VM list"
    "4. Stop VMs"
    "5. Clone PVCs"
    "6. Move resources"
    "7. Recreate VMs"
    "8. Start VMs"
    "9. Validate move"
    "10. Cleanup source"
    "11. Run full move"
    "12. Change namespaces"
    "Quit"
)

while true; do
    echo ""
    echo "Current: $SOURCE_NS → $TARGET_NS"
    select opt in "${options[@]}"; do
        case $opt in
            "1. Assess VMs") ./assess-vms.sh; break;;
            "2. Create VM list") ./create-move-list.sh; break;;
            "3. Validate VM list") ./validate-move-list.sh; break;;
            "4. Stop VMs") ./stop-vms.sh; break;;
            "5. Clone PVCs") ./clone-pvcs.sh; break;;
            "6. Move resources") ./move-resources.sh; break;;
            "7. Recreate VMs") ./recreate-vms.sh; break;;
            "8. Start VMs") ./start-and-verify-vms.sh; break;;
            "9. Validate move") ./validate-move.sh; break;;
            "10. Cleanup source") ./cleanup-source-vms.sh; break;;
            "11. Run full move")
                echo "Running full namespace move..."
                ./stop-vms.sh && ./clone-pvcs.sh && ./move-resources.sh && ./recreate-vms.sh && ./start-and-verify-vms.sh
                break;;
            "12. Change namespaces") prompt_namespaces; break;;
            "Quit") echo "Exiting"; exit 0;;
            *) echo "Invalid option"; break;;
        esac
    done
    echo "Press Enter to continue..."
    read
done
