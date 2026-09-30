---
applyTo: '**/*.{py,pyi}'
---

Provide project context and coding guidelines that AI should follow when generating Python code, answering questions, or reviewing changes. This document is specifically for **Python programming** and adheres to PEP 8 standards and industry best practices.

## Related Documentation

**IMPORTANT**: All code must also comply with code review standards for Python (when available), which contain comprehensive mandatory code review rules organized by severity. Review those standards before submitting code.

---

## Python-Specific Guidelines

### Language Fundamentals
- **Python Version**: Use Python 3.8+ features (f-strings, walrus operator, type hints)
- **Modern Python**: Leverage type hints for readability and IDE support
- **Virtual Environments**: Always use virtual environments for project isolation
- **PEP 8 Compliance**: Follow PEP 8 style guide strictly
- **Code Style**: Use tools like `black`, `flake8`, and `mypy` for enforcement

### Naming Conventions (MANDATORY)

#### Modules and Packages
- **all lowercase**: `mymodule`, `mypackage`
- **underscores for readability**: `my_module` preferred
- **Avoid hyphens**: Use underscores instead
- **Descriptive names**: Reflect the module's purpose

#### Classes
- **PascalCase**: `CustomerService`, `OrderProcessor`
- **Nouns**: Classes represent things
- **No prefix abbreviations**: Not `CCustomer` or `IService`

#### Functions and Methods
- **snake_case**: `calculate_total`, `find_by_id`, `process_order`
- **Verbs**: Functions perform actions
- **Private methods**: Prefix with underscore: `_internal_method`
- **Dunder methods**: `__init__`, `__str__`, `__repr__`
- **Boolean functions**: Use `is_`, `has_`, `can_` prefixes: `is_valid()`, `has_permission()`

#### Variables and Constants
- **snake_case**: `first_name`, `total_amount`, `order_list`
- **Descriptive**: Full words, minimize abbreviations
- **Constants**: `UPPER_SNAKE_CASE`: `MAX_RETRIES = 3`
- **Private variables**: Prefix with underscore: `_internal_var`
- **No single letters**: Except loop counters (`i`, `j`, `k` in list comprehensions)

#### Type Variables
```python
from typing import TypeVar

T = TypeVar('T')  # Generic type
UserT = TypeVar('UserT', bound='User')  # Bounded type
```

### Code Formatting (MANDATORY)

#### Indentation and Spacing
- **4 spaces per level** (never tabs)
- **Blank lines**: Two around top-level functions/classes, one between methods
- **Spaces around operators**: `a + b` not `a+b`, but `func(a, b=1)` not `func(a, b = 1)`
- **Spaces after commas**: `(a, b, c)` not `(a,b,c)`
- **Line length**: Maximum 88 characters (Black standard) or 79 (PEP 8)

#### String Formatting
- **f-strings**: Preferred for readability (Python 3.6+)
  ```python
  message = f"Username: {user.name}, age: {user.age}"
  ```
- **str.format()**: For complex formatting
  ```python
  message = "Items: {}, Total: ${:.2f}".format(count, total)
  ```
- **String concatenation**: Only for simple cases, avoid in loops

#### Line Continuations
- **Use parentheses**: For implicit line continuation
  ```python
  result = (
      some_long_function(arg1, arg2) +
      other_function(arg3, arg4)
  )
  ```
- **Backslash**: Only when parentheses impossible

#### Import Organization
```python
# Standard library imports
import os
import sys
from datetime import datetime
from typing import List, Optional

# Third-party imports
import requests
import numpy as np

# Local imports
from . import config
from .models import User
```

### Type Hints (MANDATORY)

#### Function Signatures
```python
def calculate_total(items: List[float], tax_rate: float) -> float:
    """Calculate total with tax."""
    return sum(items) * (1 + tax_rate)

def find_user(user_id: int) -> Optional[User]:
    """Find user by ID, return None if not found."""
    # Implementation
    pass
```

#### Variable Type Hints
```python
# Explicit type hints
count: int = 0
users: List[User] = []
config: Dict[str, Any] = {}
response: Optional[Response] = None
```

#### Complex Types
```python
from typing import Callable, Dict, List, Optional, Tuple, Union

# Callable
handler: Callable[[int, str], bool] = process_item

# Union
value: Union[int, str] = get_value()

# Generic with multiple parameters
mapping: Dict[str, List[int]] = {}

# Tuple with fixed types
coordinates: Tuple[float, float, float] = (0.0, 0.0, 0.0)
```

