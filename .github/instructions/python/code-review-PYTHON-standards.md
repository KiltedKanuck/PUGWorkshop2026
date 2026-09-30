---
applyTo: '**/*.{py,pyi}'
---

# Code Review Standards for Python Programming

## Overview

This document contains comprehensive mandatory code review rules for **Python programming**. All code must comply with these standards before merge and follow PEP 8, PEP 20 (Zen of Python), and industry best practices.

**Severity Indicators**:
- **BLOCKER**: Must be fixed immediately - blocks release
- **CRITICAL**: Must be fixed before merge - causes bugs, security issues, or runtime failures
- **MAJOR**: Should be fixed - impacts performance, maintainability, or quality
- **MINOR**: Recommended to fix - improves code quality and consistency
- **INFO**: Information or low-priority improvements

**Related Documentation**: See [general-python-instructions.md](general-python-instructions.md) for quick-reference coding guidelines, best practices, and project structure requirements.

---

## Standards Overview

This document enforces:
1. Naming Conventions (MANDATORY)
2. Code Formatting and Style (MANDATORY)
3. Type Hints and Annotations (CRITICAL)
4. Function and Method Design (MAJOR)
5. Class Design and SOLID (CRITICAL)
6. Exception Handling (CRITICAL)
7. Imports and Module Organization (MANDATORY)
8. Documentation and Comments (MANDATORY)
9. Testing and Coverage (MANDATORY)
10. Security (CRITICAL)
11. Performance (MAJOR)
12. Code Complexity (MAJOR)

---

## 1. Naming Conventions (MANDATORY)

### Module and Package Names
- **All lowercase**: `mymodule`, `mypackage`
- **Underscores for readability**: `my_module` preferred over `mymodule`
- **No hyphens**: Use underscores instead
- **Descriptive**: Reflect module purpose

**Noncompliant:**
```python
# ❌ Wrong cases, hyphens, unclear names
import MyModule
import my-module
import util
```

**Compliant:**
```python
# ✅ Correct
import customer_service
import order_processor
```

### Class Names
- **PascalCase**: `CustomerService`, `OrderProcessor`
- **Nouns**: Classes represent entities
- **No abbreviations**: Not `Cust` or `Ord`
- **Single responsibility**: Name reflects purpose

**Noncompliant:**
```python
class customer_service:  # Should be PascalCase
    pass

class Data:  # Too generic
    pass

class DoStuff:  # Not a noun
    pass
```

**Compliant:**
```python
class CustomerService:
    pass

class OrderProcessor:
    pass

class PaymentValidator:
    pass
```

### Function and Method Names
- **snake_case**: `calculate_total`, `find_by_id`, `process_order`
- **Verbs or verb phrases**: Describe action
- **Private methods**: Prefix with underscore: `_internal_method`
- **Boolean functions**: Use `is_`, `has_`, `can_`, `should_` prefixes

**Noncompliant:**
```python
def CalculateTotal():  # Should be snake_case
    pass

def active():  # Should use is_ prefix for boolean
    pass

def customer():  # Noun, not verb
    pass
```

**Compliant:**
```python
def calculate_total():
    pass

def is_active():
    pass

def find_customer_by_id(customer_id):
    pass

def _internal_helper():
    pass
```

### Variable and Constant Names
- **snake_case**: `first_name`, `total_amount`, `order_list`
- **Descriptive**: Full words, minimize abbreviations
- **Constants**: `UPPER_SNAKE_CASE`: `MAX_RETRIES = 3`
- **Private variables**: Prefix with underscore: `_internal_var`
- **No single letters**: Except loop counters (`i`, `j`, `k` in comprehensions)

**Noncompliant:**
```python
fn = "John"  # Abbreviated, unclear
MAX_TRIES = 3  # Not uppercase
_private = value  # Unnecessary leading underscore for constants
d = 10  # Single letter, unclear intent
```

**Compliant:**
```python
first_name = "John"
MAX_RETRIES = 3
private_timeout = value
days_in_month = 30
```

