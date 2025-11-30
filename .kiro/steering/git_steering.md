## Git Steering - Automated Steering File Management

This project uses the `git_steering` gem to automatically manage symlinks for `.kiro/steering/*.md` files from vendor gems and submodules into the parent project's `.kiro/steering` directory.

reference: https://github.com/magenticmarketactualskill/git_steering.git

### Quick Command

To build/update all steering file symlinks:

```bash
bin/git_steering symlink_build
```

### What It Does

The git_steering gem:
- Scans installed gems' `.kiro/steering/` directories for steering files
- Scans `vendor/*/.kiro/steering/` for steering files from vendor gems
- Scans `submodules/*/.kiro/steering/` for steering files from submodules
- Creates symlinks in `.kiro/steering/` pointing to these files
- Updates existing symlinks if sources change
- Deletes broken or orphaned symlinks
- Skips regular files (non-symlinks) to avoid overwriting manual content

### Priority Rules

When the same filename exists in both locations:
- **Vendor gems take priority** over submodules
- Regular files (non-symlinks) are never overwritten

### Common Options

Preview changes without applying them:
```bash
bin/git_steering symlink_build --dry-run
```

Specify a custom project root:
```bash
bin/git_steering symlink_build --project-root /path/to/project
```

### Integration with Development Workflow

Run this command when:
- Installing or updating gems with steering files
- Adding new vendor gems with steering files
- Updating submodules that contain steering files
- Setting up a new development environment
- Steering files are missing or broken

### Example Output

```
=== Building Symlinks ===
✓ Created: 3 files
  + architecture.md
  + coding_standards.md
  + testing_guide.md
↻ Updated: 1 file
  ↻ deployment.md
✗ Deleted: 1 broken symlink
  ✗ old_rule.md

Total symlinks: 12
```

### Directory Structure

```
project/
├── [gem_install_path]/
│   └── some_gem/.kiro/steering/
│       └── gem_rule.md
├── vendor/
│   └── another_gem/.kiro/steering/
│       └── vendor_rule.md
├── submodules/
│   └── some_module/.kiro/steering/
│       └── module_rule.md
└── .kiro/steering/
    ├── gem_rule.md -> [symlink to installed gem]
    ├── vendor_rule.md -> ../../vendor/another_gem/.kiro/steering/vendor_rule.md
    └── module_rule.md -> ../../submodules/some_module/.kiro/steering/module_rule.md
```

### Version

Current version: 0.1.0

Check version: `bin/git_steering version`