#### Type Checking
- **Use mypy**: Static type checker
  ```bash
  mypy src/
  ```
- **Fix type errors**: Before commit
- **Ignore only when necessary**: Add `# type: ignore` sparingly

### Object-Oriented Design

#### Classes and Inheritance
```python
class BaseService:
    """Base service with shared functionality."""
    
    def __init__(self, name: str):
        self._name = name
    
    def get_name(self) -> str:
        """Get service name."""
        return self._name


class CustomerService(BaseService):
    """Service for customer operations."""
    
    def find_by_id(self, customer_id: int) -> Optional[Customer]:
        """Find customer by ID."""
        # Implementation
        pass
```

#### Properties and Encapsulation
```python
class Account:
    """Bank account with encapsulation."""
    
    def __init__(self, balance: float):
        self._balance = balance
    
    @property
    def balance(self) -> float:
        """Get current balance (read-only)."""
        return self._balance
    
    def deposit(self, amount: float) -> None:
        """Deposit funds."""
        if amount <= 0:
            raise ValueError("Deposit amount must be positive")
        self._balance += amount
```

#### SOLID Principles
1. **Single Responsibility**: One class, one reason to change
2. **Open/Closed**: Open for extension, closed for modification (use ABC)
3. **Liskov Substitution**: Subclasses must be substitutable for parent
4. **Interface Segregation**: Many specific interfaces over one general
5. **Dependency Inversion**: Depend on abstractions, not concretions

```python
from abc import ABC, abstractmethod

class DataRepository(ABC):
    """Abstract base class for data access."""
    
    @abstractmethod
    def find(self, item_id: int) -> Optional[Any]:
        """Find item by ID."""
        pass
    
    @abstractmethod
    def save(self, item: Any) -> None:
        """Save or update item."""
        pass


class DatabaseRepository(DataRepository):
    """Concrete implementation using database."""
    
    def find(self, item_id: int) -> Optional[Any]:
        # Implementation
        pass
    
    def save(self, item: Any) -> None:
        # Implementation
        pass
```

### Function and Method Design

#### Keep Functions Small
- **Maximum 20-30 lines**: One level of abstraction
- **Single purpose**: Do one thing well
- **Descriptive names**: Name reveals intent
- **Document purpose**: Not implementation details

#### Parameters and Return Values
- **Maximum 3-4 parameters**: Use dataclass or dict for more
- **Use keyword arguments**: For optional parameters
- **Return values over out parameters**: Python has multiple return values
- **Return None sparingly**: Consider raising exception instead

```python
# Good: Keyword arguments
def create_order(customer_id: int, items: List[Item], 
                 expedite: bool = False, gift_wrap: bool = False) -> Order:
    pass

# Good: Multiple return values
def calculate_stats(data: List[float]) -> Tuple[float, float, float]:
    """Return mean, median, and std dev."""
    pass

# Good: Raise exception for invalid state
def withdraw(account: Account, amount: float) -> None:
    """Withdraw funds, raise InsufficientFundsError if not enough."""
    if amount > account.balance:
        raise InsufficientFundsError(f"Need ${amount}, have ${account.balance}")
    account._balance -= amount
```

#### Context Management
```python
from contextlib import contextmanager

class FileHandler:
    """File handler with context manager."""
    
    def __enter__(self):
        """Enter context."""
        self.file = open('data.txt', 'r')
        return self.file
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Exit context - always cleanup."""
        if self.file:
            self.file.close()

# Usage
with FileHandler() as f:
    data = f.read()

# Or use contextlib decorator
@contextmanager
def database_session(connection_string: str):
    """Context manager for database sessions."""
    conn = connect(connection_string)
    try:
        yield conn
    finally:
        conn.close()
```

### Exception Handling (CRITICAL)

#### Specific Exception Catching
```python
# ❌ Too broad
try:
    result = process_data(data)
except Exception as e:
    print(f"Error: {e}")

# ✅ Specific exceptions
try:
    result = process_data(data)
except ValueError as e:
    logger.error(f"Invalid data format: {e}")
except IOError as e:
    logger.error(f"File operation failed: {e}")
except Exception as e:
    logger.critical(f"Unexpected error: {e}")
    raise
```

#### Raise Custom Exceptions
```python
class ValidationError(ValueError):
    """Raised when validation fails."""
    pass

class ConfigurationError(RuntimeError):
    """Raised when configuration is invalid."""
    pass

def validate_config(config: Dict[str, Any]) -> None:
    """Validate configuration, raise ConfigurationError if invalid."""
    if 'database_url' not in config:
        raise ConfigurationError("Missing required 'database_url'")
```