### Exception Classes
- **PascalCase with 'Error' suffix**: `ValidationError`, `ConfigurationError`
- **Inherit from appropriate base**: `ValueError`, `RuntimeError`

**Compliant:**
```python
class ValidationError(ValueError):
    pass

class ConfigurationError(RuntimeError):
    pass
```

---

## 2. Code Formatting and Style (MANDATORY)

### Line Length
- **Maximum 88 characters** (Black standard) or 79 (strict PEP 8)
- **Break at logical points**: After comma, before operator
- **Indent continuations**: 4 additional spaces or parentheses alignment

**Compliant:**
```python
# Break after opening bracket
result = (
    some_long_function(arg1, arg2) +
    other_function(arg3, arg4)
)

# Implicit line continuation in parentheses
items = [
    item1,
    item2,
    item3,
]
```

### Indentation
- **4 spaces per level** (never tabs)
- **Consistent throughout file**
- **Use spaces, never tabs** (Python 3 enforces this)

**Noncompliant:**
```python
def function():
    # Using tab character
    if condition:
        print("bad")
```

**Compliant:**
```python
def function():
    # Using 4 spaces
    if condition:
        print("good")
```

### Whitespace and Blank Lines
- **Two blank lines** between top-level functions and classes
- **One blank line** between methods in a class
- **One blank line** between logical sections within functions
- **No multiple consecutive blank lines**
- **No trailing whitespace**

**Compliant:**
```python
def function1():
    pass


def function2():
    pass


class MyClass:
    def method1(self):
        pass

    def method2(self):
        pass
```

### Spaces Around Operators
- **Space before and after** binary operators: `a + b`, `x == y`
- **No space** around default parameter values: `func(a, b=1)`
- **Space after comma**: `(a, b, c)` not `(a,b,c)`

**Noncompliant:**
```python
x=1+2
result=function(a,b,c=10)
```

**Compliant:**
```python
x = 1 + 2
result = function(a, b, c=10)
```

### String Formatting
- **f-strings preferred**: `f"Username: {user.name}"` (Python 3.6+)
- **.format() for complex**: `"Items: {}, Total: ${:.2f}".format(count, total)`
- **Avoid concatenation in loops**: Use list comprehension or join

**Noncompliant:**
```python
# ❌ Old-style formatting
message = "User: %s, Age: %d" % (name, age)

# ❌ Concatenation in loop (inefficient)
result = ""
for item in items:
    result += str(item)
```

**Compliant:**
```python
# ✅ f-string
message = f"User: {name}, Age: {age}"

# ✅ Efficient collection
result_list = [str(item) for item in items]
result = "".join(result_list)
```

### Import Organization
- **Standard library imports** first
- **Third-party imports** second
- **Local imports** last
- **Alphabetical within groups**
- **One import per line** (except `from X import A, B` if short)

**Noncompliant:**
```python
# ❌ Wrong order
import requests
import os
from mymodule import something
import sys
```

**Compliant:**
```python
# ✅ Correct order
import os
import sys
from datetime import datetime
from typing import List, Optional

import requests
import numpy as np

from . import config
from .models import User
```

---

## 3. Type Hints and Annotations (CRITICAL)

### Function Type Hints
- **All public functions** must have type hints
- **Include return type**: `-> Type`
- **Use Optional** for potentially None values: `Optional[Type]`
- **Use Union** for multiple types: `Union[int, str]`

**Noncompliant:**
```python
# ❌ No type hints
def calculate_total(items, tax_rate):
    return sum(items) * (1 + tax_rate)

# ❌ Incomplete hints
def find_user(user_id: int):
    pass
```

**Compliant:**
```python
# ✅ Complete type hints
def calculate_total(items: List[float], tax_rate: float) -> float:
    return sum(items) * (1 + tax_rate)

def find_user(user_id: int) -> Optional[User]:
    pass
```

### Variable Type Hints
- **Complex or unclear types** should be annotated
- **Module-level variables** with type hints
- **Class attributes** in class definition

