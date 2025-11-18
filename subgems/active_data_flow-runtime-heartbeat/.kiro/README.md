# Heartbeat Runtime .kiro Directory

This directory contains specifications and steering guidelines for the heartbeat runtime subgem.

## Structure

```
.kiro/
├── specs/
│   ├── design.md              # Heartbeat-specific design (new)
│   ├── requirements.md        # Heartbeat-specific requirements (existing)
│   ├── tasks.md               # Heartbeat-specific tasks (new)
│   ├── parent_requirements.md # Symlink to parent requirements
│   ├── parent_design.md       # Symlink to parent design
│   ├── fromParent/            # Information from parent to this subgem
│   └── toParent/              # Information from this subgem to parent
├── steering/
│   ├── glossary.md            # Symlink to parent glossary
│   ├── product.md             # Symlink to parent product overview
│   ├── structure.md           # Symlink to parent structure
│   ├── tech.md                # Symlink to parent tech stack
│   ├── design_gem.md          # Symlink to parent gem design guidelines
│   ├── dry.md                 # Symlink to parent DRY principles
│   └── test_driven_design.md  # Symlink to parent testing guidelines
└── README.md                  # This file
```

## File Organization

### Symbolic Links

Files linked to parent (active_data_flow) documentation:
- **steering/** - All steering files are symlinked to maintain consistency
- **specs/parent_*.md** - Reference links to parent specs for context

### Subgem-Specific Files

Files specific to the heartbeat runtime:
- **specs/design.md** - Heartbeat runtime architecture and implementation details
- **specs/requirements.md** - Heartbeat-specific requirements (already exists)
- **specs/tasks.md** - Implementation tasks for heartbeat runtime

### Communication Directories

- **specs/fromParent/** - Parent project communicates requirements/constraints to subgem
- **specs/toParent/** - Subgem communicates capabilities/dependencies to parent

## Usage

When working on the heartbeat runtime:

1. **Read parent context**: Check symlinked files for overall project guidelines
2. **Focus on subgem specs**: Work with design.md, requirements.md, tasks.md
3. **Follow parent guidelines**: Steering files provide consistent development practices
4. **Update communication**: Use fromParent/toParent for coordination

## Rationale

This structure follows the DRY principle:
- Shared guidelines are symlinked (single source of truth)
- Subgem-specific details are in dedicated files
- Clear separation between parent and subgem concerns
- Easy navigation between parent and subgem documentation
