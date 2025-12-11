# CLAUDE.MD - Project Context for Claude Code

## Document Metadata
- **Project**: OVE VM Namespace Move Toolkit
- **Version**: 0.10.0
- **Authors**: Marc Mitsialis
- **Last Edit**: 2025/12/11
- **License**: MIT License
- **Purpose**: Context document for Claude Code development environment

## Changelog
- **0.10.0** (2025/12/11) - Changed terminology from "migration" to "move" for namespace operations
                          - Renamed all scripts from migration to move terminology
                          - Changed "Author" to "Authors" in all metadata
                          - Added Changelog sections to all script headers
                          - Updated all documentation to reflect new terminology
- **0.9.0** (2024/12/10)  - Initial release

---

## Project Overview

This is a production-ready toolkit for moving Virtual Machines between namespaces in OpenShift Virtualization (OVE) environments. The toolkit was developed to address the common scenario where VMs are migrated from VMware to the wrong OVE namespace and need to be moved to the correct namespace.

### Key Design Principles
1. **Selective Move** - Move specific VMs, not entire namespaces
2. **Dynamic Configuration** - All scripts prompt for source/target namespaces at runtime
3. **Safety First** - Multiple validation stages and confirmation prompts
4. **Production Ready** - Comprehensive error handling, logging, and reporting
5. **Team Distribution** - Packaged for multi-user deployment

---

## Current Status

### Completed Work (v0.10.0)
✅ Complete script suite (12 executable scripts)
✅ Comprehensive documentation (5 core documents)
✅ Semantic versioning system implemented
✅ MIT license applied
✅ All metadata headers standardized
✅ Distribution tarball created (25 KB)
✅ Testing framework documented
✅ Rollback procedures defined

### Next Steps (Post-0.9.0)
- [ ] Test with real VM migrations (path to 1.0.0)
- [ ] Gather user feedback
- [ ] Enhance error handling based on edge cases
- [ ] Add parallel processing capability (future v1.1.0)
- [ ] Create automated test suite

---

## Project Structure

```
/home/claude/ove-vm-move-toolkit/
├── README.md                        # Architecture and design principles
├── PROCEDURE.md                     # Step-by-step usage guide
├── QUICKSTART.md                    # 5-minute quick start
├── CHANGELOG.md                     # Version history
├── SEMANTIC_VERSIONING.md          # Version management guide
├── CLAUDE.md                        # This file (for Claude Code)
├── LICENSE                          # MIT License
├── VERSION                          # Current version number
├── scripts/
│   ├── move-functions.sh       # Common function library
│   ├── orchestrate-move.sh     # Master control script
│   ├── assess-vms.sh               # VM discovery
│   ├── create-move-list.sh    # VM selection
│   ├── validate-move-list.sh  # Pre-migration validation
│   ├── stop-vms.sh                 # VM shutdown
│   ├── clone-pvcs.sh               # Storage cloning
│   ├── move-resources.sh        # ConfigMap/Secret migration
│   ├── recreate-vms.sh             # VM recreation
│   ├── start-and-verify-vms.sh     # VM startup
│   ├── validate-move.sh       # Post-migration validation
│   └── cleanup-source-vms.sh       # Cleanup
└── examples/
    └── vm-move-list-example.txt

OUTPUT (Created but separate):
/mnt/user-data/outputs/
├── ove-vm-move-toolkit-0.9.0.tar.gz  # Distribution tarball
├── README.md                               # (Copy for preview)
├── PROCEDURE.md                            # (Copy for preview)
├── QUICKSTART.md                           # (Copy for preview)
├── CHANGELOG.md                            # (Copy for preview)
├── SEMANTIC_VERSIONING.md                 # (Copy for preview)
└── PACKAGE_SUMMARY.txt                    # Quick reference
```

---

## Key Technologies and Dependencies

### Platform Requirements
- OpenShift 4.10+ with OpenShift Virtualization
- Dell PowerFlex storage with CSI driver
- Bash 4.0+ (for associative arrays)
- jq (JSON parsing)

### Client Tools Required
- `oc` CLI (OpenShift command-line)
- `virtctl` (KubeVirt VM management)
- Standard Unix tools (sed, grep, tar, etc.)

### Script Dependencies
- All scripts source `move-functions.sh` for common functions
- Namespace configuration saved in `namespace-config.txt` (created at runtime)
- VM list files: `vm-move-list.txt` and `vm-move-list-validated.txt`

