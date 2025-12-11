#!/bin/bash
################################################################################
# Script Name: create-migration-list.sh
# Description: Create VM migration list template
# Process: Move OVE VMs between Namespaces
# Author: Marc Mitsialis
# Version: 0.9.0
# Last Edit: 2024/12/10
# License: MIT License
# Development Assistance: Claude.AI (Anthropic)
################################################################################


echo "=== Create VM Migration List ==="
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
