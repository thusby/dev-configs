# Model Selection Strategy

**Last Updated:** 2025-11-13

---

## Critical Skills: Use Haiku

All autonomous skills in this ecosystem use **Haiku** as orchestrator for critical operations.

### Rationale

1. **Critical Functionality**
   - Git operations (commit, push, branch management)
   - Secret management (Age encryption, YubiKey integration)
   - Project setup (directory creation, Claude settings, git init)

2. **Ecosystem Complexity**
   - 5 main components (dotfiles, dev-configs, chezmoi, secrets, projects)
   - 3 repositories to coordinate
   - Age + YubiKey workflow integration

3. **Cost vs Risk Analysis**
   - Haiku cost: $0.80/million input tokens
   - Typical orchestrator run: ~$0.004 (less than 1 cent)
   - Cost of fixing errors from unreliable model: 15-30 min debugging + frustration + data loss risk

**Conclusion:** Saving $0.01 is not worth the risk of breaking critical workflows.

---

## Skills Using Haiku

All 3 active skills specify `model: haiku` in their frontmatter:

| Skill | Purpose | Why Haiku |
|-------|---------|-----------|
| **sync-check** | Morning sync verification | Git status, secrets check, critical reporting |
| **project-setup** | Project initialization | Directory creation, git init, Claude settings |
| **sync-orchestrator** | Evening multi-repo sync | Git operations across multiple repos |

---

## When to Use Local Models

Local models (Codestral, DeepSeek, etc.) are appropriate for:

### ✅ Safe Use Cases

- **Code completion** in editor (Continue/Cursor)
- **Rapid prototyping** of bash scripts (non-critical)
- **Boilerplate generation** (.env.example, README templates)
- **Interactive debugging** (non-destructive exploratory commands)
- **Documentation** drafting and editing

### ❌ Avoid Local Models For

- Autonomous git operations (commit, push, reset)
- Secret/credential management
- Multi-repo orchestration
- Critical file operations (rm, mv of important files)
- Production deployments

---

## Cost Analysis

### Typical Orchestrator Run

```
Input:  ~5000 tokens (documentation + context)
Output: ~1000 tokens (commands + explanation)
Cost:   ~$0.004 with Haiku (< 1 cent)
```

### Monthly Estimate

Assuming 20 project setups + 40 morning/evening routines per month:

```
60 runs × $0.004 = $0.24/month
$2.88/year
```

**ROI:** One avoided git disaster or secret leak saves 100x this cost in time and stress.

---

## Implementation

Skills specify model in frontmatter:

```yaml
---
name: project-setup
description: |
  Sets up new projects from new-project command.
model: haiku
allowed-tools:
  - Bash
  - Read
---
```

This ensures:
- Fast execution (Haiku optimized for speed)
- High reliability for critical operations
- Negligible cost (~$0.004 per run)
- Consistent behavior across environments

---

## Future Considerations

If/when more capable local models emerge:
- Re-evaluate for non-critical operations
- Keep Haiku for git/secrets/orchestration
- Document any local model experiments in this file

**Principle:** Reliability > Cost savings for critical infrastructure.

---

**Maintained by:** Terje Husby + Claude Code
**Repository:** dev-configs
