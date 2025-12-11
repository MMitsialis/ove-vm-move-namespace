# Quick Start Guide - Move OVE VMs between Namespaces

## Document Metadata
- **Authors**: Marc Mitsialis
- **Version**: 0.9.0
- **Last Edit**: 2025/12/11
- **License**: MIT License

## 5-Minute Setup

### 1. Extract the Toolkit
```bash
cd ~/tools
tar -xzf ove-vm-move-toolkit-0.9.0.tar.gz
cd ove-vm-move-toolkit
chmod +x scripts/*.sh
```

### 2. Verify Prerequisites
```bash
oc whoami              # Check OpenShift connection
virtctl version        # Verify virtctl installed
oc get namespaces      # List available namespaces
```

### 3. Run the Orchestrator
```bash
cd scripts
./orchestrate-move.sh
```

### 4. Follow the Menu
1. Select option 1: Assess VMs
2. Select option 2: Create VM list
3. Edit `vm-move-list.txt` (add your VM names)
4. Select option 3: Validate list
5. Select option 11: Run full move

## What Gets Installed

```
ove-vm-move-toolkit/
├── README.md                    # Architecture & design
├── PROCEDURE.md                 # Detailed usage guide
├── CHANGELOG.md                 # Version history
├── LICENSE                      # MIT License
├── VERSION                      # Version number
├── SEMANTIC_VERSIONING.md      # Version management guide
├── QUICKSTART.md               # This file
├── scripts/                    # All migration scripts
│   ├── orchestrate-move.sh
│   ├── assess-vms.sh
│   ├── create-move-list.sh
│   ├── validate-move-list.sh
│   ├── stop-vms.sh
│   ├── clone-pvcs.sh
│   ├── move-resources.sh
│   ├── recreate-vms.sh
│   ├── start-and-verify-vms.sh
│   ├── validate-move.sh
│   ├── cleanup-source-vms.sh
│   └── move-functions.sh
└── examples/
    └── vm-move-list-example.txt
```

## First Migration Example

```bash
# 1. Assess VMs in source namespace
cd ove-vm-move-toolkit/scripts
./assess-vms.sh
# Enter source: aa-test
# Enter target: bss-sa-a1-nl

# 2. Navigate to assessment directory
cd ~/vm-migration/aa-test-to-bss-sa-a1-nl-*/

# 3. Create VM list
../ove-vm-move-toolkit/scripts/create-move-list.sh

# 4. Edit the list
vi vm-move-list.txt
# Add: test-vm-01

# 5. Validate
../ove-vm-move-toolkit/scripts/validate-move-list.sh

# 6. Run migration
../ove-vm-move-toolkit/scripts/orchestrate-move.sh
# Select option 11: Run full move
```

## Common Commands

```bash
# Check VMs in namespace
oc get vms -n aa-test

# Check VM status
oc get vm <vm-name> -n aa-test -o wide

# Check PVCs
oc get pvc -n aa-test

# Stop a VM manually
virtctl stop <vm-name> -n aa-test

# Start a VM manually
virtctl start <vm-name> -n bss-sa-a1-nl
```

## Getting Help

- Read PROCEDURE.md for detailed instructions
- Check README.md for architecture details
- Review CHANGELOG.md for version history
- See SEMANTIC_VERSIONING.md for version management

## Support

For issues:
1. Check logs: `oc get events -n <namespace>`
2. Review PROCEDURE.md troubleshooting section
3. Contact: Marc Mitsialis

---
**Version 0.9.0** | MIT License | Assisted by Claude.AI
