---
description: Update documentation and context files with session learnings, prune obsolete info
---

# Task

Update project documentation (README, AGENTS.md, CLAUDE.md) with pertinent information from the current session and remove outdated or irrelevant content.

# Instructions

## 1. Review Current Session

Analyze the conversation history to identify:
- **New patterns or approaches** discovered
- **Configuration changes** made (Nix modules, Home Manager, etc.)
- **Commands or workflows** established
- **Solutions to problems** that took multiple attempts
- **Architecture changes** or new organizational patterns
- **Deprecated approaches** that no longer work
- **User preferences** that emerged

## 2. Update AGENTS.md

**Location:** `${XDG_CONFIG_HOME:-$HOME/.config}/AGENTS.md` (or project-specific location)

**Read the file first**, then update:

### Add New Information:
- New architectural patterns (e.g., "Declarative First" if discovered)
- New dependency tiers (e.g., how packages are managed)
- New workflows or change protocols
- Tool discoveries (e.g., "Claude Code can now read symlinks")
- Module organization changes

### Remove Obsolete Information:
- Outdated workarounds no longer needed
- Deprecated tools or approaches
- Incorrect assumptions or patterns
- Stale examples that no longer apply

### Guidelines:
- Keep the document's existing structure and voice
- Be concise but comprehensive
- Include specific examples and file paths
- Maintain the "single source of truth" philosophy

## 3. Update CLAUDE.md

**Location:** `${XDG_CONFIG_HOME:-$HOME/.config}/CLAUDE.md` (project) and `~/.claude/CLAUDE.md` (global)

**Read both files first**, then update:

### Add New Information:
- New user preferences discovered (coding style, commit format, etc.)
- New tools or commands the user prefers
- Workflow preferences (e.g., "ALWAYS use symlinks, not copying")
- Quality standards (e.g., "SLOW tests are bad tests")
- Git workflow preferences

### Remove Obsolete Information:
- Outdated tool versions or approaches
- Superseded preferences
- Contradictory instructions (keep the most recent)

### Guidelines:
- Preserve the user's voice and instruction style
- Keep instructions clear and imperative
- Organize by category (Tools, Workflow, Git, etc.)
- Use UPPERCASE for emphasis where user has established that pattern

## 4. Update Project Documentation

**Common files:** README.md, docs/, CHANGELOG.md

**Read relevant files first**, then update:

### Add New Information:
- New features or capabilities added this session
- Configuration changes users should know about
- New commands or scripts available
- Updated installation or setup steps

### Remove Obsolete Information:
- Features that were removed
- Deprecated configuration options
- Outdated setup instructions
- Incorrect or superseded information

### Guidelines:
- Match the existing documentation style
- Keep README concise, link to detailed docs
- Update examples to reflect current state
- Ensure all links and references are valid

## 5. Verification

After updates:
- Read through changes to ensure coherence
- Verify no critical information was lost
- Check that examples and paths are accurate
- Ensure documentation is internally consistent

## 6. Summary

Provide a clear summary:
- **Files updated:** List all files modified
- **Key additions:** Major new information added
- **Information pruned:** What was removed and why
- **Recommendations:** Suggest any additional documentation needs

# Important Considerations

- **Be conservative with removals:** When in doubt, keep information
- **Preserve context:** Don't remove "why" explanations, only "how" that changed
- **Check before deleting sections:** Large sections likely have value
- **Maintain document structure:** Don't reorganize unless clearly needed
- **Version-specific info:** Keep version markers (e.g., "As of 2025")

# Example Session Learnings

If this session discovered:
- "Claude Code can now read symlinks" → Update AGENTS.md to remove workaround section
- "User prefers atomic commits" → Add to CLAUDE.md Git Guidelines
- "New slash commands added" → Update README with command list
- "Nix flake structure changed" → Update AGENTS.md architecture section

# Output Format

```markdown
## Documentation Updates

### AGENTS.md
**Added:**
- Section on [new pattern]
- Example of [new workflow]

**Removed:**
- Outdated workaround for [old problem]
- Deprecated [old approach]

### CLAUDE.md
**Added:**
- Preference: [new preference]
- Workflow: [new workflow]

**Removed:**
- Contradictory instruction about [topic]

### README.md
**Added:**
- Documentation for [new feature]

**Updated:**
- Installation steps to reflect [change]

### Recommendations
- Consider adding section on [topic]
- Example code in [file] could use update
```