**Compliant:**
```python
# Public function with hints
def process_data(data: Dict[str, List[int]]) -> Tuple[float, float]:
    pass

# Module variable
configuration: Dict[str, Any] = {}

# Class attribute
class DataProcessor:
    results: List[str] = []
```

### Type Checking Compliance
- **Pass mypy**: Static type checker validation
- **Fix type errors**: Before committing
- **Use # type: ignore sparingly**: Only when necessary

```bash
# Validate type hints
mypy src/
```

---

## 4. Function and Method Design (MAJOR)

### Function Size
- **Maximum 20-30 lines**: One level of abstraction
- **Single purpose**: Do one thing well
- **Extract methods**: Break large functions into smaller ones

**Noncompliant:**
```python
# ❌ Too large, mixed concerns
def process_order(order):
    # 50 lines of validation, calculation, persistence, notification
    validate_order(order)
    calculate_tax(order)
    apply_discount(order)
    persist_to_database(order)
    send_confirmation_email(order)
    update_inventory(order)
```

**Compliant:**
```python
# ✅ Small, focused functions
def process_order(order: Order) -> None:
    validate_order(order)
    calculate_total(order)
    save_order(order)
    notify_customer(order)
```

### Parameter Count
- **Maximum 3-4 parameters**: Too many indicates design issue
- **Use dataclass or dict** for more parameters
- **Use keyword-only arguments** for optional parameters

**Noncompliant:**
```python
# ❌ Too many parameters
def create_user(first_name, last_name, email, phone, address, city, state, zip_code):
    pass
```

**Compliant:**
```python
# ✅ Parameter object or dataclass
from dataclasses import dataclass

@dataclass
class UserInfo:
    first_name: str
    last_name: str
    email: str
    phone: str

def create_user(user_info: UserInfo, address: Address) -> User:
    pass
```

### Return Values
- **Prefer returning values**: Over modifying parameters
- **Return early**: Avoid deep nesting
- **Use Optional<T>**: For potentially None values
- **Never use implicit None return**

**Noncompliant:**
```python
# ❌ Implicit return None
def find_user(user_id: int):
    if user_id == 1:
        return User(id=1)
    # Implicitly returns None

# ❌ Modifying external state
def update_total(order):
    order.total = calculate(order)  # Mutates parameter
```

**Compliant:**
```python
# ✅ Explicit return type
def find_user(user_id: int) -> Optional[User]:
    if user_id == 1:
        return User(id=1)
    return None

# ✅ Return new value
def calculate_total(order: Order) -> float:
    return sum(item.price for item in order.items)
```

---

## 5. Class Design and SOLID (CRITICAL)

### Single Responsibility Principle
- **One reason to change**: Each class has single responsibility
- **Cohesive methods**: All relate to class purpose
- **Small classes**: Easier to test and maintain

**Noncompliant:**
```python
# ❌ Multiple responsibilities
class Customer:
    def save(self):  # Persistence
        pass

    def send_email(self):  # Communication
        pass

    def generate_invoice(self):  # Billing
        pass
```

**Compliant:**
```python
# ✅ Separated concerns
class Customer:
    def __init__(self, name: str, email: str):
        self.name = name
        self.email = email

class CustomerRepository:
    def save(self, customer: Customer) -> None:
        pass

class EmailService:
    def send_email(self, customer: Customer, message: str) -> None:
        pass
```

### Encapsulation
- **Private attributes**: Prefix with underscore `_attr`
- **Public methods**: Expose only necessary interface
- **Properties**: For controlled access to attributes

**Noncompliant:**
```python
# ❌ Public attributes
class Account:
    balance = 100.0  # Should be private
    transactions = []  # Mutable, exposed
```

**Compliant:**
```python
# ✅ Proper encapsulation
class Account:
    def __init__(self, balance: float):
        self._balance = balance
        self._transactions: List[Transaction] = []

    @property
    def balance(self) -> float:
        return self._balance

    def deposit(self, amount: float) -> None:
        if amount <= 0:
            raise ValueError("Amount must be positive")
        self._balance += amount
```

