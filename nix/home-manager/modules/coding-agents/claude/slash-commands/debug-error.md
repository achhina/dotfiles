---
description: Systematically debug and fix errors with guided workflow
---

Systematically debug and fix the error using this approach:

1. **Understand the Error**
   - Read the full error message and stack trace
   - Identify the error type and location
   - Note any relevant context from the error output

2. **Reproduce the Issue**
   - Identify the steps or conditions that trigger the error
   - Verify the error is reproducible
   - Note any patterns or edge cases

3. **Investigate Root Cause**
   - Examine the code at the error location
   - Check recent changes that might have introduced the issue
   - Review related code paths and dependencies
   - Look for common issues (null references, type mismatches, logic errors)

4. **Propose Solution**
   - Explain the root cause clearly
   - Suggest one or more fix approaches
   - Consider edge cases and side effects
   - Discuss trade-offs if multiple solutions exist

5. **Implement Fix**
   - Apply the chosen solution
   - Add defensive checks if appropriate
   - Update error handling if needed

6. **Verify Fix**
   - Test that the error no longer occurs
   - Run existing tests to ensure no regressions
   - Test edge cases

Arguments: $ARGUMENTS (optional: error message, file path, or description)

Please be thorough and methodical. If you need more information, ask before proceeding.
