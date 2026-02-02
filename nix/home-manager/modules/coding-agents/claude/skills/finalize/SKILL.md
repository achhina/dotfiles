---
name: finalize
description: Prepare development work for commit with quality gates
disable-model-invocation: true
allowed-tools:
  - Task(@TDD_WORKFLOWS_AGENT@)
  - Skill(@SUPERPOWERS_DEBUGGING@)
  - Skill(comments)
  - Skill(commit)
  - Bash(git *)
  - Bash(npm *)
  - Bash(pytest *)
  - Bash(cargo test *)
  - Bash(go test *)
  - Bash(make test)
  - Bash(just test)
  - Read
  - Grep
  - Glob
---

# Finalize Development Work

Ensure all changes meet quality standards before committing.

## Purpose

When work is complete, verify it meets quality gates: tests pass, code is reviewed, comments are clean, and the commit is meaningful. This skill defines success criteria, not prescriptive steps.

## Quality Gates

All gates must pass before committing:

1. **Tests Pass**
   - Run the appropriate test command for this project
   - Fix any failures before proceeding
   - If debugging is needed, use the @SUPERPOWERS_DEBUGGING@ skill

2. **Code Quality**
   - Review changes for security, performance, and best practices
   - Use the @TDD_WORKFLOWS_AGENT@ agent if significant changes were made
   - Address critical issues; document minor issues for later

3. **Clean Comments**
   - Remove obvious and redundant comments
   - Use the /comments skill if code has spurious comments
   - Skip if comments are already clean

4. **Meaningful Commit**
   - Create a descriptive commit message focused on "why"
   - Use the /commit skill
   - Follow conventional commit format

## Process Guidelines

**Determine test command:**
- Check for test scripts in package.json, pytest.ini, go.mod, Cargo.toml, or Makefile
- Run the detected test command
- If tests fail, analyze errors and fix root causes

**Code review approach:**
- For significant changes, use Task tool with subagent_type="@TDD_WORKFLOWS_AGENT@"
- Focus on security vulnerabilities, logic errors, and maintainability
- Apply fixes and re-run tests to verify

**Flexibility:**
- Adapt the workflow based on what changed
- Small typo fixes don't need full code review
- If tests are already passing, verify and move on
- Skip steps that don't apply to the current changes

## Stop Conditions

Halt the workflow if:
- Tests fail after debugging attempt
- Critical security or logic issues cannot be auto-fixed
- No changes to commit (report this as successful completion)
- Pre-commit hooks fail (analyze, fix, retry)

## Success Criteria

Work is ready to commit when:
- All tests pass
- No critical code quality issues remain
- Spurious comments are removed
- A meaningful commit is created

The goal is polished, reviewed, tested work - not rigid process adherence.