### Inheritance and Composition
- **Prefer composition**: More flexible than inheritance
- **Use inheritance** only for "is-a" relationships
- **Use abstract base classes** for contracts

**Compliant:**
```python
from abc import ABC, abstractmethod

# Abstract base class defines contract
class DataRepository(ABC):
    @abstractmethod
    def find(self, item_id: int) -> Optional[Any]:
        pass

    @abstractmethod
    def save(self, item: Any) -> None:
        pass

# Concrete implementation
class DatabaseRepository(DataRepository):
    def find(self, item_id: int) -> Optional[Any]:
        # Implementation
        pass

    def save(self, item: Any) -> None:
        # Implementation
        pass
```

---

## 6. Exception Handling (CRITICAL)

### Use Specific Exceptions
- **Catch specific exceptions**: Never catch `Exception` or `BaseException`
- **Raise appropriate exceptions**: Use built-in or custom exceptions
- **Create custom exceptions**: For domain-specific errors
- **Chain exceptions**: Use `raise ... from ...` to preserve context

**Noncompliant:**
```python
# ❌ Too broad exception catch
try:
    result = process_data(data)
except Exception as e:  # Too broad
    print(f"Error: {e}")

# ❌ Lost exception context
try:
    data = parse_json(json_string)
except ValueError:
    raise ConfigurationError("Failed to parse config")  # Lost context
```

**Compliant:**
```python
# ✅ Specific exceptions
try:
    result = process_data(data)
except ValueError as e:
    logger.error(f"Invalid data format: {e}")
except IOError as e:
    logger.error(f"File operation failed: {e}")

# ✅ Preserve exception context
try:
    data = parse_json(json_string)
except ValueError as e:
    raise ConfigurationError(f"Failed to parse config: {e}") from e
```

### Never Ignore Exceptions (BLOCKER)
- **Never catch and ignore**: Always log or re-raise
- **Always access exception variable**: If catching, you should handle it

**Noncompliant:**
```python
# ❌ Silent failure - NEVER do this
try:
    risky_operation()
except SpecificError:
    pass  # Silently ignores error
```

**Compliant:**
```python
# ✅ Log and re-raise
try:
    risky_operation()
except SpecificError as e:
    logger.exception("Operation failed")
    raise

# ✅ Or handle appropriately
try:
    risky_operation()
except SpecificError as e:
    logger.warning("Retrying operation: %s", str(e))
    return None
```

### Custom Exceptions
- **Meaningful class names**: Describe what went wrong
- **Include docstrings**: Explain purpose
- **Preserve cause**: Constructor with cause parameter

**Compliant:**
```python
class ValidationError(ValueError):
    """Raised when validation fails."""
    pass

class ConfigurationError(RuntimeError):
    """Raised when configuration is invalid."""
    pass

# Usage
try:
    data = parse_config(config_file)
except ValueError as e:
    raise ConfigurationError(f"Invalid config: {e}") from e
```

### Use Context Managers
- **Clean up resources**: Automatically on exit
- **Use with statement**: For resource management
- **Create custom**: When needed for domain logic

**Noncompliant:**
```python
# ❌ Manual cleanup
file = open('data.txt', 'r')
try:
    content = file.read()
finally:
    file.close()  # Easy to forget
```

**Compliant:**
```python
# ✅ Automatic cleanup with context manager
with open('data.txt', 'r') as file:
    content = file.read()
```

---

## 7. Imports and Module Organization (MANDATORY)

### Import Organization
- **Standard library** imports first
- **Third-party imports** second
- **Local imports** last
- **Alphabetical** within groups

**Noncompliant:**
```python
import requests
import os
from mymodule import something
import sys
```

**Compliant:**
```python
import os
import sys
from datetime import datetime
from typing import List, Optional

import requests
import numpy as np

from . import config
from .models import User
```

### Unused Imports
- **Remove unused imports** (MAJOR violation)
- **Use linting tools**: flake8, pylint to detect
- **Never use `import *`**: Explicit is better than implicit

