# Move OVE VMs between Namespaces

## Document Metadata

- **Process Name**: Move OVE VMs between Namespaces
- **Authors**: Marc Mitsialis
- **Version**: 0.9.0
- **Last Edit**: 2025/12/11
- **License**: MIT License
- **Development Assistance**: Claude.AI (Anthropic)
- **Target Platform**: OpenShift Virtualization (OVE) on Dell PowerFlex

## Overview

This toolkit provides a structured, automated approach for migrating Virtual Machines (VMs) between namespaces in OpenShift Virtualization environments. The solution addresses the common scenario where VMs are inadvertently provisioned in incorrect namespaces during migration from legacy virtualization platforms (e.g., VMware to OVE).

### Problem Statement

When migrating VMs from VMware vSphere to OpenShift Virtualization, VMs and their associated resources (PVCs, ConfigMaps, Secrets, Services) may be created in the wrong namespace. OpenShift/Kubernetes does not provide native "move" functionality for namespaced resources, requiring a structured approach to:

1. Clone storage volumes across namespaces
2. Recreate VMs with proper namespace associations
3. Migrate dependent resources
4. Validate the migration
5. Clean up source namespace resources

### Design Principles

#### 1. Selective Migration
The toolkit operates on explicitly identified VMs rather than bulk namespace operations. This allows:
- Granular control over which VMs are migrated
- Coexistence of migrating and non-migrating VMs in the source namespace
- Incremental migration strategies

#### 2. Safety First
Multiple safety mechanisms are built in:
- Pre-migration assessment and validation
- Confirmation prompts before destructive operations
- Source resources remain intact until explicit cleanup
- Validation reporting before cleanup authorization

#### 3. Namespace Agnostic
Scripts prompt for source and target namespaces at runtime, making the toolkit reusable across:
- Different namespace pairs
- Multiple clusters
- Various migration scenarios

#### 4. Idempotency
Where possible, operations are idempotent:
- PVC cloning checks for existing resources
- Resource migration skips duplicates
- VM recreation can be retried

#### 5. Observability
Comprehensive logging and reporting:
- Detailed assessment reports
- Migration progress monitoring
- Post-migration validation reports
- Audit trail of all operations

## Technical Architecture

### Storage Migration Strategy

The toolkit uses **PVC cloning** rather than PV relabeling because:

1. **Namespace Isolation**: PVs are cluster-scoped but PVCs are namespace-scoped. Cross-namespace PVC cloning is supported by CSI drivers.

2. **PowerFlex CSI Support**: Dell PowerFlex CSI driver supports efficient volume cloning through the `dataSource` field in PVC specifications.

3. **Data Integrity**: VMs are stopped before cloning to ensure filesystem consistency and prevent data corruption.

4. **Storage Independence**: The cloning approach works regardless of the underlying PowerFlex storage topology.

### Resource Dependency Management

VMs in OpenShift Virtualization have multiple resource dependencies:

```
VM
├── PersistentVolumeClaims (storage)
├── DataVolumes (optional)
├── ConfigMaps (cloud-init, configuration)
├── Secrets (credentials, certificates)
├── Services (network exposure)
└── NetworkAttachmentDefinitions (secondary networks)
```

The toolkit handles these in the correct order:
1. Storage (PVCs) - must exist before VM creation
2. Configuration resources (ConfigMaps, Secrets)
3. Network resources (Services)
4. VM definitions
5. VM instance startup

### State Machine Flow

```
┌─────────────────┐
│   Assessment    │ ← Discover VMs and dependencies
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  VM Selection   │ ← Create explicit move list
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Validation    │ ← Verify VMs exist and are accessible
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    Stop VMs     │ ← Ensure data consistency
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Clone PVCs    │ ← Duplicate storage to target namespace
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│Migrate Resources│ ← Copy ConfigMaps, Secrets, Services
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Recreate VMs   │ ← Create VM definitions in target
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Start VMs     │ ← Boot VMs in target namespace
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Validation    │ ← Verify successful migration
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    Cleanup      │ ← Remove source namespace resources
└─────────────────┘
```

## Components Overview

### Core Scripts

1. **move-functions.sh**
   - Library of common functions
   - Namespace configuration management
   - VM list parsing utilities
   - Reusable across all migration scripts

