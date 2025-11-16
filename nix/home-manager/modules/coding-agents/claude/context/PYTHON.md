# Python Development Principles

## Code Style

### Import Organization

- Always place imports at the top of the module, not within function scope
- Group imports in order: standard library, third-party, local
- Use absolute imports over relative imports
- Avoid wildcard imports (`from module import *`)
- One import per line for clarity

## Type Hints

### Static Typing

- Use type hints for function signatures
- Annotate return types explicitly
- Use `typing` module for complex types (List, Dict, Optional, Union)
- Leverage `typing.Protocol` for structural subtyping
- Run `ty`, `pyrefly`, or `basedpyright` for type checking

## Project

### Project Manager

Use `uv` as the project manager for all Python projects. Always use `uv` commands when working within a project for installing dependencies, managing virtual environments, and running tasks.

### Structure

#### Package Organization

```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── core/
│       ├── utils/
│       └── tests/
├── tests/
├── pyproject.toml
├── README.md
└── .gitignore
```

Use the src/ layout to prevent implicit imports from the current working directory during development. Without src/, Python can accidentally import files and paths from your project root, causing code to work locally but fail when packaged and distributed. The src/ structure enforces proper package installation and ensures your code works the same way in development and production.

#### Configuration Files

- Use `pyproject.toml` for project metadata and tool configuration
- Define dependencies in `pyproject.toml` (not requirements.txt for packages)
- Lock dependencies for reproducible builds

## Testing

### pytest Best Practices

- Use pytest as the testing framework
- Organize tests to mirror source structure
- Use fixtures for test setup and teardown
- Name tests descriptively: `test_<what>_<condition>_<expected>`
- Use parametrize for testing multiple inputs

### Test Coverage

- Aim for high test coverage (>80%)
- Test edge cases and error conditions
- Use `pytest-cov` to measure coverage
- Don't just chase coverage numbers; write meaningful tests

## Error Handling

### Exception Practices

- Use specific exception types, not bare `except:`
- Create custom exceptions for domain-specific errors
- Use context managers for resource management
- Fail fast and provide clear error messages

### Example

```python
class ValidationError(Exception):
    """Raised when data validation fails."""
    pass

def validate_input(data: str) -> None:
    if not data:
        raise ValidationError("Input cannot be empty")
```

## Tooling

### Linting and Formatting

- Use `ruff` for linting and formatting (replaces black, isort, flake8)
- Use `ty`, `pyrefly`, or `basedpyright` for type checking (replacements for mypy and pyright)

### Virtual Environments

- Always use virtual environments for projects
- Use `uv sync` if the project is already initialized
- Use `uv init` if the project is not yet initialized

## Data Classes and Models

### When to Use Each

- Use **Data Classes** for DTOs (Data Transfer Objects) and handling data within the application
- Use **Pydantic** when validating data and serializing it across boundaries (APIs, config files, external systems)

### Data Classes

```python
from dataclasses import dataclass

@dataclass
class User:
    """Internal user representation."""
    name: str
    email: str
    age: int
```

### Pydantic for Validation and Serialization

- Use Pydantic for data validation and settings management
- Leverage automatic type coercion and validation
- Define clear schemas for external data
- Use `BaseModel` for data crossing boundaries

### Example

```python
from pydantic import BaseModel, Field, validator

class UserInput(BaseModel):
    """Validate user input from API."""
    name: str
    email: str
    age: int = Field(..., gt=0, lt=150)

    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email')
        return v
```

## Async Programming

### asyncio Best Practices

- Use `async`/`await` for I/O-bound operations
- Don't mix blocking and async code
- Use `asyncio.gather()` for concurrent tasks
- Handle exceptions in async code properly
- Use `asyncio.run()` as the entry point

### Async Patterns

```python
import asyncio

async def fetch_data(url: str) -> dict:
    """Async function to fetch data."""
    pass

async def main():
    results = await asyncio.gather(
        fetch_data("url1"),
        fetch_data("url2"),
        fetch_data("url3"),
    )
    return results
```

