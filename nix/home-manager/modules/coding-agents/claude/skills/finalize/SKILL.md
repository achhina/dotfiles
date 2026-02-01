---
name: finalize
description: This skill should be used when the user asks to "finalize", "/finalize", "ship it", "ship this", "wrap up", "wrap this up", or "finish and commit". Orchestrates the complete workflow for finishing development work including running tests, code review, comment cleanup, and creating a commit.
version: 0.1.0
---

# Finalize Development Work

This skill orchestrates the complete workflow for finishing development work by running tests, performing code review, cleaning up comments, and creating a well-thought-out commit.

## Purpose

When development work is complete, finishing properly requires several quality gates: verifying tests pass, reviewing code quality, removing spurious comments, and creating a meaningful commit. This skill automates this multi-step workflow to ensure consistent quality before committing changes.

## When to Use

Use this skill when the user indicates work is ready to be finalized and committed:

- "finalize" or "/finalize"
- "ship it" or "ship this"
- "wrap up" or "wrap this up"
- "finish and commit"

## Workflow Steps

Execute the following steps in order, stopping only if a critical failure occurs that cannot be automatically resolved.

### Step 1: Run Tests

Detect and run the appropriate test command for the project:

**Detection priority:**
1. Check for `package.json` with test script → use `npm test`
2. Check for `pytest.ini`, `pyproject.toml`, or `.py` test files → use `pytest`
3. Check for `go.mod` → use `go test ./...`
4. Check for `Cargo.toml` → use `cargo test`
5. Check for `Makefile` with test target → use `make test`

**Execution:**
```bash
# Run the detected test command
<detected-test-command>
```

**On test failure:**
1. Do not proceed with remaining steps
2. Invoke the `superpowers:systematic-debugging` skill to analyze and fix the failures
3. After fixes are applied, re-run tests to verify they pass
4. If tests still fail after debugging attempt, report to user and halt
5. Only proceed to Step 2 when all tests pass

### Step 2: Code Review

Invoke the TDD workflows code-reviewer agent to analyze recent changes:

**Determine review scope:**
```bash
# Get list of modified files for review
git diff --name-only
```

**Run code review:**
Use the Task tool with `subagent_type="tdd-workflows:code-reviewer"` for comprehensive analysis:

```
Use Task tool:
- subagent_type: "tdd-workflows:code-reviewer"
- prompt: "Review the uncommitted changes for security vulnerabilities, performance issues, code quality, and best practices"
```

This elite code reviewer provides comprehensive analysis covering:
- AI-powered code analysis and modern static analysis tools
- Security vulnerabilities (OWASP Top 10, injection attacks, secrets, cryptography)
- Performance issues (algorithms, database queries, memory leaks, caching)
- Code quality (Clean Code, SOLID, DRY, maintainability, complexity)
- Error handling and resilience patterns
- Testing coverage and testability
- Configuration and infrastructure security
- Modern development practices (TDD, feature flags, observability)

**On review findings:**
- Analyze all code review comments and issues identified
- Apply fixes for all issues found (style violations, potential bugs, best practice deviations)
- Re-run tests after applying fixes to ensure nothing breaks
- If any fixes cannot be automatically applied, report to user and halt
- Only proceed to Step 3 when all review issues are resolved and tests still pass

### Step 3: Remove Spurious Comments

Invoke the comments skill to clean up obvious and redundant comments:

```
Use Skill tool: skill="comments"
```

The `/comments` skill launches the `comment-remover` agent which will:
- Scan uncommitted changes for obvious comments
- Remove redundant and self-evident comments
- Preserve valuable documentation (TODO/FIXME, "why" explanations, docstrings)
- Runs in isolated context to reduce main conversation context usage

### Step 4: Create Commit

Invoke the commit skill to create a well-thought-out commit message:

```
Use Skill tool: skill="commit"
```

The `/commit` skill will:
- Analyze all changes (git diff and git status)
- Review recent commit messages for style consistency
- Draft a meaningful commit message focused on the "why"
- Create the commit with staged changes

## Error Handling

**Test failures:**
- Attempt automatic fix using systematic-debugging skill
- Verify fix with test re-run
- Halt if tests still fail after debugging

**Code review issues:**
- Analyze all findings from the comprehensive code review
- Apply fixes for all identified issues (security, performance, style, logic)
- Re-run full test suite after applying fixes
- Halt if critical issues cannot be auto-fixed
- Ensure all high-priority review feedback is addressed before proceeding

**Comment cleanup:**
- Non-critical, proceed even if no comments removed

**Commit creation:**
- If no changes to commit, report and complete successfully
- If pre-commit hooks fail, analyze and fix issues, then retry commit

## Success Criteria

The workflow completes successfully when:
1. All tests pass
2. Code review finds no critical issues (or issues are fixed)
3. Spurious comments are removed
4. A commit is created with a meaningful message

## Notes

- This workflow assumes work is complete and ready to commit
- Each step builds on the previous step's success
- Test failures trigger debugging, not just reporting
- Code quality gates prevent committing problematic code
- The final commit represents polished, reviewed, tested work