2. **assess-vms.sh**
   - Discovers all VMs in source namespace
   - Documents VM configurations
   - Identifies dependencies
   - Exports VM definitions for analysis

3. **create-move-list.sh**
   - Generates template for VM selection
   - Lists available VMs
   - Creates editable migration manifest

4. **validate-move-list.sh**
   - Verifies VM existence
   - Checks VM accessibility
   - Creates validated VM list for migration

5. **stop-vms.sh**
   - Stops VMs gracefully
   - Verifies VM instance termination
   - Ensures no active I/O before cloning

6. **clone-pvcs.sh**
   - Clones PVCs using CSI dataSource
   - Monitors cloning progress
   - Verifies PVC binding in target namespace

7. **move-resources.sh**
   - Migrates ConfigMaps
   - Migrates Secrets (excluding service accounts)
   - Migrates Services
   - Tracks resource migration to prevent duplicates

8. **recreate-vms.sh**
   - Exports VM definitions from source
   - Modifies namespace references
   - Creates VMs in target namespace

9. **start-and-verify-vms.sh**
   - Starts VMs in target namespace
   - Monitors startup progress
   - Reports IP addresses and node placement

10. **validate-move.sh**
    - Comprehensive post-migration validation
    - Compares source and target states
    - Generates detailed validation report

11. **cleanup-source-vms.sh**
    - Removes VMs from source namespace
    - Deletes associated PVCs and DataVolumes
    - Requires explicit confirmation

12. **orchestrate-move.sh**
    - Master control script
    - Menu-driven interface
    - Sequential or full-pipeline execution

### Documentation Files

1. **README.md** (this file)
   - Overview and principles
   - Architecture and design
   - Component descriptions

2. **PROCEDURE.md**
   - Step-by-step usage instructions
   - Prerequisites and requirements
   - Troubleshooting guide

3. **CHANGELOG.md**
   - Version history
   - Change tracking

4. **LICENSE**
   - MIT License text

5. **VERSION**
   - Current version number

## Key Features

### Dynamic Namespace Configuration

All scripts prompt for source and target namespaces at execution time, eliminating hardcoded values and enabling:
- Multi-cluster deployments
- Different migration scenarios
- Team-wide toolkit distribution

### Selective Resource Migration

The toolkit migrates only resources explicitly associated with selected VMs through:
- Kubernetes labels (`kubevirt.io/vm`)
- Owner references
- Associative array tracking to prevent duplicates

### Progress Monitoring

Real-time monitoring of long-running operations:
- PVC cloning status with capacity and phase
- VM startup monitoring with IP assignment
- Clear visual feedback on operation progress

### Validation and Reporting

Comprehensive validation at multiple stages:
- Pre-migration VM validation
- Post-clone PVC verification
- Post-startup VM health checks
- Detailed validation reports for audit

## Semantic Versioning