**Noncompliant:**
```python
# ❌ Unused imports
import os  # Not used
from typing import Dict  # Not used
from mymodule import *  # Implicit
```

**Compliant:**
```python
# ✅ Only needed imports
from typing import List
from mymodule import specific_function

# ✅ or use explicit imports
from mymodule import function1, function2
```

### Circular Import Prevention
- **Design to avoid**: Circular imports indicate design issues
- **Use TYPE_CHECKING**: For type hints only

**Compliant:**
```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from other_module import SomeClass

def function(obj: 'SomeClass') -> None:
    pass
```

---

## 8. Documentation and Comments (MANDATORY)

### Docstrings (Google Style Required)
- **All public functions** must have docstrings
- **All classes** must have docstrings
- **Module-level docstring**: At top of file
- **Format**: Google style docstrings

**Noncompliant:**
```python
# ❌ Missing docstring
def calculate_total(items, tax_rate):
    return sum(items) * (1 + tax_rate)

# ❌ Poor docstring
def process_order(order):
    """Does something with order."""
    pass
```

**Compliant:**
```python
# ✅ Complete Google-style docstring
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

### Class Docstrings
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

### Inline Comments
- **Explain WHY, not WHAT**: Code should be self-explanatory
- **Keep updated**: Or remove
- **Avoid commented code**: Use version control

**Noncompliant:**
```python
# ❌ Explains what, not why
x = y + z  # Add y and z to x

# ❌ Commented-out code
# old_value = calculate()
# result = process(old_value)
```

**Compliant:**
```python
# ✅ Explains why
# Remove outliers (values > 3 standard deviations)
# using modified Z-score method
mean = sum(data) / len(data)
std_dev = (sum((x - mean) ** 2 for x in data) / len(data)) ** 0.5
threshold = 3 * std_dev
filtered_data = [x for x in data if abs(x - mean) <= threshold]
```

---

## 9. Testing and Coverage (MANDATORY)

### Test Structure
- **Test all public functions**: Comprehensive coverage
- **Test edge cases**: Boundaries, None, empty collections
- **Test failure scenarios**: Exception paths
- **Test isolation**: No dependencies between tests
- **Fast tests**: Unit tests should be milliseconds

### Test Organization
- **Parallel structure**: Tests mirror main code
- **Test directory**: `tests/` or `test_*` files
- **Test class names**: Match source with `Test` prefix or `_test.py` suffix
- **Test method names**: Descriptive, follow pattern

**Compliant:**
```python
# tests/test_order_service.py
import pytest

class TestOrderService:
    """Test suite for OrderService."""
    
    def setup_method(self):
        """Setup before each test."""
        self.service = OrderService()
    
    def test_calculate_total_with_valid_items(self):
        """Test calculating total with valid items."""
        # Arrange
        items = [Item(price=10.0), Item(price=20.0)]
        
        # Act
        result = self.service.calculate_total(items, 0.08)
        
        # Assert
        assert result == pytest.approx(32.4, rel=1e-2)
    
    def test_calculate_total_with_empty_items_raises_error(self):
        """Test calculating total raises error with empty items."""
        with pytest.raises(ValueError, match="Items list cannot be empty"):
            self.service.calculate_total([], 0.08)
```

### Fixtures and Setup
- **Use fixtures**: For common setup
- **Clean isolation**: Each test independent
- **@pytest.fixture**: For reusable setup

**Compliant:**
```python
@pytest.fixture
def sample_user():
    """Fixture providing sample user."""
    return User(name="John Doe", email="john@example.com")

@pytest.fixture
def database():
    """Fixture providing test database."""
    db = TestDatabase()
    yield db
    db.close()  # Cleanup

def test_create_user(database, sample_user):
    """Test creating user in database."""
    result = database.create(sample_user)
    assert result.id is not None
