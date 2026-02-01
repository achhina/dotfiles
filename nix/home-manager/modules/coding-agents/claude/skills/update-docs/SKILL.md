---
name: update-docs
description: Update documentation with session learnings and prune obsolete info. Use after significant changes, at session end, or when new patterns/approaches are discovered.
---

# Update Documentation

Update project documentation with pertinent information from the current session and remove outdated or irrelevant content.

## Purpose

After making significant changes or discovering new patterns, documentation should be updated to reflect the current state. This skill analyzes the session and updates `.local.md` files with new learnings while pruning obsolete information.

## When to Use

Claude should invoke this skill when:
- A session involved significant architectural changes
- New patterns or approaches were discovered
- Configuration was substantially modified
- Workflows were established or changed
- Solutions to complex problems were found
- Deprecated approaches were identified
- At the end of long, productive sessions

## Instructions

### 1. Review Current Session

Analyze the conversation history to identify:
- **New patterns or approaches** discovered
- **Configuration changes** made (Nix modules, Home Manager, etc.)
- **Commands or workflows** established
- **Solutions to problems** that took multiple attempts
- **Architecture changes** or new organizational patterns
- **Deprecated approaches** that no longer work
- **User preferences** that emerged

### 2. Update AGENTS.local.md

**Location:** `${XDG_CONFIG_HOME:-$HOME/.config}/AGENTS.local.md`

Read the file first (create if it doesn't exist), then update:

#### Add New Information:
- New architectural patterns discovered
- New dependency management approaches
- New workflows or change protocols
- Tool discoveries or capability changes
- Module organization changes
- Project-specific conventions

#### Remove Obsolete Information:
- Outdated workarounds no longer needed
- Deprecated tools or approaches
- Incorrect assumptions or patterns
- Stale examples that no longer apply

#### Guidelines:
- Keep the document's existing structure and voice
- Be concise but comprehensive
- Include specific examples and file paths
- Maintain the "single source of truth" philosophy
- Use version markers (e.g., "As of 2025")

### 3. Update CLAUDE.local.md

**Location:** `${XDG_CONFIG_HOME:-$HOME/.config}/CLAUDE.local.md`

Read the file first (create if it doesn't exist), then update:

#### Add New Information:
- New user preferences discovered (coding style, commit format, etc.)
- New tools or commands the user prefers
- Workflow preferences
- Quality standards
- Git workflow preferences

#### Remove Obsolete Information:
- Outdated tool versions or approaches
- Superseded preferences
- Contradictory instructions (keep the most recent)

#### Guidelines:
- Preserve the user's voice and instruction style
- Keep instructions clear and imperative
- Organize by category (Tools, Workflow, Git, etc.)
- Use UPPERCASE for emphasis where established

### 4. Update Project Documentation (Optional)

**Common files:** README.md, docs/, CHANGELOG.md

Only update these if session changes affect user-facing documentation:

#### Add New Information:
- New features or capabilities added this session
- Configuration changes users should know about
- New commands or scripts available
- Updated installation or setup steps

#### Remove Obsolete Information:
- Features that were removed
- Deprecated configuration options
- Outdated setup instructions
- Incorrect or superseded information

#### Guidelines:
- Match the existing documentation style
- Keep README concise, link to detailed docs
- Update examples to reflect current state
- Ensure all links and references are valid

### 5. Verification

After updates:
- Read through changes to ensure coherence
- Verify no critical information was lost
- Check that examples and paths are accurate
- Ensure documentation is internally consistent

### 6. Summary

Provide a clear summary:
- **Files updated:** List all files modified
- **Key additions:** Major new information added
- **Information pruned:** What was removed and why
- **Recommendations:** Suggest any additional documentation needs

## Important Considerations

- **Be conservative with removals:** When in doubt, keep information
- **Preserve context:** Don't remove "why" explanations, only "how" that changed
- **Check before deleting sections:** Large sections likely have value
- **Maintain document structure:** Don't reorganize unless clearly needed
- **Version-specific info:** Keep version markers

## Example Session Learnings

If this session discovered:
- "Slash commands merged into skills" → Add to AGENTS.local.md
- "User prefers atomic commits" → Add to CLAUDE.local.md
- "New `/learn` skill added" → Update README with command list
- "Nix module reorganization" → Update AGENTS.local.md architecture section

## Output Format

```markdown
## Documentation Updates

### AGENTS.local.md
**Added:**
- Section on [new pattern]
- Example of [new workflow]

**Removed:**
- Outdated workaround for [old problem]

### CLAUDE.local.md
**Added:**
- Preference: [new preference]
- Workflow: [new workflow]

**Removed:**
- Contradictory instruction about [topic]

### README.md (if applicable)
**Added:**
- Documentation for [new feature]

**Updated:**
- Installation steps to reflect [change]

### Recommendations
- Consider adding section on [topic]
```
