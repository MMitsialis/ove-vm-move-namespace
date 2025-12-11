#!/bin/bash
################################################################################
# Script Name: migration-functions.sh
# Description: Common functions library for OVE VM migration toolkit
# Process: Move OVE VMs between Namespaces
# Author: Marc Mitsialis
# Version: 0.9.0
# Last Edit: 2024/12/10
# License: MIT License
# Development Assistance: Claude.AI (Anthropic)
#
# Usage: source migration-functions.sh
#
# Purpose:
#   Provides reusable functions for namespace configuration management,
#   VM list parsing, and common utilities used across all migration scripts.
#
# References:
#   - OpenShift Virtualization: https://docs.openshift.com/container-platform/latest/virt/
#   - Bash Best Practices: https://google.github.io/styleguide/shellguide.html
################################################################################

# Function to load namespace configuration from file
# Returns: 0 if successful, 1 if file not found
load_namespace_config() {
    if [ -f "namespace-config.txt" ]; then
        source namespace-config.txt
        return 0
    fi
    return 1
}

# Function to prompt for and validate namespaces
# Sets: SOURCE_NS, TARGET_NS environment variables
# Returns: 0 if successful, 1 if validation fails
prompt_namespaces() {
    echo "Enter namespace configuration:"
    read -p "SOURCE namespace: " SOURCE_NS
    read -p "TARGET namespace: " TARGET_NS
    
    # Validate inputs
    if [ -z "$SOURCE_NS" ]; then
        echo "ERROR: Source namespace cannot be empty"
        return 1
    fi
    
    if [ -z "$TARGET_NS" ]; then
        echo "ERROR: Target namespace cannot be empty"
        return 1
    fi
    
    # Verify source namespace exists
    if ! oc get namespace "$SOURCE_NS" &>/dev/null; then
        echo "ERROR: Source namespace '$SOURCE_NS' does not exist"
        return 1
    fi
    
    # Export for current script
    export SOURCE_NS
    export TARGET_NS
    
    # Save config for future use
    cat > namespace-config.txt <<EOF
SOURCE_NS=$SOURCE_NS
TARGET_NS=$TARGET_NS
EOF
    
    return 0
}

# Function to get namespace configuration (load or prompt)
# Attempts to load saved config, prompts if not found or declined
# Returns: 0 if successful, 1 if user cancels or validation fails
get_namespace_config() {
    if load_namespace_config; then
        echo "Loaded configuration from namespace-config.txt"
        echo "  Source: $SOURCE_NS"
        echo "  Target: $TARGET_NS"
        echo ""
        read -p "Use this configuration? (yes/no): " use_config
        if [ "$use_config" = "yes" ]; then
            export SOURCE_NS
            export TARGET_NS
            return 0
        fi
    fi
    
    prompt_namespaces
    return $?
}

# Function to read and parse VM list file
# Filters out comments and empty lines
# Parameters:
#   $1 - Path to VM list file (default: vm-migration-list-validated.txt)
# Returns: Prints VM names one per line, returns 1 if file not found
get_vm_list() {
    local list_file="${1:-vm-migration-list-validated.txt}"
    
    if [ ! -f "$list_file" ]; then
        echo "ERROR: VM list file not found: $list_file" >&2
        return 1
    fi
    
    local vms=()
    while IFS= read -r vm || [ -n "$vm" ]; do
        # Skip comments and empty lines
        [[ "$vm" =~ ^#.*$ ]] && continue
        [[ -z "$vm" ]] && continue
        
        # Trim whitespace
        vm=$(echo "$vm" | xargs)
        vms+=("$vm")
    done < "$list_file"
    
    printf '%s\n' "${vms[@]}"
}

# Export functions for use in other scripts
export -f load_namespace_config
export -f prompt_namespaces
export -f get_namespace_config
export -f get_vm_list

################################################################################
# End of migration-functions.sh
################################################################################