## Performance

### Optimization Guidelines

- Use generators for large datasets
- Leverage list comprehensions over loops
- Use `__slots__` for classes with many instances
- Profile with `cProfile` before optimizing
- Consider `numpy` for numerical computations

### Memory Management

- Use context managers for file handling
- Close resources explicitly when not using context managers
- Be mindful of circular references
- Use `weakref` when appropriate

## Documentation

### Docstrings

- Use NumPy style docstrings only
- Document all public functions, classes, and modules
- Include type information in docstrings
- Provide usage examples for complex functions

### Example (NumPy Style)

```python
def calculate_total(items: List[float], tax_rate: float = 0.1) -> float:
    """Calculate total price including tax.

    Parameters
    ----------
    items : List[float]
        List of item prices
    tax_rate : float, optional
        Tax rate as decimal (default: 0.1)

    Returns
    -------
    float
        Total price including tax

    Raises
    ------
    ValueError
        If tax_rate is negative

    Examples
    --------
    >>> calculate_total([10.0, 20.0], 0.1)
    33.0
    """
    if tax_rate < 0:
        raise ValueError("Tax rate cannot be negative")
    subtotal = sum(items)
    return subtotal * (1 + tax_rate)
```

## Security

### Common Vulnerabilities

- Never use `eval()` or `exec()` on user input
- Use parameterized queries for database access
- Validate and sanitize all input data

## Python Version

### Modern Python Features

- Target Python 3.12+ for new projects
- Use structural pattern matching (match/case) when appropriate
- Use positional-only and keyword-only parameters
- Take advantage of improved error messages

## Logging

### Structured Logging

- Use `structlog` if possible for structured logging in production systems
- Falls back to standard `logging` module when structlog is not available

### Logging Architecture

Understand the powerful logging abstractions:

- **Logger**: Named channel for emitting log records (e.g., `logger.info()`, `logger.error()`)
- **Handler**: Determines where logs go (console, file, syslog, etc.)
- **Formatter**: Controls log output format (text, JSON, etc.)
- **Filter**: Allows fine-grained control over which log records are processed

### Logging Levels

Use `logging.getLevelNamesMapping()` (Python 3.11+) to get a mapping of level names to their numeric values without creating your own DTO:

```python
import logging
level_mapping = logging.getLevelNamesMapping()
# Returns: {'CRITICAL': 50, 'ERROR': 40, 'WARNING': 30, 'INFO': 20, 'DEBUG': 10, 'NOTSET': 0, ...}
```

### Configuration Best Practices

- Configure logging in ONE location (typically application entry point)
- Retrieve configured loggers elsewhere using `logging.getLogger(__name__)`
- Never configure handlers in library code
- Libraries should use `logging.getLogger(__name__)` without adding handlers

### Library Logging

- Libraries should NOT modify the root handler
- Attach a NullHandler on init so users can opt-in to see library logs:
  ```python
  import logging
  logging.getLogger(__name__).addHandler(logging.NullHandler())
  ```

### Example (Application Entry Point)

Create a logging utility module for configuration, then configure once at entry point:

```python
# utils/logging_config.py - Logging configuration module
import logging

def configure_logging():
    """Configure logging for the entire application."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    try:
        import structlog
        structlog.configure(
            processors=[
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer(),
            ],
            logger_factory=structlog.stdlib.LoggerFactory(),
        )
    except ImportError:
        pass
```

```python
# main.py - Application entry point
from utils.logging_config import configure_logging

if __name__ == "__main__":
    configure_logging()
```

## Recommended Libraries

### CLI Applications

Use **Click** for building command-line interfaces:

- Decorator-based approach makes code clean and declarative
- Automatic help generation from function docstrings
- Automatic shell completion generation (bash, zsh, fish)
- Built-in support for environment variables
- Composable and extensible for complex multi-command CLIs
