# Move OVE VMs between Namespaces - Usage Procedure

## Document Metadata

- **Process Name**: Move OVE VMs between Namespaces
- **Document Type**: Usage Procedure
- **Author**: Marc Mitsialis
- **Version**: 0.9.0
- **Last Edit**: 2024/12/10
- **License**: MIT License
- **Development Assistance**: Claude.AI (Anthropic)

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Detailed Procedure](#detailed-procedure)
5. [Troubleshooting](#troubleshooting)
6. [Post-Migration Tasks](#post-migration-tasks)
7. [Rollback Procedures](#rollback-procedures)

## Prerequisites

### System Requirements

- **OpenShift Cluster**: Version 4.10 or later
- **OpenShift Virtualization**: Installed and operational
- **Storage**: Dell PowerFlex CSI driver configured
- **Client Tools**:
  - `oc` CLI (version matching cluster)
  - `virtctl` CLI
  - `bash` 4.0 or later
  - `jq` for JSON parsing

### Permissions Required

You must have the following permissions:

**Source Namespace**:
- View and list VMs, VMIs, PVCs, DataVolumes
- Stop VMs (virtctl stop)
- Export resource definitions
- Delete resources (for cleanup phase only)

**Target Namespace**:
- Create PVCs, ConfigMaps, Secrets, Services
- Create and start VMs
- View and list resources

**Cluster Level**:
- View namespaces
- Create namespaces (if target doesn't exist)

### Pre-Migration Checklist

- [ ] Verify cluster connectivity: `oc whoami`
- [ ] Confirm virtctl installation: `virtctl version`
- [ ] Verify access to source namespace: `oc get vms -n <source-ns>`
- [ ] Check target namespace exists or can be created
- [ ] Confirm storage quota in target namespace
- [ ] Review VM dependencies (networks, storage classes)
- [ ] Schedule maintenance window for VM downtime
- [ ] Notify stakeholders of migration plan

## Installation

### Step 1: Extract the Toolkit

```bash
# Navigate to your working directory
cd ~/tools

# Extract the tarball
tar -xzf ove-vm-migration-toolkit-0.9.0.tar.gz

# Navigate into the toolkit directory
cd ove-vm-migration-toolkit

# Verify contents
ls -la
```

Expected contents:
```
ove-vm-migration-toolkit/
├── README.md                      # Overview and architecture
├── PROCEDURE.md                   # This file
├── CHANGELOG.md                   # Version history
├── LICENSE                        # MIT License text
├── VERSION                        # Version number
├── scripts/
│   ├── migration-functions.sh     # Common library
│   ├── assess-vms.sh             # Discovery
│   ├── create-migration-list.sh  # VM selection
│   ├── validate-migration-list.sh # Validation
│   ├── stop-vms.sh               # Stop VMs
│   ├── clone-pvcs.sh             # Clone storage
│   ├── migrate-resources.sh      # Migrate configs
│   ├── recreate-vms.sh           # Recreate VMs
│   ├── start-and-verify-vms.sh   # Start VMs
│   ├── validate-migration.sh     # Validation
│   ├── cleanup-source-vms.sh     # Cleanup
│   └── orchestrate-migration.sh  # Master script
└── examples/
    └── vm-migration-list-example.txt
```

### Step 2: Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### Step 3: Verify OpenShift Connection

```bash
# Check cluster connection
oc whoami
oc cluster-info

# List available namespaces
oc get namespaces
```

## Quick Start

For experienced users who want to run the full migration quickly:

```bash
# 1. Navigate to scripts directory
cd ove-vm-migration-toolkit/scripts

# 2. Run orchestrator
./orchestrate-migration.sh

# 3. When prompted, enter namespaces:
#    Source: aa-test
#    Target: bss-sa-a1-nl

# 4. Follow menu:
#    - Option 1: Assess VMs
#    - Option 2: Create migration list
#    - Edit vm-migration-list.txt
#    - Option 3: Validate list
#    - Option 11: Run full migration

# 5. After validation, run cleanup:
#    - Option 10: Cleanup source
```

## Detailed Procedure

### Phase 1: Assessment and Planning

#### Step 1: Run VM Assessment

```bash
cd ove-vm-migration-toolkit/scripts
./assess-vms.sh
```

**Prompts**:
```
Enter SOURCE namespace: aa-test
Enter TARGET namespace: bss-sa-a1-nl
```

**Output**:
- Creates assessment directory: `~/vm-migration/aa-test-to-bss-sa-a1-nl-YYYYMMDD-HHMMSS/`
- Generates `assessment-report.txt` with full VM inventory
- Exports individual VM YAML files

**Review the Assessment Report**:
```bash
cd ~/vm-migration/aa-test-to-bss-sa-a1-nl-*/
cat assessment-report.txt | less
```

Look for:
- VM names and current status
- Storage requirements (PVC sizes)
- Network attachments
- Dependent resources

#### Step 2: Create VM Migration List

```bash
# Still in ~/vm-migration/aa-test-to-bss-sa-a1-nl-*/
../ove-vm-migration-toolkit/scripts/create-migration-list.sh
```

This creates `vm-migration-list.txt` template.

**Edit the migration list**:
```bash
vi vm-migration-list.txt
```

Add VM names (one per line):
```
# VMs to migrate from aa-test to bss-sa-a1-nl
web-server-prod-01
database-prod-02
app-server-prod-03
```

**Best Practice**: Start with 1-2 non-critical VMs for your first migration.

#### Step 3: Validate Migration List

```bash
../ove-vm-migration-toolkit/scripts/validate-migration-list.sh
```

**Expected Output**:
```
✓ web-server-prod-01 - EXISTS
  Status: Running, Running: true
✓ database-prod-02 - EXISTS
  Status: Stopped, Running: false
✓ app-server-prod-03 - EXISTS
  Status: Running, Running: true

Summary:
  Valid VMs: 3
  Invalid VMs: 0

✓ All VMs validated successfully
```

This creates `vm-migration-list-validated.txt` for use in migration.

### Phase 2: Pre-Migration Preparation

#### Step 4: Stop VMs

**Important**: This causes downtime. Ensure stakeholders are notified.

```bash
../ove-vm-migration-toolkit/scripts/stop-vms.sh
```

**Prompts**:
```
Configuration:
  Source: aa-test
  VM List: vm-migration-list-validated.txt

VMs to stop:
  web-server-prod-01
  database-prod-02
  app-server-prod-03

Proceed with stopping these VMs in 'aa-test'? (yes/no): yes
```

**Verification**:
```bash
# Verify no VMIs are running
oc get vmis -n aa-test

# Should show: No resources found
```

**WHY**: VMs must be stopped to ensure filesystem consistency during PVC cloning. Running VMs have active I/O that could corrupt the clone.

### Phase 3: Storage Migration

#### Step 5: Clone PVCs

```bash
../ove-vm-migration-toolkit/scripts/clone-pvcs.sh
```

This script:
1. Creates target namespace if it doesn't exist
2. Identifies all PVCs for each VM
3. Creates PVC clones using CSI dataSource
4. Monitors cloning progress in real-time

**Progress Display**:
```
PVC Clone Status - 2024/12/10 14:30:45
Source: aa-test → Target: bss-sa-a1-nl
==========================================
VM: web-server-prod-01
NAME                  STATUS   CAPACITY   AGE
web-server-disk-0     Bound    50Gi       2m30s

VM: database-prod-02
NAME                  STATUS   CAPACITY   AGE
database-disk-0       Bound    100Gi      2m28s

✓ All PVCs are Bound
```

**Duration Estimate**: 
- Small VMs (< 50GB): 2-5 minutes
- Medium VMs (50-200GB): 5-15 minutes
- Large VMs (> 200GB): 15+ minutes

Press `Ctrl+C` to exit monitoring (cloning continues in background).

**Verify Cloning Completion**:
```bash
oc get pvc -n bss-sa-a1-nl
```

All PVCs should show `STATUS: Bound`.

### Phase 4: Resource Migration

#### Step 6: Migrate Dependent Resources

```bash
../ove-vm-migration-toolkit/scripts/migrate-resources.sh
```

This migrates:
- ConfigMaps (cloud-init, application config)
- Secrets (credentials, certificates)
- Services (network endpoints)

**Output Example**:
```
========================================
VM: web-server-prod-01
========================================
ConfigMaps:
  Migrating: web-config-cm
    configmap/web-config-cm created
Secrets:
  Migrating: web-tls-secret
    secret/web-tls-secret created
Services:
  Migrating: web-service
    service/web-service created
```

**WHY**: VMs depend on these resources for configuration and network access. They must exist before VM creation.

#### Step 7: Recreate VMs in Target Namespace

```bash
../ove-vm-migration-toolkit/scripts/recreate-vms.sh
```

This:
1. Exports VM definitions from source
2. Modifies namespace references
3. Removes cluster-specific metadata
4. Creates VMs in target namespace

**Output**:
```
Processing VM: web-server-prod-01
  Creating in bss-sa-a1-nl...
  ✓ VM web-server-prod-01 created successfully
```

**Verify**:
```bash
oc get vms -n bss-sa-a1-nl
```

VMs should exist but not be running yet.

### Phase 5: Startup and Verification

#### Step 8: Start VMs

```bash
../ove-vm-migration-toolkit/scripts/start-and-verify-vms.sh
```

**Confirmation Prompt**:
```
Pre-flight check:
  ✓ web-server-prod-01 exists in bss-sa-a1-nl
  ✓ database-prod-02 exists in bss-sa-a1-nl
  ✓ app-server-prod-03 exists in bss-sa-a1-nl

Start all VMs in 'bss-sa-a1-nl'? (yes/no): yes
```

**Real-time Monitoring**:
```
VM Status - 2024/12/10 14:45:23
Target Namespace: bss-sa-a1-nl
Elapsed: 45s / 300s
===========================================

VM: web-server-prod-01
  Status: Running
  Ready: true
  IP: 10.128.2.45
  Node: worker-01
  Phase: Running

VM: database-prod-02
  Status: Starting
  Ready: false
  IP: Pending
  Node: worker-02
  Phase: Scheduled
```

Wait until all VMs show:
- Status: Running
- Ready: true
- IP: Assigned

#### Step 9: Generate Validation Report

```bash
../ove-vm-migration-toolkit/scripts/validate-migration.sh
```

**Report Contents**:
```
=== VM Migration Validation Report ===
Source Namespace: aa-test
Target Namespace: bss-sa-a1-nl
Generated: 2024/12/10 14:50:15

VM: web-server-prod-01
✓ Exists in target namespace 'bss-sa-a1-nl'
  Target Status: Running
  Ready: true
  IP Address: 10.128.2.45
  Node: worker-01
  VMI Phase: Running
  ✓ VMI is running

  Storage:
    web-server-disk-0    Bound    50Gi
    ✓ All PVCs are Bound

Summary:
Total VMs in scope: 3
Successfully migrated: 3
Failed: 0

✓ All VMs migrated successfully
```

**Save this report** for audit purposes.

### Phase 6: Application Validation

#### Step 10: Test VM Connectivity

```bash
# Get VM IP addresses
oc get vmi -n bss-sa-a1-nl -o custom-columns=\
NAME:.metadata.name,\
IP:.status.interfaces[0].ipAddress,\
NODE:.status.nodeName

# Test ping connectivity
ping -c 3 10.128.2.45

# Test SSH access (if configured)
ssh admin@10.128.2.45

# Test application endpoints
curl http://10.128.2.45:80
```

#### Step 11: Verify Application Functionality

**Checklist**:
- [ ] VMs respond to ping
- [ ] SSH/RDP access works
- [ ] Applications are running
- [ ] Database connections work
- [ ] Network shares are mounted
- [ ] Application logs show no errors
- [ ] Monitoring systems detect VMs
- [ ] Backup jobs are configured

**Wait Period**: Keep both source and target VMs for 24-48 hours before cleanup.

### Phase 7: Cleanup

#### Step 12: Remove VMs from Source Namespace

**WARNING**: This is destructive and cannot be undone.

```bash
../ove-vm-migration-toolkit/scripts/cleanup-source-vms.sh
```

**Prompts**:
```
This will DELETE the following VMs from 'aa-test':
  web-server-prod-01
  database-prod-02
  app-server-prod-03

This action cannot be undone!

Have you verified all VMs are working in 'bss-sa-a1-nl'? (yes/no): yes
Type 'DELETE' to confirm cleanup from 'aa-test': DELETE
```

**What Gets Deleted**:
- VM definitions
- Associated PVCs
- DataVolumes (if any)

**What Is Preserved**:
- VMs in target namespace
- Other VMs in source namespace
- ConfigMaps and Secrets (shared resources)

**Verify Cleanup**:
```bash
# Check source namespace
oc get vms -n aa-test

# Verify target namespace unchanged
oc get vms -n bss-sa-a1-nl
```

## Troubleshooting

### Issue: PVC Stuck in "Pending"

**Symptoms**:
```
NAME              STATUS    VOLUME   CAPACITY
vm-disk-0         Pending
```

**Diagnosis**:
```bash
oc describe pvc vm-disk-0 -n bss-sa-a1-nl
oc get events -n bss-sa-a1-nl --sort-by='.lastTimestamp'
```

**Common Causes**:
1. Insufficient storage quota
2. Storage class not available in target namespace
3. PowerFlex CSI driver issues

**Resolution**:
```bash
# Check storage quota
oc get resourcequota -n bss-sa-a1-nl

# Verify storage class exists
oc get storageclass

# Check CSI driver pods
oc get pods -n vxflexos

# Delete and recreate PVC if needed
oc delete pvc vm-disk-0 -n bss-sa-a1-nl
# Then rerun clone-pvcs.sh
```

### Issue: VM Won't Start

**Symptoms**:
```
VM Status: Starting (stuck)
Ready: false
```

**Diagnosis**:
```bash
# Check VM details
oc describe vm <vm-name> -n bss-sa-a1-nl

# Check VMI (if created)
oc describe vmi <vm-name> -n bss-sa-a1-nl

# Check virt-launcher logs
oc logs -n bss-sa-a1-nl -l kubevirt.io/vm=<vm-name>
```

**Common Causes**:
1. PVC not bound
2. Missing ConfigMaps/Secrets
3. Network attachment issues
4. Node resource constraints

**Resolution**:
```bash
# Verify all PVCs are bound
oc get pvc -n bss-sa-a1-nl -l kubevirt.io/vm=<vm-name>

# Check for missing ConfigMaps
oc get cm -n bss-sa-a1-nl

# Restart VM
virtctl stop <vm-name> -n bss-sa-a1-nl
sleep 10
virtctl start <vm-name> -n bss-sa-a1-nl
```

### Issue: VM Has No IP Address

**Symptoms**:
```
VM Status: Running
IP: <none> or empty
```

**Diagnosis**:
```bash
# Check VMI network status
oc get vmi <vm-name> -n bss-sa-a1-nl -o jsonpath='{.status.interfaces}'

# Check guest agent
virtctl guestosinfo <vm-name> -n bss-sa-a1-nl
```

**Common Causes**:
1. Guest agent not running
2. DHCP not configured
3. Network attachment issues
4. VM needs more time to boot

**Resolution**:
```bash
# Wait longer (some VMs take 2-5 minutes)
watch oc get vmi <vm-name> -n bss-sa-a1-nl

# Check VM console
virtctl console <vm-name> -n bss-sa-a1-nl

# Restart VM if necessary
virtctl restart <vm-name> -n bss-sa-a1-nl
```

### Issue: "Namespace Not Found"

**Symptoms**:
```
Error from server (NotFound): namespaces "bss-sa-a1-nl" not found
```

**Resolution**:
```bash
# Create target namespace
oc create namespace bss-sa-a1-nl

# Add required labels
oc label namespace bss-sa-a1-nl \
  openshift.io/cluster-monitoring="true" \
  pod-security.kubernetes.io/enforce=privileged

# Then rerun clone-pvcs.sh
```

### Issue: Permission Denied

**Symptoms**:
```
Error: User "username" cannot create VMs in namespace "bss-sa-a1-nl"
```

**Resolution**:
```bash
# Check your permissions
oc auth can-i create vms -n bss-sa-a1-nl

# Request admin to grant permissions
# Admin runs:
oc adm policy add-role-to-user admin <username> -n bss-sa-a1-nl
```

## Post-Migration Tasks

### Update External Systems

1. **DNS Records**
   - Update DNS entries with new IP addresses
   - Update CNAME records if namespace affects DNS

2. **Load Balancers**
   - Update backend pools with new VM IPs
   - Test load balancer health checks

3. **Monitoring Systems**
   - Update monitoring configs for new namespace
   - Verify alerts are working
   - Update dashboards

4. **Backup Systems**
   - Configure backups for target namespace
   - Test backup and restore procedures
   - Disable backups in source namespace after cleanup

5. **Documentation**
   - Update runbooks with new namespace
   - Update architecture diagrams
   - Document migration date and details

### Verify Resource Cleanup

```bash
# Verify no orphaned resources in source
oc get all -n aa-test
oc get pvc -n aa-test
oc get cm,secrets -n aa-test

# Document remaining resources
oc get all,pvc,cm,secrets -n aa-test -o yaml > source-remaining-resources.yaml
```

## Rollback Procedures

### If Issues Occur Before Cleanup

If problems are discovered before running `cleanup-source-vms.sh`:

1. **VMs Still Exist in Source**: Simply restart them
   ```bash
   # Restart VMs in source namespace
   for vm in web-server-prod-01 database-prod-02; do
     virtctl start $vm -n aa-test
   done
   ```

2. **Delete Target Namespace Resources**:
   ```bash
   # Remove VMs from target
   oc delete vms --all -n bss-sa-a1-nl
   
   # Remove PVCs from target
   oc delete pvc --all -n bss-sa-a1-nl
   ```

3. **Restart Source VMs**:
   ```bash
   cd ~/vm-migration/aa-test-to-bss-sa-a1-nl-*/
   
   # Start each VM
   for vm in $(cat vm-migration-list-validated.txt); do
     echo "Starting $vm in aa-test"
     virtctl start $vm -n aa-test
   done
   ```

### If Issues Occur After Cleanup

If cleanup has already occurred:

1. **Check Backup Systems**: Restore from backup if available

2. **Recreate from Assessment**:
   ```bash
   # Navigate to assessment directory
   cd ~/vm-migration/aa-test-to-bss-sa-a1-nl-*/
   
   # Recreate VMs from exported YAMLs
   for yaml in *-full.yaml; do
     oc apply -f $yaml
   done
   ```

3. **Contact Support**: If data loss has occurred, engage support immediately

## Best Practices

### Migration Planning

1. **Start Small**: Migrate 1-2 non-critical VMs first
2. **Document Everything**: Save all output and reports
3. **Communicate**: Keep stakeholders informed
4. **Schedule Wisely**: Migrate during maintenance windows
5. **Test Thoroughly**: Validate application functionality before cleanup

### Execution Best Practices

1. **Read All Prompts Carefully**: Scripts ask for confirmation before destructive operations
2. **Monitor Progress**: Watch PVC cloning and VM startup screens
3. **Save Reports**: Keep validation reports for audit trail
4. **Wait Before Cleanup**: Keep source VMs for 24-48 hours
5. **Backup First**: Ensure backups are current before migration

### Team Coordination

1. **Assign Roles**:
   - Migration executor
   - Application validator
   - Communication coordinator

2. **Pre-Migration Meeting**:
   - Review VM list
   - Confirm downtime window
   - Assign responsibilities
   - Establish rollback criteria

3. **Post-Migration Meeting**:
   - Review validation results
   - Document issues encountered
   - Update procedures for next migration

## Appendix: Command Reference

### Quick Command Reference

```bash
# Assessment
./assess-vms.sh

# VM Selection
./create-migration-list.sh
vi vm-migration-list.txt
./validate-migration-list.sh

# Migration Execution
./stop-vms.sh
./clone-pvcs.sh
./migrate-resources.sh
./recreate-vms.sh
./start-and-verify-vms.sh

# Validation
./validate-migration.sh

# Cleanup
./cleanup-source-vms.sh

# Or use orchestrator for all steps
./orchestrate-migration.sh
```

### Manual VM Operations

```bash
# List VMs
oc get vms -n <namespace>

# Get VM details
oc describe vm <vm-name> -n <namespace>

# Stop VM
virtctl stop <vm-name> -n <namespace>

# Start VM
virtctl start <vm-name> -n <namespace>

# Restart VM
virtctl restart <vm-name> -n <namespace>

# Access VM console
virtctl console <vm-name> -n <namespace>

# Get VM IP
oc get vmi <vm-name> -n <namespace> -o jsonpath='{.status.interfaces[0].ipAddress}'
```

### Storage Operations

```bash
# List PVCs
oc get pvc -n <namespace>

# Get PVC details
oc describe pvc <pvc-name> -n <namespace>

# Check PVC events
oc get events -n <namespace> --field-selector involvedObject.name=<pvc-name>

# Delete PVC (careful!)
oc delete pvc <pvc-name> -n <namespace>
```

## Support Information

### Getting Help

For issues with this toolkit:

1. **Review Troubleshooting Section**: Most common issues are documented
2. **Check Logs**: Use `oc get events` and `oc logs` for detailed error messages
3. **Consult README.md**: Architecture and design information
4. **Contact Team Lead**: For organizational-specific guidance

### Reporting Issues

When reporting issues, include:

- Version number (from VERSION file or script output)
- Source and target namespace names
- Error messages (full text)
- Output from validation scripts
- Steps to reproduce

### Version Information

Current Version: 0.9.0

Check for updates:
- Review CHANGELOG.md for version history
- Verify VERSION file matches documentation
- Ensure all team members use same version

---

**End of PROCEDURE.md**
