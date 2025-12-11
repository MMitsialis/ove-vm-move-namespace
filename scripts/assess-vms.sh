#!/bin/bash
################################################################################
# Script Name: assess-vms.sh
# Description: VM discovery and assessment for namespace move planning
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
#   0.9.0 (2024/12/10)  - Initial release
#
# Usage: ./assess-vms.sh
#
# Purpose:
#   Discovers all VMs in the source namespace and creates comprehensive
#   assessment report including storage, network, and dependency information.
#
# References:
#   - OpenShift Virtualization: https://docs.openshift.com/container-platform/latest/virt/
################################################################################

echo "=== VM Assessment Tool ==="
echo ""

# Prompt for namespaces
read -p "Enter SOURCE namespace: " SOURCE_NS
read -p "Enter TARGET namespace: " TARGET_NS

# Validate inputs
if [ -z "$SOURCE_NS" ]; then
    echo "ERROR: Source namespace cannot be empty"
    exit 1
fi

if [ -z "$TARGET_NS" ]; then
    echo "ERROR: Target namespace cannot be empty"
    exit 1
fi

# Verify source namespace exists
if ! oc get namespace "$SOURCE_NS" &>/dev/null; then
    echo "ERROR: Source namespace '$SOURCE_NS' does not exist"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  Source: $SOURCE_NS"
echo "  Target: $TARGET_NS"
echo ""
read -p "Proceed with assessment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted"
    exit 0
fi

ASSESSMENT_DIR="$HOME/vm-migration/${SOURCE_NS}-to-${TARGET_NS}-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$ASSESSMENT_DIR"
cd "$ASSESSMENT_DIR"

# Save namespace config for later scripts
cat > namespace-config.txt <<EOF
SOURCE_NS=$SOURCE_NS
TARGET_NS=$TARGET_NS
EOF

echo "=== VM Assessment Report ===" | tee assessment-report.txt
echo "Cluster: ros-sa-p-nl-ove-01" | tee -a assessment-report.txt
echo "Source Namespace: $SOURCE_NS" | tee -a assessment-report.txt
echo "Target Namespace: $TARGET_NS" | tee -a assessment-report.txt
echo "Assessment Date: $(date +'%Y/%m/%d %H:%M')" | tee -a assessment-report.txt
echo "" | tee -a assessment-report.txt

# Get list of all VMs
VMS=$(oc get vms -n $SOURCE_NS -o jsonpath='{.items[*].metadata.name}')

if [ -z "$VMS" ]; then
    echo "No VMs found in namespace: $SOURCE_NS" | tee -a assessment-report.txt
    exit 0
fi

for vm in $VMS; do
    echo "========================================" | tee -a assessment-report.txt
    echo "VM: $vm" | tee -a assessment-report.txt
    echo "========================================" | tee -a assessment-report.txt
    
    # Basic VM info
    echo "Status: $(oc get vm $vm -n $SOURCE_NS -o jsonpath='{.status.printableStatus}')" | tee -a assessment-report.txt
    echo "Running: $(oc get vm $vm -n $SOURCE_NS -o jsonpath='{.spec.running}')" | tee -a assessment-report.txt
    echo "Created: $(oc get vm $vm -n $SOURCE_NS -o jsonpath='{.status.created}')" | tee -a assessment-report.txt
    
    # Get IP if VMI exists
    if oc get vmi $vm -n $SOURCE_NS &>/dev/null; then
        IP=$(oc get vmi $vm -n $SOURCE_NS -o jsonpath='{.status.interfaces[0].ipAddress}')
        NODE=$(oc get vmi $vm -n $SOURCE_NS -o jsonpath='{.status.nodeName}')
        echo "IP Address: $IP" | tee -a assessment-report.txt
        echo "Current Node: $NODE" | tee -a assessment-report.txt
    fi
    
    # Storage information
    echo "" | tee -a assessment-report.txt
    echo "Storage Resources:" | tee -a assessment-report.txt
    oc get pvc -n $SOURCE_NS -l kubevirt.io/vm=$vm -o custom-columns=\
NAME:.metadata.name,\
STATUS:.status.phase,\
CAPACITY:.status.capacity.storage,\
STORAGECLASS:.spec.storageClassName,\
ACCESSMODE:.spec.accessModes[0] 2>/dev/null | tee -a assessment-report.txt || echo "None found" | tee -a assessment-report.txt
    
    # DataVolumes
    if oc get dv -n $SOURCE_NS -l kubevirt.io/vm=$vm &>/dev/null; then
        echo "" | tee -a assessment-report.txt
        echo "DataVolumes:" | tee -a assessment-report.txt
        oc get dv -n $SOURCE_NS -l kubevirt.io/vm=$vm -o name | tee -a assessment-report.txt
    fi
    
    # Network information
    echo "" | tee -a assessment-report.txt
    echo "Network Configuration:" | tee -a assessment-report.txt
    oc get vm $vm -n $SOURCE_NS -o jsonpath='{.spec.template.spec.networks[*].name}' | tee -a assessment-report.txt
    echo "" | tee -a assessment-report.txt
    
    # Check for Network Attachment Definitions
    NADS=$(oc get vm $vm -n $SOURCE_NS -o jsonpath='{.spec.template.spec.networks[?(@.multus)].multus.networkName}')
    if [ -n "$NADS" ]; then
        echo "Network Attachments: $NADS" | tee -a assessment-report.txt
    fi
    
    # Dependent ConfigMaps
    echo "" | tee -a assessment-report.txt
    echo "ConfigMaps:" | tee -a assessment-report.txt
    oc get cm -n $SOURCE_NS -o json | jq -r --arg vm "$vm" \
        '.items[] | select(.metadata.ownerReferences[]?.name == $vm or .metadata.labels["kubevirt.io/vm"] == $vm) | .metadata.name' \
        2>/dev/null | tee -a assessment-report.txt || echo "None found" | tee -a assessment-report.txt
    
    # Dependent Secrets
    echo "" | tee -a assessment-report.txt
    echo "Secrets:" | tee -a assessment-report.txt
    oc get secrets -n $SOURCE_NS -o json | jq -r --arg vm "$vm" \
        '.items[] | select(.metadata.ownerReferences[]?.name == $vm or .metadata.labels["kubevirt.io/vm"] == $vm) | .metadata.name' \
        2>/dev/null | tee -a assessment-report.txt || echo "None found" | tee -a assessment-report.txt
    
    # Services
    echo "" | tee -a assessment-report.txt
    echo "Services:" | tee -a assessment-report.txt
    oc get svc -n $SOURCE_NS -l kubevirt.io/vm=$vm -o name 2>/dev/null | tee -a assessment-report.txt || echo "None found" | tee -a assessment-report.txt
    
    # Export full VM definition
    echo "" | tee -a assessment-report.txt
    echo "Exporting VM definition to ${vm}-full.yaml" | tee -a assessment-report.txt
    oc get vm $vm -n $SOURCE_NS -o yaml > "${vm}-full.yaml"
    
    echo "" | tee -a assessment-report.txt
done

echo "" | tee -a assessment-report.txt
echo "Assessment complete. Review assessment-report.txt to identify VMs for migration." | tee -a assessment-report.txt
echo "Assessment files saved in: $ASSESSMENT_DIR"
echo ""
echo "Next steps:"
echo "  1. Review assessment-report.txt"
echo "  2. Create vm-migration-list.txt with VMs to migrate"
echo "  3. Run validate-migration-list.sh"

################################################################################
# End of assess-vms.sh
################################################################################