#### Exception Context
```python
# ✅ Preserve exception context
try:
    data = parse_json(json_string)
except ValueError as e:
    raise ConfigurationError(f"Failed to parse config: {e}") from e

# Usage with cause
try:
    # operations
except CustomError as e:
    # e.__cause__ points to the original exception
    handle_error(e)
```

#### Logging Exceptions
```python
import logging

logger = logging.getLogger(__name__)

try:
    risky_operation()
except SpecificException as e:
    # Log with exception details
    logger.exception("Operation failed: %s", str(e))
    # Optionally re-raise
    raise
```

### Collections and Iteration

#### List Comprehensions
```python
# List comprehension - clear and efficient
squares = [x ** 2 for x in range(10)]

# With condition
even_squares = [x ** 2 for x in range(10) if x % 2 == 0]

# Nested comprehension
matrix = [[f"({i},{j})" for j in range(3)] for i in range(3)]

# Dict comprehension
word_lengths = {word: len(word) for word in words}

# Set comprehension
unique_lengths = {len(word) for word in words}

# Generator expression - for memory efficiency
total = sum(x ** 2 for x in large_sequence)
```

#### Appropriate Data Structures
```python
from collections import defaultdict, Counter, deque

# defaultdict for grouping
users_by_role = defaultdict(list)
for user in users:
    users_by_role[user.role].append(user)

# Counter for frequency
word_frequencies = Counter(words)
top_5 = word_frequencies.most_common(5)

# deque for efficient queue operations
queue = deque(maxlen=100)  # Last 100 items
queue.append(item)
oldest = queue.popleft()
```

#### Iteration Best Practices
```python
# Enumerate for index and value
for index, item in enumerate(items):
    print(f"{index}: {item}")

# zip for parallel iteration
for user, score in zip(users, scores):
    print(f"{user.name}: {score}")

# Unpacking in loops
for first, second, *rest in sequences:
    process(first, second, rest)
```

### String Operations

#### String Methods Over str.format() in Loops
```python
# Good - f-strings
results = [f"Item {i}: {item.name}" for i, item in enumerate(items)]

# Avoid in loops
results = []
for i, item in enumerate(items):
    results.append(f"Item {i}: {item.name}")

# Not concatenation in loops
results = []
for i, item in enumerate(items):
    results.append("Item " + str(i) + ": " + item.name)  # ❌ Inefficient
```

#### Unicode Handling
```python
# Always use Unicode strings (default in Python 3)
text = "Hello, 世界"

# Encode/decode explicitly when needed
encoded = text.encode('utf-8')
decoded = encoded.decode('utf-8')
```

### Concurrency and Async Programming

#### Threading for I/O-Bound Operations
```python
from concurrent.futures import ThreadPoolExecutor
import requests

def fetch_url(url: str) -> str:
    """Fetch URL content."""
    response = requests.get(url)
    return response.text

urls = ['http://example.com/1', 'http://example.com/2']

# Use ThreadPoolExecutor for I/O-bound tasks
with ThreadPoolExecutor(max_workers=3) as executor:
    results = list(executor.map(fetch_url, urls))
```

#### Async/Await for Concurrent I/O (Python 3.7+)
```python
import asyncio
import aiohttp

async def fetch_url(session: aiohttp.ClientSession, url: str) -> str:
    """Fetch URL asynchronously."""
    async with session.get(url) as response:
        return await response.text()

async def fetch_all(urls: List[str]) -> List[str]:
    """Fetch all URLs concurrently."""
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_url(session, url) for url in urls]
        return await asyncio.gather(*tasks)

# Run async code
results = asyncio.run(fetch_all(urls))
```

#### Multiprocessing for CPU-Bound Operations
```python
from multiprocessing import Pool
from typing import List

def expensive_computation(n: int) -> int:
    """CPU-intensive operation."""
    return sum(x ** 2 for x in range(n))

numbers = [1000000, 2000000, 3000000]

# Use multiprocessing for CPU-bound tasks
with Pool(processes=4) as pool:
    results = pool.map(expensive_computation, numbers)
```

### Memory Management

#### Context Managers for Resource Cleanup
```python
# Files
with open('data.txt', 'r') as f:
    content = f.read()

# Database connections
with database.connection() as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()

# Locks
with threading.Lock() as lock:
    shared_resource.update()
```

