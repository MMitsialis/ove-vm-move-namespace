# Semantic Versioning Guide

## Document Metadata

- **Process Name**: Move OVE VMs between Namespaces
- **Document Type**: Semantic Versioning Guide
- **Authors**: Marc Mitsialis
- **Version**: 0.9.0
- **Last Edit**: 2025/12/11
- **License**: MIT License

## Overview

This toolkit follows [Semantic Versioning 2.0.0](https://semver.org/) for version management. This document explains the versioning scheme and provides guidelines for future maintainers.

## Version Format

```
MAJOR.MINOR.PATCH
```

Example: `0.9.0`, `1.2.3`, `2.0.1`

### Components

**MAJOR version** (first number)
- Incremented for incompatible API/interface changes
- Breaking changes that require user action
- Indicates major architectural changes

**MINOR version** (second number)
- Incremented for backwards-compatible functionality additions
- New features that don't break existing usage
- Significant improvements or enhancements

**PATCH version** (third number)
- Incremented for backwards-compatible bug fixes
- Documentation updates
- Minor improvements
- Security patches

## Version 0.x.x (Pre-Release)

**Current Status**: 0.9.0

The major version `0` indicates this toolkit is in **pre-release/development** status.

### Characteristics of 0.x.x versions:
- APIs and interfaces may change without notice
- Suitable for internal testing and validation
- Not recommended for critical production use
- Breaking changes can occur in MINOR versions
- Documentation may be incomplete

### When to use 0.x.x:
- Initial development phase
- Feature testing and validation
- Gathering user feedback
- Iterating on design

## Version Decision Matrix

### When to Increment MAJOR (X.0.0)

**MAJOR version changes when**:

1. **Script Names Change**
   ```bash
   # BREAKING: Renamed script
   Old: migrate-vms.sh
   New: vm-migrator.sh
   Version: 1.0.0 → 2.0.0
   ```

2. **Command Line Arguments Change**
   ```bash
   # BREAKING: Changed required parameters
   Old: ./script.sh
   New: ./script.sh --source NS --target NS
   Version: 1.0.0 → 2.0.0
   ```

3. **File Format Changes**
   ```bash
   # BREAKING: Changed VM list format
   Old: vm-move-list.txt (plain list)
   New: vm-move-list.json (JSON format)
   Version: 1.0.0 → 2.0.0
   ```

4. **Workflow Changes**
   ```bash
   # BREAKING: Different execution order required
   Old: assess → migrate → validate
   New: assess → prepare → migrate → cleanup → validate
   Version: 1.0.0 → 2.0.0
   ```

5. **Minimum Requirements Change**
   ```bash
   # BREAKING: New minimum requirements
   Old: OpenShift 4.10+
   New: OpenShift 4.12+ (4.10 no longer supported)
   Version: 1.0.0 → 2.0.0
   ```

### When to Increment MINOR (x.Y.0)

**MINOR version changes when**:

1. **New Scripts Added**
   ```bash
   # NEW FEATURE: Added parallel migration script
   New: parallel-migrate.sh
   Version: 1.0.0 → 1.1.0
   ```

2. **New Options Added (Backwards Compatible)**
   ```bash
   # NEW FEATURE: Optional dry-run mode
   ./script.sh --dry-run
   Version: 1.0.0 → 1.1.0
   ```

3. **New Features**
   ```bash
   # NEW FEATURE: Email notifications
   - Added email notification support
   - Old usage still works
   Version: 1.0.0 → 1.1.0
   ```

4. **Significant Performance Improvements**
   ```bash
   # ENHANCEMENT: 50% faster PVC cloning
   - Optimized cloning algorithm
   - No user action required
   Version: 1.0.0 → 1.1.0
   ```

5. **New Documentation**
   ```bash
   # ENHANCEMENT: Added video tutorials
   - Added docs/tutorials/
   - Existing docs unchanged
   Version: 1.0.0 → 1.1.0
   ```

### When to Increment PATCH (x.y.Z)

**PATCH version changes when**:

1. **Bug Fixes**
   ```bash
   # BUG FIX: Fixed PVC name parsing
   - Corrected regex for PVC names with hyphens
   Version: 1.0.0 → 1.0.1
   ```

2. **Documentation Fixes**
   ```bash
   # DOC FIX: Corrected typos in PROCEDURE.md
   - Fixed spelling errors
   - Clarified step 3
   Version: 1.0.0 → 1.0.1
   ```

3. **Minor Script Improvements**
   ```bash
   # IMPROVEMENT: Better error messages
   - More descriptive error output
   - No functional changes
   Version: 1.0.0 → 1.0.1
   ```

4. **Security Patches**
   ```bash
   # SECURITY: Fixed shell injection vulnerability
   - Sanitized user input
   - Emergency patch
   Version: 1.0.0 → 1.0.1
   ```

5. **Dependency Updates**
   ```bash
   # UPDATE: Updated jq requirement
   - Now requires jq 1.6+ (was 1.5+)
   - Still backwards compatible
   Version: 1.0.0 → 1.0.1
   ```

## Version Lifecycle

### Path to 1.0.0

**Current**: 0.9.0
**Target**: 1.0.0 (First stable release)

**Requirements for 1.0.0**:
- [ ] 50+ successful VM migrations
- [ ] Complete test coverage
- [ ] All documentation complete
- [ ] Production validation
- [ ] Security review complete
- [ ] No known critical bugs
- [ ] API stability confirmed

**Incremental releases to 1.0.0**:
```
0.9.0 → 0.9.1 (bug fixes)
0.9.1 → 0.9.2 (more bug fixes)
0.9.2 → 0.10.0 (new features, still pre-release)
0.10.0 → 1.0.0 (stable release)
```

### Post-1.0.0 Development

After 1.0.0 release:
```
1.0.0 → 1.0.1 (bug fix)
1.0.1 → 1.1.0 (new feature)
1.1.0 → 1.1.1 (bug fix)
1.1.1 → 2.0.0 (breaking change)
```

## Practical Examples

### Example 1: Adding Dry-Run Mode

**Change**:
```bash
# Add optional --dry-run flag to all scripts
./migrate-vms.sh --dry-run
```

**Version Impact**:
- **MINOR increment**: New feature, backwards compatible
- **Old usage still works**: `./migrate-vms.sh` (without flag)
- **New version**: 1.0.0 → 1.1.0

**CHANGELOG Entry**:
```markdown
## [1.1.0] - 2024-12-15
### Added
- Dry-run mode for all migration scripts (--dry-run flag)
- Preview migrations without making changes
- Validates configuration before execution
```

### Example 2: Fixing VM Name Parsing Bug

**Change**:
```bash
# Fixed bug where VMs with underscores weren't recognized
# VM name regex updated: [-a-z0-9]+ → [-a-z0-9_]+
```

**Version Impact**:
- **PATCH increment**: Bug fix only
- **No user action required**
- **New version**: 1.0.0 → 1.0.1

**CHANGELOG Entry**:
```markdown
## [1.0.1] - 2024-12-12
### Fixed
- VM name parsing now correctly handles underscores
- Resolved issue #42 where VMs like "web_server_01" were rejected
```

### Example 3: Changing to JSON Config

**Change**:
```bash
# Replace vm-move-list.txt with vm-move-list.json
# Old format: text file with VM names
# New format: JSON with VM names and options
```

**Version Impact**:
- **MAJOR increment**: Breaking change
- **Old format no longer supported**
- **Migration guide required**
- **New version**: 1.5.0 → 2.0.0

**CHANGELOG Entry**:
```markdown
## [2.0.0] - 2025-01-01
### Changed
- **BREAKING**: VM list format changed from .txt to .json
- Migration guide: docs/MIGRATION-1.x-to-2.x.md
- Use `tools/convert-vm-list.sh` to migrate old lists

### Migration Path
```bash
# Convert old format to new format
./tools/convert-vm-list.sh vm-move-list.txt > vm-move-list.json
```
```

## Version Update Checklist

When incrementing version, update these files:

### 1. VERSION File
```bash
# Update version number
echo "1.1.0" > VERSION
```

### 2. All Script Headers
```bash
# Update in each .sh file:
# Version: 1.1.0
# Last Edit: 2024/12/15
```

### 3. Documentation Headers
```bash
# Update in README.md, PROCEDURE.md, CHANGELOG.md:
- **Version**: 1.1.0
- **Last Edit**: 2024/12/15
```

### 4. CHANGELOG.md
```markdown
## [1.1.0] - 2024-12-15
### Added
- New feature description

### Changed
- What changed

### Fixed
- What was fixed

### Deprecated
- What's being phased out

### Removed
- What was removed

### Security
- Security fixes
```

### 5. README.md
```markdown
# Update version references
Current Version: 1.1.0
```

### 6. Create Git Tag
```bash
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin v1.1.0
```

## Version Communication

### Release Notes Template

```markdown
# Release v1.1.0 - [Release Name]

**Release Date**: 2024/12/15
**Type**: Minor Release

## Highlights
- Added dry-run mode
- Improved error messages
- Enhanced documentation

## What's New
- Dry-run mode for all operations
- Better progress indicators
- New troubleshooting guide

## Bug Fixes
- Fixed PVC name parsing issue
- Corrected timeout calculation
- Resolved namespace validation bug

## Upgrade Instructions
1. Extract new tarball
2. Run `./scripts/orchestrate-move.sh`
3. No configuration changes required

## Breaking Changes
None

## Deprecated Features
None

## Contributors
- Marc Mitsialis
```

## Automated Version Management

### Version Check Script

```bash
#!/bin/bash
# check-version.sh - Verify version consistency

VERSION_FILE="VERSION"
EXPECTED_VERSION=$(cat $VERSION_FILE)

echo "Checking version consistency..."

# Check all script headers
for script in scripts/*.sh; do
    SCRIPT_VERSION=$(grep "^# Version:" $script | awk '{print $3}')
    if [ "$SCRIPT_VERSION" != "$EXPECTED_VERSION" ]; then
        echo "ERROR: $script has version $SCRIPT_VERSION, expected $EXPECTED_VERSION"
        exit 1
    fi
done

echo "✓ All versions are consistent: $EXPECTED_VERSION"
```

### Version Update Script

```bash
#!/bin/bash
# update-version.sh - Update version across all files

OLD_VERSION=$(cat VERSION)
read -p "Enter new version: " NEW_VERSION

# Validate semver format
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid version format. Use X.Y.Z"
    exit 1
fi

echo "Updating from $OLD_VERSION to $NEW_VERSION..."

# Update VERSION file
echo "$NEW_VERSION" > VERSION

# Update all scripts
for script in scripts/*.sh; do
    sed -i "s/^# Version: .*$/# Version: $NEW_VERSION/" $script
    sed -i "s/^# Last Edit: .*$/# Last Edit: $(date +'%Y\/%m\/%d')/" $script
done

# Update documentation
for doc in README.md PROCEDURE.md CHANGELOG.md; do
    sed -i "s/\*\*Version\*\*: .*$/\*\*Version\*\*: $NEW_VERSION/" $doc
    sed -i "s/\*\*Last Edit\*\*: .*$/\*\*Last Edit\*\*: $(date +'%Y\/%m\/%d')/" $doc
done

echo "✓ Version updated to $NEW_VERSION"
echo "Don't forget to:"
echo "  1. Update CHANGELOG.md"
echo "  2. Commit changes"
echo "  3. Create git tag: git tag -a v$NEW_VERSION -m 'Release $NEW_VERSION'"
```

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Git Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)

---

**End of SEMANTIC_VERSIONING.md**