---

## Development Workflow

### Making Changes to Scripts

1. **Before Editing**
   ```bash
   cd /home/claude/ove-vm-move-toolkit
   
   # Check current version
   cat VERSION
   
   # Review what needs to change
   cat CHANGELOG.md
   ```

2. **Edit Script(s)**
   ```bash
   # Edit the script
   vim scripts/clone-pvcs.sh
   
   # Update header metadata if needed:
   # - Version number (if incrementing)
   # - Last Edit date
   ```

3. **Test Changes** (if possible)
   ```bash
   # Syntax check
   bash -n scripts/clone-pvcs.sh
   
   # Test execution (in safe environment)
   # Use non-production namespaces for testing
   ```

4. **Update Version** (see Semantic Versioning section)

### Adding New Scripts

1. **Create with Proper Header**
   ```bash
   cat > scripts/new-script.sh << 'EOF'
   #!/bin/bash
   ################################################################################
   # Script Name: new-script.sh
   # Description: Brief description of what this script does
   # Process: Move OVE VMs between Namespaces
   # Author: Marc Mitsialis
   # Version: 0.9.1
   # Last Edit: 2024/12/XX
   # License: MIT License
   # Development Assistance: Claude.AI (Anthropic)
   ################################################################################
   
   # Script content here
   EOF
   
   chmod +x scripts/new-script.sh
   ```

2. **Source Common Functions**
   ```bash
   # At top of script
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/move-functions.sh" || source move-functions.sh
   ```

3. **Update Documentation**
   - Add to README.md (Components section)
   - Add to PROCEDURE.md (if user-facing)
   - Document in CHANGELOG.md

### Modifying Documentation

1. **Update Metadata Header**
   ```markdown
   - **Version**: 0.9.1
   - **Last Edit**: 2024/12/XX
   ```

2. **Follow Existing Structure**
   - Keep markdown formatting consistent
   - Maintain TOC if present
   - Update cross-references

3. **Update CHANGELOG.md**
   ```markdown
   ## [0.9.1] - 2024-12-XX
   ### Changed
   - Updated PROCEDURE.md with additional troubleshooting steps
   ```

---

## Semantic Versioning Guide

### Version Format: MAJOR.MINOR.PATCH

**Current Version: 0.10.0** (Pre-release)

### When to Increment

**PATCH (0.9.0 → 0.9.1)** - Bug fixes, documentation updates
- Fixed script typo
- Corrected documentation error
- Minor improvements to error messages
- No user action required

**MINOR (0.9.0 → 0.10.0 or 0.9.1 → 1.0.0)** - New features, backwards compatible
- Added new script
- Added optional command-line flags
- Performance improvements
- Enhanced features

**MAJOR (1.x.x → 2.0.0)** - Breaking changes
- Changed script names
- Modified command-line arguments
- Changed file formats
- Workflow changes requiring user action

### Version Update Process

1. **Update VERSION File**
   ```bash
   echo "0.9.1" > VERSION
   ```

2. **Update All Script Headers**
   ```bash
   # Manual or use script (see SEMANTIC_VERSIONING.md)
   for script in scripts/*.sh; do
       sed -i "s/^# Version: .*$/# Version: 0.9.1/" $script
       sed -i "s/^# Last Edit: .*$/# Last Edit: $(date +'%Y\/%m\/%d')/" $script
   done
   ```

3. **Update Documentation Headers**
   ```bash
   for doc in README.md PROCEDURE.md CHANGELOG.md SEMANTIC_VERSIONING.md QUICKSTART.md; do
       sed -i "s/\*\*Version\*\*: .*$/\*\*Version\*\*: 0.9.1/" $doc
       sed -i "s/\*\*Last Edit\*\*: .*$/\*\*Last Edit\*\*: $(date +'%Y\/%m\/%d')/" $doc
   done
   ```

4. **Update CHANGELOG.md**
   ```markdown
   ## [0.9.1] - 2024-12-XX
   ### Fixed
   - Description of bug fix
   
   ### Changed
   - Description of change
   ```

5. **Regenerate Tarball**
   ```bash
   cd /home/claude
   tar -czf /mnt/user-data/outputs/ove-vm-move-toolkit-0.9.1.tar.gz \
       ove-vm-move-toolkit/
   ```

---

## Common Development Tasks