#### Avoiding Memory Leaks
```python
# ❌ Circular references
class Node:
    def __init__(self, value):
        self.value = value
        self.parent = None
        self.children = []
    
    def add_child(self, child):
        self.children.append(child)
        child.parent = self  # Creates circular reference

# ✅ Use weak references for circular refs
import weakref

class Node:
    def __init__(self, value):
        self.value = value
        self._parent = None
        self.children = []
    
    @property
    def parent(self):
        return self._parent() if self._parent else None
    
    @parent.setter
    def parent(self, node):
        self._parent = weakref.ref(node) if node else None
```

### File and Directory Operations

#### Using pathlib (Modern Approach)
```python
from pathlib import Path

# Modern - pathlib
data_dir = Path('data')
file_path = data_dir / 'file.txt'

if file_path.exists():
    content = file_path.read_text(encoding='utf-8')
    lines = content.splitlines()

# Create directories
output_dir = Path('output')
output_dir.mkdir(parents=True, exist_ok=True)

# Iterate files
for py_file in Path('src').glob('*.py'):
    print(f"Processing {py_file.name}")
```

#### Avoid os Module When Possible
```python
# ❌ Old way - os module
import os
file_path = os.path.join('data', 'file.txt')
if os.path.exists(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

# ✅ New way - pathlib
from pathlib import Path
file_path = Path('data') / 'file.txt'
if file_path.exists():
    content = file_path.read_text()
```

### Configuration Management

#### Environment Variables
```python
import os
from typing import Optional

def get_env(key: str, default: Optional[str] = None) -> str:
    """Get environment variable with optional default."""
    return os.getenv(key, default)

# Usage
database_url = get_env('DATABASE_URL', 'sqlite:///test.db')
debug_mode = get_env('DEBUG', 'False').lower() == 'true'
```

#### Configuration Files
```python
import json
from pathlib import Path
from typing import Any, Dict

def load_config(config_file: Path) -> Dict[str, Any]:
    """Load JSON configuration file."""
    if not config_file.exists():
        raise FileNotFoundError(f"Config file not found: {config_file}")
    
    with open(config_file, 'r') as f:
        return json.load(f)

# Or use configparser for INI files
import configparser

config = configparser.ConfigParser()
config.read('config.ini')
database_url = config.get('database', 'url')
```

### Documentation (MANDATORY)

#### Docstrings (Google Style or NumPy Style)
```python
def calculate_total(items: List[Item], tax_rate: float) -> float:
    """Calculate total amount including tax.
    
    Multiplies item subtotal by (1 + tax_rate).
    
    Args:
        items: List of items to sum.
        tax_rate: Tax rate as decimal (0.08 for 8%).
    
    Returns:
        Total amount including tax.
    
    Raises:
        ValueError: If tax_rate is negative or items is empty.
    
    Example:
        >>> items = [Item(price=10), Item(price=20)]
        >>> calculate_total(items, 0.08)
        32.4
    """
    if not items:
        raise ValueError("Items list cannot be empty")
    if tax_rate < 0:
        raise ValueError("Tax rate cannot be negative")
    
    subtotal = sum(item.price for item in items)
    return subtotal * (1 + tax_rate)
```

#### Class Docstrings
```python
class CustomerService:
    """Service for managing customer operations.
    
    Handles customer CRUD operations and business logic.
    
    Attributes:
        repository: Data access layer for customers.
        email_service: Service for sending customer emails.
    """
    
    def __init__(self, repository: CustomerRepository, 
                 email_service: EmailService):
        """Initialize service with dependencies."""
        self.repository = repository
        self.email_service = email_service
```

#### Inline Comments
```python
# Explain WHY, not WHAT
def process_data(data: List[float]) -> List[float]:
    """Process raw sensor data."""
    
    # Remove outliers (values > 3 standard deviations)
    # using modified Z-score method
    mean = sum(data) / len(data)
    std_dev = (sum((x - mean) ** 2 for x in data) / len(data)) ** 0.5
    threshold = 3 * std_dev
    
    return [x for x in data if abs(x - mean) <= threshold]
```

### Logging

#### Structured Logging
```python
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Usage
logger.info("Processing started")
logger.debug("Debug details: %s", details)
logger.warning("Warning condition detected")
logger.error("Error occurred: %s", error_message)
logger.critical("Critical error: %s", critical_message)
```

#### Logging Exceptions
```python
try:
    risky_operation()
except SpecificException as e:
    # Include exception details in log
    logger.exception("Operation failed")  # Includes traceback
```

