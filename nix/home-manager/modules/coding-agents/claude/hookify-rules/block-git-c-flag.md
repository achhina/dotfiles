---
name: block-git-c-flag
enabled: true
event: bash
pattern: git\s+(-C|--git-dir|--work-tree)
action: block
---

🚫 **Git `-C` flag detected!**

You're attempting to use `git -C <path>` or similar directory flags (`--git-dir`, `--work-tree`).

**Why this is blocked:**
- Claude Code bash permissions are configured with git subcommand patterns like `Bash(git commit:*)`
- These patterns match commands starting with the subcommand (e.g., `git commit`)
- The `-C` flag appears BEFORE the subcommand, causing permission mismatches
- Example: `git -C /path commit` doesn't match `Bash(git commit:*)` but `git commit` does

**What to use instead:**
Since the working directory is already set to `/Users/achhina/.config`, use plain git commands:

**Good:**
```bash
git status
git add file.txt
git commit -m "message"
git push
```

**Bad:**
```bash
git -C /Users/achhina/.config status
git -C /Users/achhina/.config add file.txt
git --git-dir=/path/to/.git commit
```

**Exception:** If you genuinely need to operate on a different repository, change your working directory first with `cd`, then use normal git commands.
