#!/bin/bash
################################################################################
# Script Name: clone-pvcs.sh
# Description: Clone PVCs for VM migration
# Process: Move OVE VMs between Namespaces
# Author: Marc Mitsialis
# Version: 0.9.0
# Last Edit: 2024/12/10
# License: MIT License
################################################################################

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/migration-functions.sh" || source migration-functions.sh

echo "=== Clone PVCs for Selected VMs ==="
get_namespace_config || exit 1

VM_LIST="vm-migration-list-validated.txt"
[ ! -f "$VM_LIST" ] && echo "ERROR: $VM_LIST not found" && exit 1

read -p "Proceed with PVC cloning? (yes/no): " confirm
[ "$confirm" != "yes" ] && echo "Aborted" && exit 0

mapfile -t VMS_TO_MIGRATE < <(get_vm_list "$VM_LIST")

oc get namespace $TARGET_NS &>/dev/null || {
    echo "Creating target namespace: $TARGET_NS"
    oc create namespace $TARGET_NS
    oc label namespace $TARGET_NS openshift.io/cluster-monitoring="true" pod-security.kubernetes.io/enforce=privileged
}

for vm in "${VMS_TO_MIGRATE[@]}"; do
    echo "========================================"
    echo "Processing VM: $vm"
    PVCS=$(oc get pvc -n $SOURCE_NS -l kubevirt.io/vm=$vm -o jsonpath='{.items[*].metadata.name}')
    
    [ -z "$PVCS" ] && echo "⚠ No PVCs found for VM: $vm" && continue
    
    for pvc_name in $PVCS; do
        echo "Cloning PVC: $pvc_name"
        oc get pvc "$pvc_name" -n $TARGET_NS &>/dev/null && echo "  Already exists" && continue
        
        STORAGE_CLASS=$(oc get pvc $pvc_name -n $SOURCE_NS -o jsonpath='{.spec.storageClassName}')
        SIZE=$(oc get pvc $pvc_name -n $SOURCE_NS -o jsonpath='{.spec.resources.requests.storage}')
        ACCESS_MODE=$(oc get pvc $pvc_name -n $SOURCE_NS -o jsonpath='{.spec.accessModes[0]}')
        VOLUME_MODE=$(oc get pvc $pvc_name -n $SOURCE_NS -o jsonpath='{.spec.volumeMode}')
        
        cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $pvc_name
  namespace: $TARGET_NS
  labels:
    kubevirt.io/vm: $vm
spec:
  storageClassName: $STORAGE_CLASS
  accessModes:
    - $ACCESS_MODE
  volumeMode: ${VOLUME_MODE:-Filesystem}
  resources:
    requests:
      storage: $SIZE
  dataSource:
    kind: PersistentVolumeClaim
    name: $pvc_name
    namespace: $SOURCE_NS
EOF
        echo "  Clone request submitted"
    done
done

echo "Monitoring clone progress..."
while true; do
    ALL_BOUND=true
    for vm in "${VMS_TO_MIGRATE[@]}"; do
        if oc get pvc -n $TARGET_NS -l kubevirt.io/vm=$vm | grep -q "Pending\|Cloning"; then
            ALL_BOUND=false
        fi
    done
    $ALL_BOUND && break
    sleep 10
done
echo "✓ All PVCs are Bound"