### Testing Standards (MANDATORY)

#### Unit Testing with pytest
```python
import pytest
from typing import List

class TestCalculateTotal:
    """Test suite for calculate_total function."""
    
    def setup_method(self):
        """Setup before each test."""
        self.items = [Item(10.0), Item(20.0)]
    
    def test_calculate_total_with_valid_items(self):
        """Test calculating total with valid items."""
        # Arrange
        tax_rate = 0.08
        
        # Act
        result = calculate_total(self.items, tax_rate)
        
        # Assert
        assert result == pytest.approx(32.4, rel=1e-2)
    
    def test_calculate_total_with_empty_items(self):
        """Test calculating total raises error with empty items."""
        with pytest.raises(ValueError, match="Items list cannot be empty"):
            calculate_total([], 0.08)
    
    def test_calculate_total_with_negative_tax(self):
        """Test calculating total raises error with negative tax."""
        with pytest.raises(ValueError, match="Tax rate cannot be negative"):
            calculate_total(self.items, -0.08)
```

#### Fixtures for Common Setup
```python
@pytest.fixture
def sample_user():
    """Fixture providing sample user."""
    return User(name="John Doe", email="john@example.com")

@pytest.fixture
def database():
    """Fixture providing test database connection."""
    db = TestDatabase()
    yield db
    db.close()  # Cleanup

def test_create_user(database, sample_user):
    """Test creating user in database."""
    result = database.create(sample_user)
    assert result.id is not None
```

#### Test Organization
```
tests/
├── unit/
│   ├── test_models.py
│   ├── test_services.py
│   └── test_utils.py
├── integration/
│   ├── test_database.py
│   └── test_api.py
└── conftest.py  # Shared fixtures
```

#### Mocking External Dependencies
```python
from unittest.mock import Mock, patch, MagicMock

def test_order_service_with_mock_repository():
    """Test OrderService with mocked repository."""
    # Arrange
    mock_repo = Mock()
    mock_repo.find.return_value = Order(id=1, total=100.0)
    service = OrderService(mock_repo)
    
    # Act
    order = service.get_order(1)
    
    # Assert
    assert order.total == 100.0
    mock_repo.find.assert_called_once_with(1)

def test_external_api_call():
    """Test code that calls external API."""
    with patch('requests.get') as mock_get:
        # Mock the external API response
        mock_get.return_value.json.return_value = {'status': 'ok'}
        
        result = call_external_api()
        assert result['status'] == 'ok'
```

### Project Structure

#### Standard Project Layout
```
project/
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── models/
│       │   ├── __init__.py
│       │   ├── user.py
│       │   └── order.py
│       ├── services/
│       │   ├── __init__.py
│       │   ├── user_service.py
│       │   └── order_service.py
│       ├── repositories/
│       │   ├── __init__.py
│       │   └── user_repository.py
│       └── utils/
│           ├── __init__.py
│           └── helpers.py
├── tests/
│   ├── unit/
│   │   ├── test_models.py
│   │   └── test_services.py
│   ├── integration/
│   │   └── test_api.py
│   └── conftest.py
├── docs/
├── pyproject.toml
├── setup.py
├── requirements.txt
├── requirements-dev.txt
├── .gitignore
├── .flake8
├── .mypy.ini
├── Makefile
└── README.md
```

### Dependency Management

#### Using pip with Requirements Files
```
# requirements.txt - Production dependencies
requests==2.28.0
sqlalchemy==2.0.0
pydantic==1.10.0

# requirements-dev.txt - Development dependencies
pytest==7.2.0
pytest-cov==4.0.0
black==22.10.0
mypy==0.991
flake8==5.0.4
```

#### Using Poetry (Modern Approach)
```toml
# pyproject.toml
[tool.poetry]
name = "myproject"
version = "0.1.0"
description = "My project"

[tool.poetry.dependencies]
python = "^3.8"
requests = "^2.28.0"
sqlalchemy = "^2.0.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.2.0"
black = "^22.10.0
mypy = "^0.991"
```

### Code Quality Tools

#### Black - Code Formatting
```bash
# Format code
black src/

# Check without modifying
black --check src/
```

#### Flake8 - Linting
```bash
# Run linter
flake8 src/

# Configuration in .flake8
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = .venv,build,dist
```

#### MyPy - Static Type Checking
```bash
# Check types
mypy src/

# Configuration in pyproject.toml
[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
strict = false
```

