{
  # Claude Code settings configuration
  # Managed declaratively through Home Manager

  programs.claude-code = {
    enable = true;

    commands = {
      debug-error = ''
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
      '';

      code-review = ''
        Perform a comprehensive code review using the following structured approach:

        ## 1. Code Quality & Maintainability
        - **Readability**: Is the code clear and self-documenting?
        - **Complexity**: Are functions/methods appropriately sized and focused?
        - **Naming**: Do names accurately describe purpose and intent?
        - **Comments**: Are complex logic sections explained? Are comments up-to-date?
        - **DRY Principle**: Is there unnecessary code duplication?
        - **SOLID Principles**: Does the code follow good design principles?

        ## 2. Security Analysis
        - **Input Validation**: Are all user inputs properly validated and sanitized?
        - **Authentication/Authorization**: Are access controls properly implemented?
        - **Data Exposure**: Are sensitive data (passwords, tokens, keys) properly protected?
        - **Injection Vulnerabilities**: Check for SQL injection, XSS, command injection risks
        - **Dependencies**: Are there known vulnerabilities in dependencies?
        - **Secrets**: Are there hardcoded credentials or API keys?

        ## 3. Performance & Efficiency
        - **Algorithms**: Are appropriate data structures and algorithms used?
        - **Database Queries**: Are queries optimized? Any N+1 query issues?
        - **Memory Management**: Are there potential memory leaks or excessive allocations?
        - **Caching**: Should caching be used? Is existing caching appropriate?
        - **Async Operations**: Are blocking operations handled properly?

        ## 4. Error Handling & Resilience
        - **Exception Handling**: Are errors caught and handled appropriately?
        - **Error Messages**: Are error messages informative without exposing sensitive data?
        - **Edge Cases**: Are boundary conditions and edge cases handled?
        - **Graceful Degradation**: Does the code handle failures gracefully?

        ## 5. Testing & Testability
        - **Test Coverage**: Are there tests for the changed code?
        - **Test Quality**: Do tests cover edge cases and failure scenarios?
        - **Testability**: Is the code structured to be easily testable?
        - **Mocking**: Are external dependencies properly isolated in tests?

        ## 6. Style & Conventions
        - **Coding Standards**: Does the code follow project conventions?
        - **Formatting**: Is formatting consistent?
        - **Linting**: Are there linter warnings or errors?
        - **Type Safety**: Are types used appropriately (if applicable)?

        ## 7. Documentation & Communication
        - **API Documentation**: Are public interfaces documented?
        - **README Updates**: Does documentation reflect the changes?
        - **Breaking Changes**: Are breaking changes clearly documented?
        - **Migration Guide**: Are migration steps provided if needed?

        ## Output Format
        Provide findings in the following structure:
        - **Summary**: High-level overview of changes and overall quality
        - **Critical Issues**: Security vulnerabilities or bugs that must be fixed
        - **Major Concerns**: Significant problems that should be addressed
        - **Minor Issues**: Suggestions for improvement
        - **Positive Observations**: What was done well
        - **Recommendations**: Specific actionable items

        Arguments: $ARGUMENTS (optional: file path, commit range, or scope)

        Be constructive and specific. Provide code examples for suggested improvements.
      '';
    };

    settings = {
      env = {
        BASH_DEFAULT_TIMEOUT_MS = "300000";
        BASH_MAX_TIMEOUT_MS = "600000";
      };

      includeCoAuthoredBy = false;

      permissions = {
        allow = [
          "Bash(cat:*)"
          "Bash(echo:*)"
          "Bash(find:*)"
          "Bash(fd:*)"
          "Bash(git add:*)"
          "Bash(git commit:*)"
          "Bash(git log:*)"
          "Bash(grep:*)"
          "Bash(head:*)"
          "Bash(hm:*)"
          "Bash(home-manager:*)"
          "Bash(just:*)"
          "Bash(ls:*)"
          "Bash(mkdir:*)"
          "Bash(nix:*)"
          "Bash(nix-channel:*)"
          "Bash(nix-shell:*)"
          "Bash(nix-collect-garbage:*)"
          "Bash(npm:*)"
          "Bash(nvim:*)"
          "Bash(sed:*)"
          "Bash(python:*)"
          "Bash(rg:*)"
          "Bash(tail:*)"
          "Bash(test:*)"
          "Bash(tmux list-:*)"
          "Bash(tmux show-:*)"
          "Bash(tmux display:*)"
          "Bash(tmux has-session:*)"
          "Bash(tmux capture-pane:*)"
          "Read"
          "WebFetch"
          "WebSearch"
          "Write"
        ];

        deny = [
          "Bash(git commit --no-verify:*)"
        ];

        additionalDirectories = [
          "~/docs"
          "/tmp"
          "~/.cache"
        ];
      };

      model = "sonnet";

      statusLine = {
        type = "command";
        command = "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); cd \"$cwd\" 2>/dev/null; git_branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \\(.*\\)/ (\\1)/'); printf \"\\033[32m$(whoami)@$(hostname -s) $(basename \"$cwd\")\${git_branch}\\033[0m\"";
      };

      alwaysThinkingEnabled = true;

      theme = "dark";

      # Plugin configuration
      extraKnownMarketplaces = {
        superpowers-marketplace = {
          source = {
            source = "github";
            repo = "obra/superpowers-marketplace";
          };
        };
      };

      enabledPlugins = {
        "superpowers@superpowers-marketplace" = true;
      };
    };
  };
}
