---
description: Perform comprehensive code review with structured analysis
---

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