#### Pytest - Testing
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test
pytest tests/unit/test_models.py::TestUser::test_creation
```

### Security Best Practices (CRITICAL)

#### Input Validation
```python
def validate_email(email: str) -> str:
    """Validate email format."""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(pattern, email):
        raise ValueError("Invalid email format")
    return email.lower()

def validate_password(password: str) -> str:
    """Validate password strength."""
    if len(password) < 8:
        raise ValueError("Password must be at least 8 characters")
    if not any(c.isupper() for c in password):
        raise ValueError("Password must contain uppercase letter")
    if not any(c.isdigit() for c in password):
        raise ValueError("Password must contain digit")
    return password
```

#### Sensitive Data Protection
```python
# ❌ Never log sensitive data
logger.info(f"User login: {username}, password: {password}")

# ✅ Log safely
logger.info(f"User login: {username}")

# Use getpass for interactive password input
import getpass
password = getpass.getpass("Enter password: ")

# Clear sensitive from memory (if using cryptography)
import secrets
token = secrets.token_urlsafe(32)
```

#### SQL Injection Prevention
```python
# ❌ String concatenation (SQL Injection vulnerability)
query = f"SELECT * FROM users WHERE username='{username}'"

# ✅ Parameterized queries (Safe)
query = "SELECT * FROM users WHERE username=?"
cursor.execute(query, (username,))

# ✅ ORM (SQLAlchemy) (Safe)
user = session.query(User).filter(User.username == username).first()
```

#### External Dependencies
```python
# Keep dependencies updated
pip list --outdated
pip install --upgrade package_name

# Use lock files for reproducibility
# poetry.lock (Poetry)
# Pipfile.lock (Pipenv)

# Audit for vulnerabilities
pip install pip-audit
pip-audit
```

### Performance Optimization

#### Benchmarking
```python
import timeit

def test_list_vs_set():
    """Compare list vs set membership testing."""
    data_list = list(range(10000))
    data_set = set(range(10000))
    
    # List lookup is O(n)
    list_time = timeit.timeit(lambda: 5000 in data_list, number=100)
    
    # Set lookup is O(1)
    set_time = timeit.timeit(lambda: 5000 in data_set, number=100)
    
    print(f"List: {list_time:.6f}s, Set: {set_time:.6f}s")
    # Typically: List: ~0.005s, Set: ~0.0001s
```

#### Profiling
```python
import cProfile
import pstats

def expensive_function():
    """Function to profile."""
    return sum(x ** 2 for x in range(100000))

# Profile the function
profiler = cProfile.Profile()
profiler.enable()

expensive_function()

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(10)  # Top 10 functions
```

### Copyright Headers (MANDATORY)

#### Python Files
```python
"""
Copyright (c) 2026 <Company Name>

All rights reserved. No part of this program or document may be
reproduced in any form or by any means without permission in writing
from <Company Name>.
"""

"""
Module: module_name
Description: Brief description of module purpose.

Author: Author Name
Created: 2026-02-12
Modified: 2026-02-12
"""
```

---

## Summary

Key principles for Python development:

✅ **Naming**: snake_case functions, PascalCase classes, UPPER_SNAKE_CASE constants
✅ **Formatting**: 4 spaces, f-strings, max 88 chars, Black compliant
✅ **Type Hints**: Function signatures, variable annotations, mypy compliance
✅ **OOP**: Encapsulation, inheritance, SOLID principles, abstract base classes
✅ **Functions**: Small (20-30 lines), max 3-4 params, single responsibility
✅ **Exceptions**: Specific catches, custom exceptions, proper logging
✅ **Collections**: List comprehensions, appropriate data structures, iterators
✅ **Async**: Threading for I/O, async/await for concurrent I/O, multiprocessing for CPU-bound
✅ **Testing**: pytest, fixtures, mocking, comprehensive coverage
✅ **Code Quality**: black, flake8, mypy, pytest coverage
✅ **Security**: Input validation, parameterized queries, sensitive data protection
✅ **Documentation**: Docstrings (Google style), type hints, examples
✅ **Clean Code**: Descriptive names, DRY principle, explain why not what

Use code quality tools (`black`, `flake8`, `mypy`, `pytest`) to validate code automatically. Follow "Clean Code: A Handbook of Agile Software Craftsmanship" by Robert C. Martin. Reference [PEP 8](https://www.python.org/dev/peps/pep-0008/) and [PEP 20](https://www.python.org/dev/peps/pep-0020/) (Zen of Python) for additional guidance.
