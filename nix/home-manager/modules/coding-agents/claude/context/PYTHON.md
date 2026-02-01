# Python Development Principles

## Code Style

### Import Organization

- Always place imports at the top of the module, not within function scope
- Group imports in order: standard library, third-party, local
- Use absolute imports over relative imports
- Avoid wildcard imports (`from module import *`)
- One import per line for clarity

### Path and URI Handling

**File Paths**

- Use `pathlib.Path` for all file system operations
- Provides cross-platform path handling (Windows, macOS, Linux)
- Object-oriented API is more readable than string concatenation
- Works seamlessly with most standard library functions

```python
from pathlib import Path

# Good: pathlib.Path
config_file = Path("config") / "settings.json"
if config_file.exists():
    data = config_file.read_text()

# Bad: string concatenation
config_file = "config" + "/" + "settings.json"  # Breaks on Windows
```

**URLs and URIs**

- Use `urllib.parse` for URL/URI manipulation
- Never use string concatenation for building URLs
- Use `urljoin()` for combining URL components
- Use `urlparse()` for parsing and extracting URL components

```python
from urllib.parse import urljoin, urlparse, urlencode

# Good: urllib.parse
base_url = "https://api.example.com"
endpoint = urljoin(base_url, "/users/123")
params = urlencode({"format": "json", "include": "details"})
full_url = f"{endpoint}?{params}"

# Parse URLs
parsed = urlparse("https://example.com/path?query=value")
print(parsed.scheme, parsed.netloc, parsed.path)  # https example.com /path
```

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

#### Resource Loading

When using the src/ layout, the package structure during development differs from the installed wheel structure. Use `importlib.resources` (Python 3.9+) or `importlib_resources` (backport for older versions) to access package data files reliably.

**Why importlib.resources?**

- During development: `src/package_name/data/template.html`
- After installation: Files are in `site-packages/package_name/data/template.html`
- The src/ prefix disappears, but importlib.resources abstracts this difference
- Uses the package name as an anchor point to locate resources

**Loading Package Resources**

```python
from importlib.resources import files

# Read a data file from your package
def load_template(name: str) -> str:
    """Load template file from package data directory."""
    template_path = files("package_name") / "data" / "templates" / name
    return template_path.read_text()

# Access binary resources
def load_image(name: str) -> bytes:
    """Load image from package resources."""
    image_path = files("package_name") / "assets" / "images" / name
    return image_path.read_bytes()

# Get a Path-like object for resources
def get_config_path() -> Path:
    """Get path to config file in package."""
    config_file = files("package_name") / "config" / "default.json"
    # For temporary file access, use as_file context manager
    from importlib.resources import as_file
    with as_file(config_file) as path:
        return path
```

**Package Data Configuration**

Include package data in `pyproject.toml`:

```toml
[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
package_name = ["data/**/*", "templates/**/*", "config/**/*"]
```

Or use `include-package-data = true` with a MANIFEST.in file for more complex scenarios.

**Directory Structure Example**

```
src/
└── package_name/
    ├── __init__.py
    ├── core/
    │   └── engine.py
    ├── data/
    │   ├── __init__.py          # Makes data directory a package
    │   ├── templates/
    │   │   ├── __init__.py      # Optional but recommended
    │   │   └── email.html
    │   └── defaults.json
    └── assets/
        ├── __init__.py          # Makes assets directory a package
        └── logo.png
```

**Important Notes**

- Add `__init__.py` (can be empty) to data directories to make them recognizable as packages
- While optional in Python 3.3+ due to namespace packages, it's best practice for clarity and compatibility
- Never use `__file__` to locate package data - it breaks with zip imports and some deployment scenarios
- importlib.resources works with both filesystem and zip-based packages
- For Python 3.7-3.8, install `importlib-resources` backport: `uv add importlib-resources`

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

### Advanced Testing Techniques

**Property-Based Testing**

- Use `hypothesis` to automatically generate test cases and find edge cases
- Define properties that should always hold true
- Let hypothesis discover inputs that break your assumptions