### Task: Add Error Handling to Script

```bash
# Open script
vim scripts/clone-pvcs.sh

# Add at top (after sourcing functions)
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Add error traps
trap 'echo "ERROR: Script failed at line $LINENO"' ERR

# Add validation
if [ -z "$VARIABLE" ]; then
    echo "ERROR: VARIABLE is required"
    exit 1
fi
```

### Task: Add New Validation Check

```bash
# In validate-move-list.sh, add new check:

# Check if PVCs exist for each VM
for vm in "${VALID_VMS[@]}"; do
    PVC_COUNT=$(oc get pvc -n $SOURCE_NS -l kubevirt.io/vm=$vm --no-headers | wc -l)
    if [ $PVC_COUNT -eq 0 ]; then
        echo "⚠ $vm has no PVCs"
    fi
done
```

### Task: Improve Progress Indicator

```bash
# Add spinner function to move-functions.sh

show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Use in scripts:
long_running_command &
PID=$!
show_spinner $PID
wait $PID
```

### Task: Add Dry-Run Mode

```bash
# In each script, add:

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No changes will be made"
fi

# Wrap destructive operations:
if [ "$DRY_RUN" = true ]; then
    echo "Would execute: oc delete vm $vm -n $SOURCE_NS"
else
    oc delete vm $vm -n $SOURCE_NS
fi
```

---

## Testing and Validation

### Manual Testing Checklist

Before releasing a new version:

1. **Syntax Validation**
   ```bash
   for script in scripts/*.sh; do
       bash -n "$script" || echo "SYNTAX ERROR: $script"
   done
   ```

2. **Shellcheck (if available)**
   ```bash
   shellcheck scripts/*.sh
   ```

3. **Test in Development Environment**
   - Use test namespace with 1-2 non-critical VMs
   - Run through complete migration workflow
   - Verify all phases complete successfully
   - Check generated reports

4. **Verify Documentation**
   - README.md renders correctly
   - PROCEDURE.md steps are accurate
   - All links work
   - Examples are current

5. **Version Consistency Check**
   ```bash
   # All files should have same version
   grep -h "Version: " scripts/*.sh | sort -u
   grep -h "\*\*Version\*\*:" *.md | sort -u
   cat VERSION
   ```

### Test Scenario Template

```bash
# Test: Basic VM Migration
# Version: 0.10.0
# Date: 2025/12/11

# Setup
SOURCE_NS="test-source"
TARGET_NS="test-target"
TEST_VM="test-vm-01"

# Create test VM
oc create namespace $SOURCE_NS
# (create VM in source namespace)

# Execute migration
cd scripts
./assess-vms.sh  # Verify VM discovered
# (create move list with TEST_VM)
./validate-move-list.sh  # Should pass
./stop-vms.sh
./clone-pvcs.sh  # Monitor progress
./move-resources.sh
./recreate-vms.sh
./start-and-verify-vms.sh
./validate-move.sh  # Check report

# Verify
oc get vm $TEST_VM -n $TARGET_NS -o wide
oc get vmi $TEST_VM -n $TARGET_NS
oc get pvc -n $TARGET_NS -l kubevirt.io/vm=$TEST_VM

# Cleanup
./cleanup-source-vms.sh  # Only after verification
oc delete namespace $SOURCE_NS
oc delete namespace $TARGET_NS
```

---

## Common Issues and Solutions

### Issue: Script Can't Find Functions

**Problem**: `source: move-functions.sh: file not found`

**Solution**: 
```bash
# Scripts need to be run from correct directory
cd /home/claude/ove-vm-move-toolkit/scripts
./orchestrate-move.sh

# Or scripts use this pattern:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/move-functions.sh"
```

### Issue: Version Inconsistency

**Problem**: Different files show different versions

**Solution**:
```bash
# Use automated version update (see SEMANTIC_VERSIONING.md)
cd /home/claude/ove-vm-move-toolkit

# Check current versions
grep -h "Version: " scripts/*.sh | sort -u
grep -h "\*\*Version\*\*:" *.md | sort -u

# Update all at once (manual or scripted)
```

### Issue: Tarball Missing Files

**Problem**: Tarball doesn't include all files

