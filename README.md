# Development Configurations

Shared development configurations and standards for all Terje Husby projects. This repository provides reusable tooling configs that can be symlinked or imported into specific projects.

## Purpose

Centralize common configuration files to maintain consistency across projects while keeping project-specific settings in their respective repositories.

**Key Principle:** This repo contains *team/project standards*, not personal system configs (those go in `dotfiles` repo).

---

## Repository Structure

```
dev-configs/
├── python/              # Python project configurations
│   ├── pyproject-base.toml
│   ├── ruff.toml
│   ├── mypy.ini
│   └── pytest.ini
├── c-embedded/          # C/C++ embedded systems configs
│   ├── .clang-format
│   └── .editorconfig
├── javascript/          # JavaScript/TypeScript configs
│   ├── .prettierrc
│   ├── .eslintrc.js
│   └── tsconfig.json
├── devcontainers/       # DevContainer templates
│   ├── python/
│   ├── zephyr/
│   └── openvino/
├── github-workflows/    # Reusable CI/CD workflows
│   ├── python-test.yml
│   ├── docker-build.yml
│   └── ansible-lint.yml
└── git/                 # Project .gitignore templates
    ├── python.gitignore
    ├── node.gitignore
    └── c-embedded.gitignore
```

---

## Usage

### Option 1: Symlink (Recommended)

```bash
# From your project root
ln -s ../../../dev-configs/python/pyproject-base.toml pyproject.toml
ln -s ../../../dev-configs/c-embedded/.clang-format .clang-format
```

### Option 2: Import in pyproject.toml

```toml
# In your project's pyproject.toml
[tool.ruff]
extend = "../../dev-configs/python/ruff.toml"
```

### Option 3: Copy and Customize

For projects needing significant customization, copy the base config and modify as needed.

---

## Configuration Files

### Python Projects

**pyproject-base.toml** - Base Python configuration with:
- `tool.ruff` - Linting rules (line-length: 88, py311+)
- `tool.mypy` - Type checking settings
- `tool.pytest` - Test framework configuration
- `tool.black` - Code formatting (optional)

**Projects using this:**
- mcp-common (with workspace extensions)
- coordinator (with setuptools)
- localfarm backend

### C/C++ Embedded

**.clang-format** - Zephyr RTOS style:
- IndentWidth: 8, UseTab: Always
- BreakBeforeBraces: Linux
- ColumnLimit: 100

**.editorconfig** - Multi-language editor settings:
- C/C++: tabs, width 8 (Zephyr style)
- Python: spaces, width 4
- YAML: spaces, width 2

**Projects using this:**
- zephyr-meta
- Embedded board projects

### JavaScript/TypeScript

**(To be added based on future needs)**

---

## Standards Summary

| Tool | Python Projects | C/C++ Projects |
|------|----------------|----------------|
| **Line Length** | 88-100 chars | 100 chars |
| **Indentation** | 4 spaces | 8-width tabs |
| **Python Version** | ≥3.10 | N/A |
| **Type Checking** | mypy strict | N/A |
| **Linting** | ruff | clang-format |
| **Test Framework** | pytest | Shell scripts |

---

## Contributing

When updating configs:

1. **Test first** - Verify changes work in at least one project
2. **Document changes** - Update this README with rationale
3. **Version carefully** - Tool configs can break builds
4. **Announce** - Notify in commit message which projects are affected

---

## Claude Code Skills Integration

This repository includes autonomous skills for Claude Code that streamline development workflows:

### Quick Start: New Project

```bash
# Create and setup a new project automatically
new-project api-gateway go
new-project mcp-slack python
new-project iot-sensor c
```

**What happens:**
1. Signal created: `~/.cache/claude-events/project-setup-requested.json`
2. Claude Code `project-setup` skill activates
3. Project directory created with:
   - Language-specific structure (Cargo.toml for Rust, go.mod for Go, etc.)
   - Claude settings from templates
   - Git initialization
   - README template

### Daily Workflows

**Morning:** `morning` - Sync verification
- Checks dotfiles, dev-configs, secrets status
- Reports uncommitted/unpushed changes

**Evening:** `evening` - Multi-repo sync
- Shows all repos with uncommitted changes
- Auto-commits task data

See [SKILLS-STATUS.md](./SKILLS-STATUS.md) for full documentation.

---

## Projects Using These Configs

- **mcp-common** - Python/FastMCP monorepo
- **coordinator** - Multi-agent systems framework
- **localfarm** - Django/Vue.js platform
- **zephyr-meta** - Embedded systems meta-repo
- **openvino** - AI/ML inference environment

---

## Related Repositories

- **dotfiles** - Personal system configurations (shell, vim, git global)
- **pet** - Command snippet manager configs

---

## Author

**Terje Husby**