```

### Mocking External Dependencies
- **Mock external calls**: Databases, APIs, file systems
- **Use unittest.mock**: For mocking
- **Verify interactions**: When behavior matters

**Compliant:**
```python
from unittest.mock import Mock, patch

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
```

### Code Coverage
- **Minimum 80% coverage**: For public code
- **Use pytest-cov**: Measure coverage
- **Run coverage reports**: Before commit

```bash
pytest --cov=src --cov-report=html
```

---

## 10. Security (CRITICAL)

### Input Validation
- **Validate all input**: Never trust user input
- **Whitelist validation**: Define what's allowed
- **Type checking**: Use type hints with mypy

**Noncompliant:**
```python
# ❌ No validation
def create_user(email: str):
    user = User(email=email)
    save(user)

# ❌ Weak validation
def validate_age(age):
    if age > 0:
        return True
    return False
```

**Compliant:**
```python
# ✅ Proper validation
import re

def validate_email(email: str) -> str:
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(pattern, email):
        raise ValueError("Invalid email format")
    return email.lower()

def validate_age(age: int) -> int:
    if not isinstance(age, int) or age < 0 or age > 150:
        raise ValueError("Age must be between 0 and 150")
    return age
```

### Sensitive Data Protection
- **Never log passwords**: Or sensitive information
- **Use getpass**: For interactive password input
- **Clear from memory**: When possible

**Noncompliant:**
```python
# ❌ Never log sensitive data
logger.info(f"User login: {username}, password: {password}")
password_str = user_input  # String is immutable
```

**Compliant:**
```python
# ✅ Log safely
logger.info(f"User login: {username}")

# ✅ Use getpass for interactive
import getpass
password = getpass.getpass("Enter password: ")
```

### SQL Injection Prevention
- **Parameterized queries**: Always use parameters
- **Use ORMs**: Like SQLAlchemy, Django ORM
- **Never string concatenation**: For queries

**Noncompliant:**
```python
# ❌ SQL Injection vulnerability
query = f"SELECT * FROM users WHERE username='{username}'"
cursor.execute(query)

# ❌ String formatting
query = "SELECT * FROM users WHERE username='%s'" % username
```

**Compliant:**
```python
# ✅ Parameterized query
cursor.execute("SELECT * FROM users WHERE username=?", (username,))

# ✅ Using ORM (best practice)
user = session.query(User).filter(User.username == username).first()
```

### Dependencies
- **Keep updated**: Audit for vulnerabilities
- **Minimal dependencies**: Reduce attack surface
- **Use requirements.txt**: Lock versions

```bash
# Audit dependencies
pip install pip-audit
pip-audit
```

---

## 11. Performance (MAJOR)

### Collections and Iteration
- **Choose right collection**: List, Set, Dict based on use
- **List comprehensions**: Efficient for creating lists
- **Generators**: For memory efficiency with large sequences
- **Use built-in functions**: Optimized in C

**Compliant:**
```python
# Efficient list comprehension
squares = [x ** 2 for x in range(10)]

# Generators for memory efficiency
def process_large_file(filepath):
    with open(filepath) as f:
        for line in f:
            yield line.strip()

# Use set for membership testing
if item in large_set:  # O(1) vs O(n) for list
    pass
```

### String Operations
- **Use f-strings**: Preferred and fast
- **str.join()**: For multiple strings
- **Avoid concatenation**: In loops

**Noncompliant:**
```python
# ❌ Inefficient
result = ""
for item in items:
    result += str(item)  # Creates new string each time
```

**Compliant:**
```python
# ✅ Efficient
result = "".join(str(item) for item in items)

# ✅ Or use f-string with join
items_str = [f"{i}: {item}" for i, item in enumerate(items)]
result = "\n".join(items_str)
```

### Avoid Premature Optimization
- **Profile first**: Don't guess bottlenecks
- **Readable first**: Then optimize if needed
- **Measure impact**: Verify optimization helps

```python
import timeit