**Solution**:
```bash
# Verify directory structure first
cd /home/claude
tree ove-vm-move-toolkit/

# Recreate tarball
tar -czf /mnt/user-data/outputs/ove-vm-move-toolkit-0.9.0.tar.gz \
    ove-vm-move-toolkit/

# Verify contents
tar -tzf /mnt/user-data/outputs/ove-vm-move-toolkit-0.9.0.tar.gz
```

---

## Git Workflow (if using version control)

### Initial Setup
```bash
cd /home/claude/ove-vm-move-toolkit
git init
git add .
git commit -m "Initial commit - OVE VM Namespace Move Toolkit v0.10.0"
git tag -a v0.10.0 -m "Version 0.9.0 - Initial release"
```

### Making Changes
```bash
# Create branch for changes
git checkout -b feature/add-dry-run-mode

# Make changes
vim scripts/clone-pvcs.sh

# Commit
git add scripts/clone-pvcs.sh
git commit -m "Add dry-run mode to PVC cloning"

# Merge back
git checkout main
git merge feature/add-dry-run-mode

# Tag new version
git tag -a v0.9.1 -m "Version 0.9.1 - Added dry-run mode"
```

### Release Process
```bash
# Ensure all changes committed
git status

# Tag release
git tag -a v0.10.0 -m "Version 0.10.0 - New features"

# Create tarball
tar -czf ove-vm-move-toolkit-0.10.0.tar.gz ove-vm-move-toolkit/

# Push (if using remote)
git push origin main
git push origin v0.10.0
```

---

## Architecture Notes for Development

### Script Execution Flow

```
orchestrate-move.sh
├── Sources: move-functions.sh
├── Prompts: get_namespace_config()
└── Executes in sequence:
    ├── assess-vms.sh → Assessment report
    ├── create-move-list.sh → Template file
    ├── [User edits vm-move-list.txt]
    ├── validate-move-list.sh → Validated list
    ├── stop-vms.sh → VMs stopped
    ├── clone-pvcs.sh → PVCs cloned
    ├── move-resources.sh → ConfigMaps/Secrets migrated
    ├── recreate-vms.sh → VMs created in target
    ├── start-and-verify-vms.sh → VMs started
    ├── validate-move.sh → Validation report
    └── cleanup-source-vms.sh → Source cleanup
```

### State Management

Scripts maintain state through files:
- `namespace-config.txt` - Source and target namespaces
- `vm-move-list.txt` - User-edited VM list
- `vm-move-list-validated.txt` - Validated VM list
- `*-report.txt` - Assessment and validation reports
- `target-vm-manifests/*.yaml` - Exported VM definitions

### Error Handling Pattern

```bash
# 1. Set strict mode
set -e  # Exit on error

# 2. Validate inputs
[ -z "$VAR" ] && echo "ERROR: VAR required" && exit 1

# 3. Check prerequisites
command -v oc >/dev/null 2>&1 || { echo "ERROR: oc not found"; exit 1; }

# 4. Confirm destructive operations
read -p "Proceed? (yes/no): " confirm
[ "$confirm" != "yes" ] && echo "Aborted" && exit 0

# 5. Provide meaningful errors
if ! oc get vm "$vm" -n $NS; then
    echo "ERROR: VM '$vm' not found in namespace '$NS'"
    exit 1
fi
```

---

## Important Files and Their Purpose

### move-functions.sh
**Purpose**: Shared library of common functions
**Key Functions**:
- `get_namespace_config()` - Load or prompt for namespaces
- `get_vm_list()` - Parse VM list file
- `load_namespace_config()` - Load from file
- `prompt_namespaces()` - Interactive prompt

**Usage**: Sourced by all other scripts

### orchestrate-move.sh
**Purpose**: Master control script with menu interface
**Features**:
- Menu-driven workflow
- Can run individual steps or full pipeline
- Namespace reconfiguration option
- Error handling between steps

### assess-vms.sh
**Purpose**: Discovery and assessment
**Outputs**:
- `assessment-report.txt` - Detailed inventory
- `{vm-name}-full.yaml` - Exported VM definitions
- `namespace-config.txt` - Saved configuration

### clone-pvcs.sh
**Purpose**: PVC cloning with monitoring
**Key Features**:
- Uses CSI dataSource for cloning
- Real-time progress monitoring
- Automatic PVC binding verification
- Label preservation for VM association

---

## Future Enhancement Ideas

### For 0.9.x (Bug fixes and minor improvements)
- Enhanced error messages with troubleshooting hints
- Better progress indicators with ETA
- Automatic retry logic for transient failures
- Pre-flight checks for storage capacity

