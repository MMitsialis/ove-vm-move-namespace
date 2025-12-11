#!/bin/bash
################################################################################
# Script Name: create-move-list.sh
# Description: Create VM namespace move list template
# Process: Move OVE VMs between Namespaces
# Authors: Marc Mitsialis
# Version: 0.10.0
# Last Edit: 2025/12/11
# License: MIT License
# Development Assistance: Claude.AI (Anthropic)
#
# Changelog:
#   0.10.0 (2025/12/11) - Renamed from create-migration-list.sh to create-move-list.sh
#                       - Changed terminology from "migration" to "move"
#                       - Changed "Author" to "Authors" in metadata
#                       - Added Changelog section to header
#   0.9.0 (2024/12/10)  - Initial release
################################################################################


echo "=== Create VM Namespace Move List ==="
echo ""

# Check for namespace config
if [ -f "namespace-config.txt" ]; then
    source namespace-config.txt
    echo "Loaded configuration:"
    echo "  Source: $SOURCE_NS"
    echo "  Target: $TARGET_NS"
    echo ""
else
    read -p "Enter SOURCE namespace: " SOURCE_NS
    read -p "Enter TARGET namespace: " TARGET_NS
    
    if [ -z "$SOURCE_NS" ] || [ -z "$TARGET_NS" ]; then
        echo "ERROR: Both namespaces are required"
        exit 1
    fi
    
    cat > namespace-config.txt <<EOF
SOURCE_NS=$SOURCE_NS
TARGET_NS=$TARGET_NS
EOF
fi

echo "Available VMs in $SOURCE_NS:"
oc get vms -n $SOURCE_NS -o custom-columns=NAME:.metadata.name,STATUS:.status.printableStatus --no-headers
echo ""

cat > vm-migration-list.txt <<EOF
# VMs to migrate from $SOURCE_NS to $TARGET_NS
# One VM name per line, comments start with #
# Generated: $(date +'%Y/%m/%d %H:%M')
#
# Example:
# web-server-01
# database-vm-03

EOF

echo "Template created: vm-migration-list.txt"
echo ""
echo "Edit this file and add one VM name per line"
echo "Then run validate-migration-list.sh to verify"