```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """Addition should be commutative."""
    assert a + b == b + a
```

**Performance Testing**

- Use `pytest-benchmark` to track performance over time
- Detect performance regressions in CI/CD
- Establish performance baselines for critical code paths

```python
def test_search_performance(benchmark):
    """Ensure search stays under 100ms."""
    result = benchmark(search_function, large_dataset)
    assert benchmark.stats.mean < 0.1  # 100ms
```

**Test Data Factories**

- Use `factory_boy` for complex test data generation
- Create reusable factories instead of manual fixtures
- Generate realistic test data with Faker integration

```python
import factory
from factory import Faker

class UserFactory(factory.Factory):
    class Meta:
        model = User

    name = Faker('name')
    email = Faker('email')
    created_at = Faker('date_time')
```

**Integration Testing**

- Test with real databases, not just mocks
- Use `pytest-docker` or testcontainers for isolated environments
- Verify actual system integration, not just unit behavior

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

## Architecture and Design Patterns

### SOLID Principles

Apply SOLID principles for maintainable, scalable Python code:

**Single Responsibility**

- Each class/module should have one reason to change
- Separate concerns (data access, business logic, presentation)

**Open/Closed**

- Open for extension, closed for modification
- Use inheritance, composition, or protocols for extensibility

**Liskov Substitution**

- Subtypes must be substitutable for their base types
- Honor the contract defined by base classes

**Interface Segregation**

- Use `Protocol` for interface definitions
- Many specific interfaces over one general interface

```python
from typing import Protocol

class Readable(Protocol):
    def read(self) -> str: ...

class Writable(Protocol):
    def write(self, data: str) -> None: ...
```

**Dependency Inversion**

- Depend on abstractions (protocols), not concrete implementations
- Inject dependencies rather than creating them internally

```python
class UserService:
    def __init__(self, db: Database, cache: Cache):
        """Dependencies injected, not created internally."""
        self.db = db
        self.cache = cache
```

### Dependency Injection

Use dependency injection for testable, flexible code:

```python
# Bad: Hard to test, tightly coupled
class UserService:
    def __init__(self):
        self.db = PostgresDatabase()  # Hard-coded dependency

# Good: Easy to test, loosely coupled
class UserService:
    def __init__(self, db: Database):
        self.db = db  # Injected dependency

# Usage
service = UserService(db=MockDatabase())  # Easy to test
```

### Event-Driven Architecture

Use events for decoupled systems:

```python
from typing import Callable, Dict, List

class EventBus:
    def __init__(self):
        self._listeners: Dict[str, List[Callable]] = {}

    def subscribe(self, event: str, callback: Callable):
        self._listeners.setdefault(event, []).append(callback)

    def publish(self, event: str, data: any):
        for callback in self._listeners.get(event, []):
            callback(data)

# Usage
bus = EventBus()
bus.subscribe("user.created", send_welcome_email)
bus.publish("user.created", user)
```

### Plugin Architectures

Create extensible systems with plugin patterns:

**Entry Points (setuptools)**

```python
# pyproject.toml
[project.entry-points."myapp.plugins"]
plugin_name = "myapp.plugins.plugin_module:PluginClass"
```

**Dynamic Loading**

```python
import importlib.metadata

def load_plugins():
    for entry_point in importlib.metadata.entry_points(group="myapp.plugins"):
        plugin_class = entry_point.load()
        yield plugin_class()
```

### Common Design Patterns

**Factory Pattern**

```python
class UserFactory:
    @staticmethod
    def create(user_type: str) -> User:
        if user_type == "admin":
            return AdminUser()
        elif user_type == "regular":
            return RegularUser()
        raise ValueError(f"Unknown user type: {user_type}")
```

**Singleton Pattern (with metaclass)**

```python
class Singleton(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]

class Database(metaclass=Singleton):
    pass
```

**Observer Pattern**

```python
class Subject:
    def __init__(self):
        self._observers = []

    def attach(self, observer):
        self._observers.append(observer)

    def notify(self, data):
        for observer in self._observers:
            observer.update(data)
```

### Advanced Python Features