### For 0.10.0 or 1.0.0 (New features)
- Dry-run mode for all operations
- Parallel PVC cloning for faster migrations
- Email notifications on completion
- Detailed timing metrics per phase

### For 1.1.0 (Major features)
- Web UI for non-CLI users
- Integration with monitoring systems (Prometheus)
- Automated rollback on failure
- Migration scheduling and queuing

### For 2.0.0 (Breaking changes)
- JSON configuration instead of interactive prompts
- API-based operation for automation
- Multi-cluster support
- Plugin architecture for custom workflows

---

## References and Resources

### External Documentation
- [OpenShift Virtualization](https://docs.openshift.com/container-platform/latest/virt/)
- [Kubernetes PVC Cloning](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-cloning)
- [Dell PowerFlex CSI](https://dell.github.io/csm-docs/)
- [KubeVirt](https://kubevirt.io/user-guide/)
- [Semantic Versioning](https://semver.org/)

### Internal Documentation
- README.md - Architecture overview
- PROCEDURE.md - Usage guide
- SEMANTIC_VERSIONING.md - Version management
- CHANGELOG.md - Version history

---

## Quick Command Reference

```bash
# Project Location
cd /home/claude/ove-vm-move-toolkit

# Run Main Script
cd scripts && ./orchestrate-move.sh

# Check Version
cat VERSION

# View Documentation
cat README.md | less
cat PROCEDURE.md | less

# Test Script Syntax
bash -n scripts/clone-pvcs.sh

# Create New Tarball
cd /home/claude
tar -czf /mnt/user-data/outputs/ove-vm-move-toolkit-$(cat ove-vm-move-toolkit/VERSION).tar.gz \
    ove-vm-move-toolkit/

# Check File Structure
tree ove-vm-move-toolkit/

# Verify Tarball Contents
tar -tzf /mnt/user-data/outputs/ove-vm-move-toolkit-0.9.0.tar.gz

# Update All Version Numbers (manual)
find . -type f \( -name "*.sh" -o -name "*.md" \) -exec sed -i 's/0\.9\.0/0.9.1/g' {} \;
```

---

## Development Environment Setup (for new Claude Code session)

When starting a new Claude Code session:

1. **Navigate to project**
   ```bash
   cd /home/claude/ove-vm-move-toolkit
   ```

2. **Review current status**
   ```bash
   cat VERSION
   cat CHANGELOG.md
   ```

3. **Check what needs work**
   ```bash
   # Look for TODOs in code
   grep -r "TODO" scripts/
   
   # Check recent changes
   ls -lt
   ```

4. **Set up any needed environment**
   ```bash
   # Ensure scripts are executable
   chmod +x scripts/*.sh
   
   # Check for required tools
   command -v oc virtctl jq
   ```

---

## Notes for Claude Code

### Context You Should Know
- This project was developed with Claude.AI (web interface)
- All files have standardized metadata headers
- Version 0.9.0 is pre-release (production testing needed for 1.0.0)
- Scripts are designed to be run in sequence or via orchestrator
- The toolkit is namespace-agnostic (prompts at runtime)
- Target platform: OpenShift 4.10+ with PowerFlex storage

### Common Requests You Might Receive
1. "Add feature X to script Y" → Update script, version, changelog
2. "Fix bug in Z" → Fix, increment patch version, update changelog
3. "Improve documentation" → Update relevant .md file, maintain consistency
4. "Create new version" → Follow semantic versioning guide
5. "Add error handling" → Use established patterns from existing scripts

### Best Practices to Follow
- Always update version metadata when changing files
- Document changes in CHANGELOG.md
- Test scripts for syntax errors (bash -n)
- Maintain consistent code style across scripts
- Keep documentation synchronized with code
- Preserve metadata headers in all files

### What Makes This Project Special
- Production-ready from day one
- Complete documentation
- Team distribution focus
- Safety mechanisms built-in
- Comprehensive error handling
- Semantic versioning from start

---

## Contact and Support

**Primary Author**: Marc Mitsialis
**Version**: 0.9.0
**Development Tool**: Claude.AI (Anthropic)
**License**: MIT License
**Project Purpose**: Simplify OpenShift VM namespace migrations

---

**This CLAUDE.MD file provides complete context for continuing development in Claude Code. All file locations, workflows, and development patterns are documented above.**