# Profile two approaches
approach1_time = timeit.timeit(lambda: list_approach(), number=100)
approach2_time = timeit.timeit(lambda: set_approach(), number=100)
print(f"List: {approach1_time:.6f}s, Set: {approach2_time:.6f}s")
```

---

## 12. Code Complexity (MAJOR)

### Function Complexity
- **Maximum 20-30 lines**: Keep functions small
- **Reduce nesting**: Maximum 3 levels
- **Use early returns**: Avoid deep nesting
- **Extract complexity**: Into separate functions

**Noncompliant:**
```python
# ❌ Complex, deeply nested
def process_order(order):
    if order:
        if order.items:
            if order.items[0]:
                if order.items[0].quantity > 0:
                    if order.items[0].price > 0:
                        # 40 lines of logic here
                        pass
```

**Compliant:**
```python
# ✅ Simple, early returns
def process_order(order: Order) -> None:
    if not order or not order.items:
        return
    
    for item in order.items:
        if not is_valid_item(item):
            continue
        process_item(item)

def is_valid_item(item: Item) -> bool:
    return item.quantity > 0 and item.price > 0
```

### Cyclomatic Complexity
- **Measure with tools**: radon, lizard
- **Keep under 10**: Parameter limit
- **Break up complex logic**: Into helper functions

```bash
# Check complexity
pip install radon
radon cc src/ -a
```

### Code Duplication
- **No duplicate code**: Copy-paste indicates refactoring needed
- **Extract to functions**: Reuse common logic
- **Use inheritance/composition**: For shared behavior

**Noncompliant:**
```python
# ❌ Duplicated code
def process_user_data(user_id):
    user = get_user(user_id)
    if not user:
        raise ValueError("User not found")
    if not user.is_active:
        raise ValueError("User not active")
    return user

def process_customer_data(customer_id):
    customer = get_customer(customer_id)
    if not customer:
        raise ValueError("Customer not found")
    if not customer.is_active:
        raise ValueError("Customer not active")
    return customer
```

**Compliant:**
```python
# ✅ Extracted to common function
def validate_entity(entity, entity_type):
    if not entity:
        raise ValueError(f"{entity_type} not found")
    if not entity.is_active:
        raise ValueError(f"{entity_type} not active")
    return entity

def process_user_data(user_id):
    user = get_user(user_id)
    return validate_entity(user, "User")

def process_customer_data(customer_id):
    customer = get_customer(customer_id)
    return validate_entity(customer, "Customer")
```

---

## Code Quality Tools (MANDATORY)

### Black - Code Formatting
```bash
black src/  # Format code
black --check src/  # Check without modifying
```

### Flake8 - Linting
```bash
flake8 src/  # Run linter

# Configuration in .flake8
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = .venv,build,dist
```

### MyPy - Type Checking
```bash
mypy src/  # Check types

# Configuration in pyproject.toml
[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
```

### Pytest - Testing
```bash
pytest  # Run all tests
pytest --cov=src  # With coverage
pytest -v  # Verbose output
```

### Pylint - Static Analysis
```bash
pylint src/  # Check code quality
```

---

## Summary

All Python code must comply with these standards before merge:

✅ **Naming**: snake_case functions, PascalCase classes, UPPER_SNAKE_CASE constants
✅ **Formatting**: 4 spaces, 88-char lines, proper spacing and blank lines
✅ **Type Hints**: Function signatures, return types, complex types annotated
✅ **Functions**: Small (20-30 lines), max 3-4 params, single responsibility
✅ **Classes**: Single responsibility, encapsulation, inheritance vs composition
✅ **Exceptions**: Specific catches, never ignore, chain with `from`
✅ **Imports**: Organized by stdlib/third-party/local, no unused imports
✅ **Documentation**: Google-style docstrings, explain why not what
✅ **Testing**: Comprehensive coverage (80%+), fixtures, mocking, isolation
✅ **Security**: Input validation, parameterized queries, protect sensitive data
✅ **Performance**: Right collections, f-strings, list comprehensions, avoid duplication
✅ **Complexity**: Small functions, max 3 nesting levels, DRY principle
✅ **Code Quality**: Pass black, flake8, mypy, pytest before commit

Use code quality tools (`black`, `flake8`, `mypy`, `pytest`) to validate automatically before committing. Follow "Clean Code" principles and PEP 8/20 for additional guidance.