This toolkit follows [Semantic Versioning 2.0.0](https://semver.org/):

**Version Format**: MAJOR.MINOR.PATCH

- **MAJOR** (0): Breaking changes to command-line interface, script names, or workflow
- **MINOR** (9): New features, additional scripts, enhanced functionality
- **PATCH** (0): Bug fixes, documentation updates, non-breaking improvements

### Current Version: 0.10.0

The `0.x.x` major version indicates pre-release status. Key considerations:

- APIs and script interfaces may change
- Suitable for internal use and testing
- Production use should await 1.0.0 release

### Version 1.0.0 Criteria

Release criteria for stable 1.0.0:
- Successful migration of 50+ VMs across 10+ scenarios
- Comprehensive error handling for all edge cases
- Complete test coverage
- Production validation in multiple environments
- Final documentation review

## References and Sources

### Primary Sources

1. **OpenShift Virtualization Documentation**
   - [OpenShift Virtualization 4.x Documentation](https://docs.openshift.com/container-platform/latest/virt/about-virt.html)
   - VM lifecycle management
   - Storage configuration

2. **Kubernetes Documentation**
   - [PersistentVolumeClaim Cloning](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-cloning)
   - Namespace concepts
   - Resource management

3. **Dell PowerFlex CSI Driver**
   - [Dell CSI Operator Documentation](https://dell.github.io/csm-docs/)
   - Volume cloning capabilities
   - Storage provisioning

4. **KubeVirt Project**
   - [KubeVirt User Guide](https://kubevirt.io/user-guide/)
   - VM management APIs
   - Virtual machine instances

### Development Assistance

This toolkit was developed with assistance from **Claude.AI** (Anthropic), which provided:
- Script architecture and design patterns
- PowerShell and Bash best practices
- Error handling strategies
- Documentation structure
- Migration workflow optimization

### Related Standards

- [Semantic Versioning 2.0.0](https://semver.org/)
- [MIT License](https://opensource.org/licenses/MIT)
- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)

## Use Cases

### 1. Post-Migration Namespace Correction

**Scenario**: VMs were migrated from VMware to OVE but ended up in a temporary namespace (`aa-test`) instead of the production namespace (`bss-sa-a1-nl`).

**Solution**: Use this toolkit to selectively move the misplaced VMs to the correct namespace while leaving test VMs in place.

### 2. Namespace Reorganization

**Scenario**: Organizational restructuring requires VMs to be moved from department-specific namespaces to project-based namespaces.

**Solution**: Systematically migrate VMs between namespaces with full validation and minimal downtime.

### 3. Multi-Tenant Isolation

**Scenario**: VMs need to be isolated into separate namespaces for security, RBAC, or resource quota purposes.

**Solution**: Clone VMs and their resources to new namespaces with proper isolation boundaries.

### 4. Disaster Recovery Testing

**Scenario**: Test DR procedures by cloning production VMs to a test namespace without affecting production.

**Solution**: Use the cloning mechanism to create isolated copies in a DR namespace.

## Limitations and Constraints

### Technical Limitations

1. **Downtime Required**: VMs must be stopped during migration to ensure data consistency
2. **Network Reconfiguration**: VMs may receive new IP addresses if using DHCP
3. **Storage Capacity**: Target namespace must have sufficient storage quota for cloned PVCs
4. **CSI Driver Support**: Requires CSI driver that supports volume cloning (PowerFlex CSI supported)

### Operational Constraints

1. **RBAC Permissions**: User must have admin privileges in both source and target namespaces
2. **Namespace Existence**: Target namespace should exist or be created during migration
3. **Network Policies**: May need adjustment in target namespace
4. **Service Dependencies**: External services may need configuration updates for new namespace

### Not Handled by This Toolkit

- **DNS Updates**: External DNS records must be updated manually
- **Load Balancer Reconfiguration**: External load balancers need manual updates
- **Application-Level Configuration**: Applications with namespace-specific config need manual updates
- **Monitoring/Alerting**: Monitoring systems need namespace updates
- **Backup Policy Migration**: Backup configurations are not automatically migrated

## Security Considerations

### Secrets Handling

- Secrets are migrated but never logged or displayed
- Service account tokens are explicitly excluded from migration
- Validation reports do not include secret contents

### RBAC Requirements

Minimum required permissions:
```yaml
# Source namespace
- get, list, watch: vms, vmis, pvcs, dvs, configmaps, secrets, services
- delete: vms, pvcs, dvs (for cleanup)

# Target namespace  
- create, get, list: vms, pvcs, configmaps, secrets, services
- get, list, watch: vmis

# Cluster-level
- get: namespaces
- create: namespaces (if creating target)
```

### Audit Trail

All operations generate logs and reports:
- Assessment reports document source state
- Validation reports document target state
- Scripts can be run with `set -x` for detailed logging
- Save all output for audit purposes

## Support and Maintenance

### Version Control

Store this toolkit in version control (Git) to:
- Track modifications over time
- Share updates across team
- Roll back if issues occur
- Document changes in CHANGELOG.md

### Future Enhancements

Potential improvements for future versions:
- Parallel VM processing for faster migrations
- Automated rollback on failure
- Integration with CI/CD pipelines
- Metrics collection and reporting
- Web-based UI for non-CLI users

### Contributing

When making modifications:
1. Update version number per semantic versioning rules
2. Document changes in CHANGELOG.md
3. Update this README if architecture changes
4. Test thoroughly before distribution
5. Update Last Edit date in metadata

## License

MIT License

Copyright (c) 2024 Marc Mitsialis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

**End of README.md**
