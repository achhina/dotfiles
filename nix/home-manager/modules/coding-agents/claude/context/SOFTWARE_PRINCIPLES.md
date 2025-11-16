# Software Engineering Principles

## Language-Specific Guides

When working on projects/files written in Python, read ./PYTHON.md for Python-specific best practices and principles.

## Code Quality

### DRY (Don't Repeat Yourself)

- Extract duplicate code into reusable functions, classes, or modules
- Use abstractions to eliminate repetition
- Prefer composition over duplication

### Clean Code

- Write self-documenting code with clear naming
- Keep functions small and focused on a single responsibility
- Maintain consistent code style and formatting
- Remove dead code and unused imports

### Test-Driven Development (TDD)

- Write tests before implementation
- Follow the red-green-refactor cycle:
  1. Write a failing test (red)
  2. Write minimal code to pass the test (green)
  3. Refactor while keeping tests green
- Avoid mock implementations; use real implementations when practical

## Architecture

### SOLID Principles

- **Single Responsibility**: Each module/class should have one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Subtypes must be substitutable for base types
- **Interface Segregation**: Many specific interfaces over one general interface
- **Dependency Inversion**: Depend on abstractions, not concretions

### Separation of Concerns

- Separate business logic from presentation
- Keep infrastructure concerns isolated
- Use layered architecture when appropriate

## Security

### Input Validation

- Validate and sanitize all user input
- Use parameterized queries to prevent SQL injection
- Escape output to prevent XSS attacks
- Implement proper authentication and authorization

## Performance

### Optimization Strategy

- Measure before optimizing
- Focus on algorithmic efficiency first
- Profile to find bottlenecks
- Optimize the critical path

### Resource Management

- Close resources properly (files, connections, etc.)
- Use connection pooling where appropriate
- Implement caching strategically
- Be mindful of memory allocations

## Error Handling

### Defensive Programming

- Expect and handle errors gracefully
- Validate assumptions with assertions
- Provide meaningful error messages
- Log errors with sufficient context

### Fail Fast

- Detect errors early
- Don't hide failures
- Use exceptions for exceptional conditions
- Return errors explicitly when appropriate

## Documentation

### Code Comments

- Comment the "why", not the "what"
- Keep comments up-to-date with code changes
- Use docstrings for public APIs
- Avoid obvious or redundant comments

## Version Control

### Commit Practices

- Make atomic commits (one logical change per commit)
- Write clear, descriptive commit messages
- Explain the "why" in commit messages
- Keep commits small and focused

## Type Safety

### Static Typing

- Use type annotations where available
- Leverage type checkers (mypy, TypeScript, etc.)
- Define clear interfaces and contracts
- Avoid `any` or dynamic types when possible

### Runtime Validation

- Validate types at boundaries
- Use schema validation for external data
- Implement runtime type checking for critical paths