**Context Managers**

```python
from contextlib import contextmanager

@contextmanager
def database_transaction(db):
    """Custom context manager for transactions."""
    db.begin()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
```

**Descriptors**

```python
class Validated:
    def __init__(self, validator):
        self.validator = validator

    def __set_name__(self, owner, name):
        self.name = f"_{name}"

    def __get__(self, obj, type):
        return getattr(obj, self.name)

    def __set__(self, obj, value):
        self.validator(value)
        setattr(obj, self.name, value)
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

### Async Libraries and Ecosystem

**HTTP Clients**

- Use `aiohttp` for async HTTP requests
- Prefer `httpx` for compatibility with both sync and async code
- Handle connection pooling and timeouts properly

```python
import aiohttp

async def fetch_with_aiohttp(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()
```

**Async Database Access**

- Use `SQLAlchemy 2.0+` with async engine for database operations
- Use `asyncpg` for PostgreSQL (fastest async driver)
- Use `motor` for async MongoDB access

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")

async def get_user(user_id: int) -> User:
    async with AsyncSession(engine) as session:
        result = await session.execute(select(User).where(User.id == user_id))
        return result.scalar_one()
```

**Background Task Processing**

- Use `Celery` with `Redis` for distributed task queues
- Use `arq` for simpler async task processing
- Consider `dramatiq` as an alternative to Celery

**WebSockets**

- Use `FastAPI` WebSocket support for real-time communication
- Use `Django Channels` for WebSocket support in Django
- Handle connection lifecycle and graceful disconnection

```python
from fastapi import FastAPI, WebSocket

app = FastAPI()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f"Echo: {data}")
    except WebSocketDisconnect:
        pass
```

**Alternative Async Frameworks**

- Consider `trio` for structured concurrency and better error handling
- Use `anyio` for writing code compatible with both asyncio and trio

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

Configure logging once at application entry point using `dictConfig` for structured configuration. Use environment variables to switch between development and production modes.

```python
# utils/logging_config.py - Logging configuration module
import logging.config
import os
import sys

import structlog


def configure_logging(env: str = "development") -> None:
    """Configure logging for the entire application.

    Parameters
    ----------
    env : str
        Environment mode: "development" or "production"
    """
    # Standard library logging configuration
    logging_config = {
        "version": 1,
        "disable_existing_loggers": False,  # Important: don't disable existing loggers
        "formatters": {
            "standard": {
                "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "level": "DEBUG" if env == "development" else "INFO",
                "formatter": "standard",
                "stream": "ext://sys.stdout",  # Log to stdout (12-Factor App)
            },
        },
        "root": {
            "level": "DEBUG" if env == "development" else "INFO",
            "handlers": ["console"],
        },
    }
    logging.config.dictConfig(logging_config)

    # Structlog configuration
    processors = [
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]

    # Development: pretty console output
    # Production: JSON for log aggregators
    if env == "development":
        processors.append(structlog.dev.ConsoleRenderer())
    else:
        processors.append(structlog.processors.JSONRenderer())

    structlog.configure(
        processors=processors,
        wrapper_class=structlog.make_filtering_bound_logger(
            logging.DEBUG if env == "development" else logging.INFO
        ),
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )
```

```python
# main.py - Application entry point
import os
from utils.logging_config import configure_logging

if __name__ == "__main__":
    # Use environment variable to determine mode
    env = os.getenv("APP_ENV", "development")
    configure_logging(env=env)
```

**Usage in modules:**

```python
import structlog

logger = structlog.get_logger(__name__)

def process_data(user_id: int) -> None:
    """Process user data with structured logging."""
    logger.info("processing_started", user_id=user_id)
    # ... processing logic ...
    logger.info("processing_completed", user_id=user_id, records_processed=100)
```

## Recommended Libraries

### CLI Applications

Use **Click** for building command-line interfaces:

- Decorator-based approach makes code clean and declarative
- Automatic help generation from function docstrings
- Automatic shell completion generation (bash, zsh, fish)
- Built-in support for environment variables
- Composable and extensible for complex multi-command CLIs
