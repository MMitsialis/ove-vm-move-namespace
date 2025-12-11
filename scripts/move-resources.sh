#!/bin/bash
################################################################################
# Script Name: move-resources.sh
# Description: Move ConfigMaps, Secrets, Services between namespaces
# Process: Move OVE VMs between Namespaces
# Authors: Marc Mitsialis
# Version: 0.10.0
# Last Edit: 2025/12/11
# License: MIT License
#
# Changelog:
#   0.10.0 (2025/12/11) - Renamed from migrate-resources.sh to move-resources.sh
#                       - Changed terminology from "migration" to "move"
#                       - Changed "Author" to "Authors" in metadata
#                       - Added Changelog section to header
#                       - Updated reference to move-functions.sh
#                       - Updated reference to vm-move-list-validated.txt
#   0.9.0 (2024/12/10)  - Initial release
################################################################################

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/move-functions.sh" || source move-functions.sh

echo "=== Move Dependent Resources ==="
get_namespace_config || exit 1

VM_LIST="vm-move-list-validated.txt"
[ ! -f "$VM_LIST" ] && echo "ERROR: $VM_LIST not found" && exit 1

read -p "Proceed with resource move? (yes/no): " confirm
[ "$confirm" != "yes" ] && echo "Aborted" && exit 0

mapfile -t VMS_TO_MIGRATE < <(get_vm_list "$VM_LIST")

declare -A MIGRATED_CM MIGRATED_SECRETS MIGRATED_SVC

for vm in "${VMS_TO_MIGRATE[@]}"; do
    echo "========================================

"
    echo "VM: $vm"
    
    # ConfigMaps
    CMS=$(oc get cm -n $SOURCE_NS -o json | jq -r --arg vm "$vm" \
        '.items[] | select(.metadata.ownerReferences[]?.name == $vm or .metadata.labels["kubevirt.io/vm"] == $vm) | .metadata.name' 2>/dev/null)
    
    for cm_name in $CMS; do
        [ -z "${MIGRATED_CM[$cm_name]}" ] && {
            oc get cm $cm_name -n $SOURCE_NS -o yaml | \
                sed "s/namespace: $SOURCE_NS/namespace: $TARGET_NS/g" | \
                grep -v "creationTimestamp:\|resourceVersion:\|uid:" | \
                oc apply -f -
            MIGRATED_CM[$cm_name]=1
        }
    done
    
    # Secrets (excluding service account tokens)
    SECRETS=$(oc get secrets -n $SOURCE_NS -o json | jq -r --arg vm "$vm" \
        '.items[] | select(.type != "kubernetes.io/service-account-token") | select(.metadata.ownerReferences[]?.name == $vm or .metadata.labels["kubevirt.io/vm"] == $vm) | .metadata.name' 2>/dev/null)
    
    for secret_name in $SECRETS; do
        [ -z "${MIGRATED_SECRETS[$secret_name]}" ] && {
            oc get secret $secret_name -n $SOURCE_NS -o yaml | \
                sed "s/namespace: $SOURCE_NS/namespace: $TARGET_NS/g" | \
                grep -v "creationTimestamp:\|resourceVersion:\|uid:" | \
                oc apply -f -
            MIGRATED_SECRETS[$secret_name]=1
        }
    done
    
    # Services
    SVCS=$(oc get svc -n $SOURCE_NS -l kubevirt.io/vm=$vm -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    for svc_name in $SVCS; do
        [ -z "${MIGRATED_SVC[$svc_name]}" ] && {
            oc get svc $svc_name -n $SOURCE_NS -o yaml | \
                sed "s/namespace: $SOURCE_NS/namespace: $TARGET_NS/g" | \
                grep -v "clusterIP:\|clusterIPs:\|creationTimestamp:\|resourceVersion:\|uid:" | \
                oc apply -f -
            MIGRATED_SVC[$svc_name]=1
        }
    done
done

echo "Resource migration complete"
