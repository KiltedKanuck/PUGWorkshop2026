---
applyTo: '**/*.{cpp,hpp,cc,hh,cxx,hxx}'
---

# Code Review Standards for C++ Programming

## Overview

This document contains comprehensive mandatory code review rules for **C++ programming** (not C or C#). All code must comply with these standards before merge.

**IMPORTANT**: This project uses **C++11 standard only**. C++14 and C++17 features are NOT available.

**Severity Indicators**:
- **MANDATORY**: Must be followed - code will be rejected if not compliant
- **CRITICAL**: Causes bugs, security issues, or compilation failures
- **Required**: Standard practice that should always be followed
- **Recommended**: Best practice that improves code quality

**Related Documentation**: See [general-cpp-instructions.md](general-cpp-instructions.md) for quick-reference coding guidelines, best practices, and project structure requirements.

---

## Standards Overview

This document covers:
1. Variable naming conventions (MANDATORY)
2. Function/Method naming standards (MANDATORY)
3. Class and namespace naming (MANDATORY)
4. Global variable restrictions (CRITICAL)
5. Type definitions and aliases (MANDATORY)
6. Data type guidelines (MANDATORY)
7. Code formatting rules (MANDATORY)
8. Memory management and RAII (CRITICAL)
9. Const correctness (MANDATORY)
10. Class design (Rule of Zero/Three/Five) (MANDATORY)
11. Best practices (Required)
12. Exception handling (MANDATORY)
13. Smart pointer usage (MANDATORY)
14. Sonarqube compliance (MANDATORY)
15. Header file organization (MANDATORY)
16. Copyright requirements (MANDATORY)
17. Testing standards (Required)

---

## Naming Conventions

## Variable Names (MANDATORY)
- Must be meaningful and comprehensible words
- Cannot match any global variable names
- Should use full words with allowed abbreviations:
  - `Mgr` for Manager
  - `Chk` for Check
- Follow lower camel case:
  - Start with lowercase
  - Capitalize subsequent words
  - Example: `firstName`, `lastName`, `transactionId`
- Acronyms follow camel case:
  - `Dom` for DOM
  - `Xml` for XML
- No single-letter names (including loop counters)
  - **Exception**: Iterator contexts (`i`, `j` acceptable in limited scope)

### Member Variable Naming
- Use camel case

### Example Variable Names

❌ Incorrect:
```cpp
long *trid;          // unclear abbreviation, wrong type case
DBKEY fib;           // ambiguous naming
int **st;            // too short
std::string XML;     // wrong acronym case
```

✅ Correct:
```cpp
LONG*              pTransactionId;    // Legacy style
DBKEY              firstIndexBlock;
int**              ppSleepTime;       // Legacy style
std::string        xmlContent;        // Correct acronym case
std::unique_ptr<Transaction> transaction;  // Modern style
```

## Class Names (MANDATORY)
- Use PascalCase (capitalize first letter of each word)
- Must be descriptive and unique
- Prefix with subsystem abbreviation for Progress-specific classes
- No conflicts with 3rd party software or STL classes

### Example Class Names

❌ Incorrect:
```cpp
class transaction_manager { };   // Wrong case
class TxnMgr { };                // Over-abbreviated
class transaction { };           // Too generic, conflictswith std::
```

✅ Correct:
```cpp
class TransactionManager { };
class MasterBlock { };
class ProtocolProcessor { };
class DatabaseConnection { };
```

## Method Names (MANDATORY)
- Use camelCase (lowercase first letter, capitalize subsequent words)
- Public methods: Use descriptive verbs
  - `processTransaction()`, `validateInput()`, `getConnectionStatus()`
- Accessors/Mutators: Use `get`/`set` prefix
  - `getValue()`, `setValue()`, `getName()`, `setName()`

### Example Method Names

❌ Incorrect:
```cpp
class MyClass
{
public:
    void ProcessData();      // Wrong case (PascalCase)
    int value();             // Missing 'get' prefix
    void value(int v);       // Missing 'set' prefix
};
```

✅ Correct:
```cpp
class MyClass
{
public:
    void processData();
    int getValue() const;
    void setValue(int value);

private:
    void processInternal();
};
```

## Function Names (Non-member, MANDATORY)
- Use camel case

### Example Function Names

❌ Incorrect:
```cpp
void bklocmb() { }           // Abbreviated
void ProcessTransaction() { } // Missing prefix, wrong case
```

✅ Correct:
```cpp
void bmLockDownMasterBlock() { }      // Progress-specific

namespace progress {
    void processTransaction() { }      // Namespaced, no prefix needed
}
```

## Namespace Names (MANDATORY)
- Use lowercase with underscores if needed
- Avoid deeply nested namespaces (max 3 levels)
- Use descriptive names

### Example Namespace Names

❌ Incorrect:
```cpp
namespace Progress { }           // Wrong case
namespace Prog::SW::DB::Conn { } // Too deeply nested
```

✅ Correct:
```cpp
namespace progress { }
namespace progress::database { }
namespace util { }
```

## Constant and Enum Names (MANDATORY)
- Constants: `ALL_CAPS` with underscores
- Enum classes: `enum class` PascalCase, values PascalCase

### Example Constants and Enums

❌ Incorrect:
```cpp
const int maxSize = 1024;           // Wrong case
enum Status { success, failure };   // Use enum class
```

✅ Correct:
```cpp
const int MAX_BUFFER_SIZE = 1024;
constexpr int MAX_CONNECTIONS = 100;

enum class Status
{
    Success,
    Failure,
    Pending
};
```

---

## Global Variables (CRITICAL)

### General Rules
- **Avoid adding new global variables**
- Exception: Constants declared as `const` or `constexpr`
- Use namespaces for constants

### Constants Example
```cpp
namespace constants
{
    constexpr int MAX_SIZE = 1024;
    const std::string DEFAULT_NAME = "default";
}
```

### PASOE Multi-Threading Considerations
- Global variables are problematic for thread safety
- Each thread may need local storage
- **Alternative**: Use context structures, dependency injection, or Meyer's singleton

### Singleton Pattern (If truly needed)
```cpp
class DatabaseManager
{
public:
    static DatabaseManager& getInstance()
    {
        static DatabaseManager instance;  // Thread-safe in C++11+
        return instance;
    }
    
    // Delete copy and move
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;
    DatabaseManager(DatabaseManager&&) = delete;
    DatabaseManager& operator=(DatabaseManager&&) = delete;

private:
    DatabaseManager() = default;
    ~DatabaseManager() = default;
};
```

### Important Notes
- Avoid naming conflicts between local and global variables
- Global mutable state breaks thread safety
- Modern C++ alternatives: dependency injection, context objects, std::thread_local

---

## Type Definitions (MANDATORY)

### General Rules
- **Use `using` instead of `typedef`** for new code
- Do NOT use macros for type definitions
- Avoid typedef for structures - use `struct`/`class` directly
- Use template aliases for generic types

### Type Alias Examples

❌ Incorrect Usage:
```cpp
typedef std::shared_ptr<Transaction> TransactionPtr;  // Old style
#define STRING std::string                             // Don't use macro
Long myLong;                                           // Wrong case
```

✅ Correct Usage:
```cpp
using TransactionPtr = std::shared_ptr<Transaction>;
using StringVector = std::vector<std::string>;

template<typename T>
using Vec = std::vector<T>;
```

### Structure Naming
- Use `struct` for data structures (POD types)
- Use `class` for objects with invariants
- Prefix with subsystem two-letter prefix (Progress-specific)
- Must be descriptive and unique

### Examples

❌ Incorrect:
```cpp
struct layout { };           // Missing prefix, too generic
class data { };              // Too generic
typedef struct Data {} DATA; // Old-style typedef
```

✅ Correct:
```cpp
struct SmLayout              // Progress-specific
{
    SmFrame*       pSmFrame;
    RnFrame*       pRnFrame;
    SmUIC*         pSmUic;
};

class TransactionManager     // Application class
{
    // ...
};
```

---

## Data Type Guidelines (MANDATORY)

### Modern C++ Types (Preferred)
- `std::string` - For strings (prefer over `TEXT*`)
- `std::vector<T>` - For dynamic arrays
- `std::array<T, N>` - For fixed-size arrays
- `std::unique_ptr<T>` - For exclusive ownership
- `std::shared_ptr<T>` - For shared ownership
- `std::weak_ptr<T>` - For non-owning references
- `size_t` - For sizes and indices
- `bool` - For boolean values
- `nullptr` - For null pointers (not NULL or 0)
- **Note**: `std::optional` and `std::variant` are C++17 features and NOT available

### Obsolete Types (Do Not Use)
- `register` - Obsolete keyword
- `auto_ptr` - Deprecated, use `std::unique_ptr`
- `NULL` - Use `nullptr`

### 64-bit Considerations
- `sizeof(LONG)` = 32 bits (always)
- `sizeof(long)` = 64 bits on 64-bit systems (platform dependent)
- `sizeof(void*)` = 64 bits on 64-bit systems
- Use `uintptr_t`/`intptr_t` for pointer arithmetic

### Type Safety
- Use `enum class` for strongly-typed enumerations
- Avoid C-style casts - use `static_cast`, `const_cast`, `reinterpret_cast`, `dynamic_cast`
- Use `std::optional<T>` instead of sentinel values
- Prefer compile-time checks with `static_assert`

---

## Memory Management and RAII (CRITICAL)

### RAII Principle (MANDATORY)
- **Resource Acquisition Is Initialization**
- Resources acquired in constructor, released in destructor
- No manual `new`/`delete` - use smart pointers
- No manual resource management - use RAII wrappers

### Smart Pointers (MANDATORY)

#### `std::unique_ptr<T>` - Exclusive Ownership
```cpp
// ✅ Correct: Use unique_ptr constructor (make_unique is C++14)
auto transaction = std::unique_ptr<Transaction>(new Transaction());
// Or with explicit type
std::unique_ptr<Transaction> transaction(new Transaction());

// ❌ Incorrect: Manual new/delete
Transaction* transaction = new Transaction();
delete transaction;  // Error-prone, forget to call
```

#### `std::shared_ptr<T>` - Shared Ownership
```cpp
// ✅ Correct: Use make_shared (use sparingly)
auto connection = std::make_shared<DatabaseConnection>();

// ✅ Alternative: Direct construction if needed
std::shared_ptr<DatabaseConnection> connection(new DatabaseConnection());

// ❌ Incorrect: Overuse of shared_ptr
std::shared_ptr<int> number = std::make_shared<int>(42);  // Overkill
```

#### `std::weak_ptr<T>` - Non-owning Reference
```cpp
class Node
{
    std::shared_ptr<Node> next_;
    std::weak_ptr<Node> prev_;  // Breaks cycles
};
```

### Custom Deleters (Progress Legacy Integration)
```cpp
// Wrapping Progress memory functions
auto deleter = [](void* p) { utfree(p); };
std::unique_ptr<MyType, decltype(deleter)> ptr(
    static_cast<MyType*>(utmalloc(sizeof(MyType))),
    deleter
);

// Or create an alias
template<typename T>
using UtPtr = std::unique_ptr<T, void(*)(void*)>;

UtPtr<MyType> createMyType()
{
    return UtPtr<MyType>(
        static_cast<MyType*>(utmalloc(sizeof(MyType))),
        [](void* p) { utfree(p); }
    );
}
```

### STL Containers (Preferred)
```cpp
// ✅ Correct: Use STL containers
std::vector<int> numbers;
std::array<char, 256> buffer;
std::string text;

// ❌ Incorrect: Manual arrays with new/delete
int* numbers = new int[100];
delete[] numbers;  // Error-prone
```

### Progress Legacy Memory Management
When interfacing with C code:

**Parameter Stack (Short-term, <100K)**
```cpp
stkpsh();  // Push stack frame
// ... use stack
stkpop();  // Always match with push (consider RAII wrapper)
```

**Pool Memory**
```cpp
stget();              // Allocate from pool
strent()/stvacate();  // When tracking needed
```

**System Memory**
```cpp
utmalloc();  // Use this, not malloc()
utfree();    // Use this, not free()
```

### RAII Wrappers (Recommended)
```cpp
class StackGuard
{
public:
    StackGuard() { stkpsh(); }
    ~StackGuard() { stkpop(); }
    
    StackGuard(const StackGuard&) = delete;
    StackGuard& operator=(const StackGuard&) = delete;
};

// Usage
void myFunction()
{
    StackGuard guard;  // Automatic cleanup
    // ... use stack
}  // stkpop() called automatically
```

---

## Const Correctness (MANDATORY)

### Const Member Functions
```cpp
class MyClass
{
public:
    // ✅ Correct: Mark methods const if they don't modify
    int getValue() const { return value_; }
    const std::string& getName() const { return name_; }
    
    // ❌ Incorrect: Missing const
    int getValue() { return value_; }  // Should be const

private:
    int value_;
    std::string name_;
};
```

### Const Parameters
```cpp
// ✅ Correct: Pass by const reference
void processData(const std::string& data, const std::vector<int>& numbers);

// ❌ Incorrect: Unnecessary copying
void processData(std::string data, std::vector<int> numbers);

// ✅ Correct: Output parameter (non-const reference)
void getValues(int& x, int& y);
```

### Const Return Values
```cpp
class MyClass
{
public:
    // ✅ Correct: Return const reference to member
    const std::string& getName() const { return name_; }
    
    // ⚠️ Careful: Don't return const reference to local
    const std::string& getBadName() const
    {
        std::string local = "bad";
        return local;  // ❌ Dangling reference!
    }
    
    // ✅ Correct: Return by value for local/temporary
    std::string getFullName() const
    {
        return firstName_ + " " + lastName_;  // RVO will optimize
    }

private:
    std::string name_;
    std::string firstName_;
    std::string lastName_;
};
```

### Const Pointers
```cpp
const int* pData;      // Pointer to const data
int* const pData;      // Const pointer to data
const int* const pData; // Const pointer to const data

// ✅ Prefer references or const references
const int& data;       // Reference to const data
```

### Constexpr (Compile-time Constants)
```cpp
// ✅ Correct: Use constexpr for compile-time constants
constexpr int MAX_SIZE = 100;
constexpr double PI = 3.14159265359;

// ✅ Correct: Constexpr functions
constexpr int square(int x)
{
    return x * x;
}

// Usage in array size
int array[square(5)];  // Legal, computed at compile-time
```

---

## Class Design (MANDATORY)

### Rule of Zero/Three/Five

#### Rule of Zero (Preferred)
```cpp
// ✅ Correct: Let compiler generate everything
class DataHolder
{
public:
    DataHolder() = default;
    // Compiler generates copy, move, destructor
    
private:
    std::string name_;
    std::vector<int> data_;
    std::unique_ptr<Resource> resource_;
};
```

#### Rule of Five (When needed)
```cpp
class ResourceManager
{
public:
    // Constructor
    ResourceManager();
    
    // Destructor
    ~ResourceManager();
    
    // Copy constructor
    ResourceManager(const ResourceManager& other);
    
    // Copy assignment
    ResourceManager& operator=(const ResourceManager& other);
    
    // Move constructor
    ResourceManager(ResourceManager&& other) noexcept;
    
    // Move assignment
    ResourceManager& operator=(ResourceManager&& other) noexcept;
};
```

#### Disabling Copy/Move
```cpp
class NonCopyable
{
public:
    NonCopyable() = default;
    
    // ✅ Correct: Explicitly delete
    NonCopyable(const NonCopyable&) = delete;
    NonCopyable& operator=(const NonCopyable&) = delete;
    
    // Allow move
    NonCopyable(NonCopyable&&) noexcept = default;
    NonCopyable& operator=(NonCopyable&&) noexcept = default;
};
```

### Virtual Functions and Inheritance

#### Virtual Destructor (MANDATORY for base classes)
```cpp
class Base
{
public:
    virtual ~Base() = default;  // ✅ Virtual destructor required
    virtual void doSomething() = 0;
};

class Derived : public Base
{
public:
    ~Derived() override = default;
    void doSomething() override;  // ✅ Use override keyword
};
```

#### Override and Final
```cpp
class Base
{
public:
    virtual void method();
    virtual void finalMethod() final;  // ✅ Cannot be overridden
};

class Derived : public Base
{
public:
    void method() override;      // ✅ Correct: Use override
    // void finalMethod() override;  // ❌ Error: Base::finalMethod is final
};

class FinalClass final  // ✅ Cannot be inherited
{
    // ...
};
```

### Constructor Guidelines

#### Initialization Lists (MANDATORY)
```cpp
class MyClass
{
public:
    // ✅ Correct: Use initialization lists
    MyClass(int value, std::string name)
        : value_(value)
        , name_(std::move(name))
    {
    }
    
    // ❌ Incorrect: Assignment in body
    MyClass(int value, std::string name)
    {
        value_ = value;
        name_ = name;
    }

private:
    int value_;
    std::string name_;
};
```

#### Explicit Constructors
```cpp
class Transaction
{
public:
    // ✅ Correct: Explicit to prevent implicit conversion
    explicit Transaction(int id);
    
    // Implicit conversion allowed for multi-param
    Transaction(int id, std::string name);
};

// Usage
Transaction t1(42);           // ✅ OK
Transaction t2 = 42;          // ❌ Error: explicit prevents this
Transaction t3(42, "test");   // ✅ OK
Transaction t4 = {42, "test"};  // ✅ OK: braces allowed
```

#### Delegating Constructors
```cpp
class MyClass
{
public:
    MyClass() : MyClass(0, "default") { }
    
    MyClass(int value) : MyClass(value, "default") { }
    
    MyClass(int value, std::string name)
        : value_(value)
        , name_(std::move(name))
    {
        // Common initialization
    }

private:
    int value_;
    std::string name_;
};
```

---

## Code Formatting Rules (MANDATORY)

### Indentation and Spacing
1. **NO TAB CHARACTERS** - Use spaces only for indentation
2. **4 spaces per indentation level** (absolutely no tabs)
3. Configure your editor to insert spaces (not tabs) when Tab key is pressed
4. Enable visible whitespace characters in editor to detect tabs
5. **Spaces around operators**: `a + b` not `a+b`
6. **Spaces after keywords**: `if (condition)` not `if(condition)`
7. **Blank line after control structures**: After `if`/`switch`/`while`/`for`

### Curly Braces (MANDATORY)
- **Opening brace on new line** (Allman style)
- **Aligned with their pair**
- **Mandatory for all loops** and conditional blocks

```cpp
// ✅ Correct
if (condition)
{
    doSomething();
}
else
{
    doSomethingElse();
}

for (int idx = 0; idx < count; ++idx)
{
    process(idx);
}

class MyClass
{
public:
    void method()
    {
        // body
    }
};

// ❌ Incorrect
if (condition) {  // Wrong: brace on same line
    doSomething();
}

if (condition)
    doSomething();  // ❌ Missing braces
```

### Statements and Assignments
1. **One statement per line**
2. **One declaration per line**
3. **Don't combine `if` and action** on same line
4. **No chained assignments**: Avoid `a = b = c;`

```cpp
// ✅ Correct
int x = 5;
int y = 10;

if (condition)
{
    doSomething();
}

// ❌ Incorrect
int x = 5, y = 10;  // Multiple declarations
if (condition) doSomething();  // Action on same line
int a = b = c = 0;  // Chained assignment
```

### Class Member Order
```cpp
class MyClass
{
public:
    // Public types and constants
    enum class Status { Active, Inactive };
    
    // Constructors and destructor
    MyClass();
    ~MyClass();
    
    // Public interface
    void publicMethod();
    int getValue() const;

protected:
    // Protected members
    void protectedMethod();

private:
    // Private types
    struct PrivateData;
    
    // Private methods
    void privateMethod();
    
    // Private data members (last)
    int value_;
    std::string name_;
    std::unique_ptr<PrivateData> data_;
};
```

---

## Exception Handling (MANDATORY)

### Exception Guidelines
- **Use exceptions for exceptional conditions** (not control flow)
- **Provide at least basic exception safety guarantee**
- **Strong exception safety preferred** when possible
- **No-throw guarantee** for destructors, move operations, swap

### Exception Safety Levels
```cpp
class SafeClass
{
public:
    // ✅ Basic guarantee: No resource leaks, invariants preserved
    void basicSafe()
    {
        auto resource = std::unique_ptr<Resource>(new Resource());
        resource->process();  // May throw, but unique_ptr cleans up
    }
    
    // ✅ Strong guarantee: Commit-or-rollback semantics
    void strongSafe(const Data& newData)
    {
        Data copy = newData;     // Copy first
        data_.swap(copy);        // Only commit if copy succeeds
    }
    
    // ✅ No-throw guarantee: Never throws
    void swap(SafeClass& other) noexcept
    {
        data_.swap(other.data_);
    }
    
    // ✅ Destructor must not throw
    ~SafeClass() noexcept
    {
        // Cleanup, should never throw
    }

private:
    Data data_;
};
```

### Throwing Exceptions
```cpp
class CustomException : public std::runtime_error
{
public:
    explicit CustomException(const std::string& message)
        : std::runtime_error(message)
    {
    }
};

void validateInput(int value)
{
    if (value < 0)
    {
        throw std::invalid_argument("Value must be non-negative");
    }
    
    if (value > MAX_VALUE)
    {
        throw CustomException("Value exceeds maximum");
    }
}
```

### Catching Exceptions
```cpp
// ✅ Correct: Catch by const reference
try
{
    processData();
}
catch (const CustomException& e)
{
    handleCustom(e);
}
catch (const std::exception& e)
{
    handleGeneric(e);
}
catch (...)
{
    handleUnknown();
}

// ❌ Incorrect: Catch by value (slicing)
catch (std::exception e)  // Don't do this
{
    // ...
}
```

### Noexcept Specification
```cpp
class MyClass
{
public:
    // ✅ Destructors should be noexcept
    ~MyClass() noexcept;
    
    // ✅ Move operations should be noexcept
    MyClass(MyClass&&) noexcept;
    MyClass& operator=(MyClass&&) noexcept;
    
    // ✅ Swap should be noexcept
    void swap(MyClass& other) noexcept;
    
    // ✅ Mark functions noexcept when they won't throw
    int getValue() const noexcept;
    
    // Not noexcept if it might throw
    void processData();  // May throw
};
```

---

## Modern C++ Features (C++11/14/17)

### Auto Type Deduction
```cpp
// ✅ Correct usage: Obvious types, iterators, lambdas
auto value = getValue();  // Return type is clear from function name
auto it = container.begin();  // Iterator type is verbose
auto lambda = [](int x) { return x * 2; };

// ❌ Avoid: Not obvious what type is
auto mystery = calculateSomething();  // What type is returned?

// ✅ Prefer explicit type for clarity
std::string name = getName();
int count = getCount();
```

### Range-Based For Loop
```cpp
// ✅ Correct: Iterate over containers
for (const auto& item : container)
{
    process(item);
}

// ✅ Correct: Modify elements
for (auto& item : container)
{
    item.update();
}

// ❌ Incorrect: Unnecessary copy
for (auto item : container)  // Copies each item
{
    // ...
}
```

### Lambda Expressions
```cpp
// ✅ Correct: Capture by value when needed
int threshold = 10;
auto isAboveThreshold = [threshold](int value)
{
    return value > threshold;
};

// ✅ Correct: Capture by reference (be careful of lifetime)
int sum = 0;
std::for_each(vec.begin(), vec.end(), [&sum](int value)
{
    sum += value;
});

// ✅ Correct: Default capture (use sparingly)
auto lambda = [=]() { return x + y; };  // Capture all by value
auto lambda = [&]() { x += y; };        // Capture all by reference

// ⚠️ Careful: Dangling references
auto makeLambda()
{
    int local = 42;
    return [&local]() { return local; };  // ❌ Danglingreference!
}
```

### Nullptr
```cpp
// ✅ Correct: Use nullptr
int* pValue = nullptr;
if (pValue == nullptr)
{
    // ...
}

// ❌ Incorrect: Use of NULL or 0
int* pValue = NULL;  // Old style
int* pValue = 0;     // Ambiguous
```

### Strongly-Typed Enums
```cpp
// ✅ Correct: Use enum class
enum class Status
{
    Active,
    Inactive,
    Pending
};

Status status = Status::Active;

// ❌ Incorrect: Plain enum (pollutes namespace)
enum Status
{
    Active,    // Conflicts with other 'Active'
    Inactive,
    Pending
};
```

### Optional Values (C++11 Alternatives)
```cpp
// ✅ Correct: Use pair with bool for optional returns (std::optional is C++17)
std::pair<bool, int> findValue(const std::vector<int>& vec, int target)
{
    auto it = std::find(vec.begin(), vec.end(), target);
    if (it != vec.end())
    {
        return std::make_pair(true, *it);
    }
    return std::make_pair(false, int{});
}

// Usage
auto result = findValue(vec, 42);
if (result.first)
{
    std::cout << "Found: " << result.second << std::endl;
}

// ✅ Alternative: Use pointer (nullptr if not found)
const int* findValuePtr(const std::vector<int>& vec, int target)
{
    auto it = std::find(vec.begin(), vec.end(), target);
    if (it != vec.end())
    {
        return &(*it);
    }
    return nullptr;
}

// ❌ Incorrect: Using sentinel values
int findValue(const std::vector<int>& vec, int target)
{
    // ...
    return -1;  // What if -1 is a valid value?
}
```

---

## Best Practices (Required)

### Initialization
```cpp
// ✅ Correct: Uniform initialization
int value{42};
std::vector<int> numbers{1, 2, 3, 4, 5};
std::string text{};  // Empty string

// ✅ Correct: Initialize in declaration
int count = getCount();
auto data = loadData();

// ❌ Incorrect: Unnecessary default initialization
int result = 0;
result = calculate();  // Wasted initialization
```

### Prefer Stack Allocation
```cpp
// ✅ Correct: Stack allocation when possible
void processData()
{
    Transaction transaction;  // Stack allocated
    transaction.process();
}  // Automatically destroyed

// ❌ Incorrect: Unnecessary heap allocation
void processData()
{
    auto transaction = std::unique_ptr<Transaction>(new Transaction());
    transaction->process();
}  // unique_ptr overhead not needed here
```

### Use Algorithms
```cpp
// ✅ Correct: Use STL algorithms
auto it = std::find(vec.begin(), vec.end(), value);
std::sort(vec.begin(), vec.end());
std::transform(input.begin(), input.end(), output.begin(),
               [](int x) { return x * 2; });

// ❌ Incorrect: Manual loops when algorithm exists
for (size_t i = 0; i < vec.size(); ++i)
{
    if (vec[i] == value)
    {
        // found it
    }
}
```

### Avoid Premature Optimization
```cpp
// ✅ Correct: Clear code first
std::string buildMessage(const std::string& name)
{
    return "Hello, " + name + "!";  // RVO will optimize
}

// ❌ Incorrect: Premature optimization obscures intent
void buildMessage(char* buffer, const char* name)
{
    strcpy(buffer, "Hello, ");
    strcat(buffer, name);
    strcat(buffer, "!");
}
```

### Prefer ++i Over i++
```cpp
// ✅ Correct: Prefix increment (no temporary)
for (auto it = vec.begin(); it != vec.end(); ++it)
{
    // ...
}

// ⚠️ Acceptable for primitives, avoid for iterators
for (int i = 0; i < count; i++)  // OK for int
{
    // ...
}
```

---

## Sonarqube Compliance (MANDATORY)

### Function Complexity
- **Keep functions small** and focused (single responsibility)
- **Maximum 7 parameters** (use objects for more)
- **Avoid deep nesting**: Maximum 3 levels preferred
- **Cyclomatic complexity**: Keep low (< 15)
- **Cognitive complexity**: Minimize

### Code Quality
- **No code duplication**: Extract to functions/methods
- **Remove commented-out code**: Use version control
- **No unused variables**: Clean up
- **No unused parameters**: Use `[[maybe_unused]]` or cast to void
- **Handle all cases**: Switch on enums without default

### Example
```cpp
// ✅ Correct: Simple, focused function
int calculateTotal(const std::vector<int>& items)
{
    return std::accumulate(items.begin(), items.end(), 0);
}

// ❌ Incorrect: Too complex
int processData(int a, int b, int c, int d, int e, int f, int g, int h)
{
    if (a > 0)
    {
        if (b > 0)
        {
            if (c > 0)
            {
                // Too deeply nested
            }
        }
    }
}
```

---

## Header Files (MANDATORY)

### Header Guards
```cpp
// ✅ Correct: Include guards
#ifndef PROGRESS_SUBSYSTEM_FILENAME_HPP
#define PROGRESS_SUBSYSTEM_FILENAME_HPP

// Declarations

#endif /* PROGRESS_SUBSYSTEM_FILENAME_HPP */

// OR use #pragma once (if supported on all target platforms)
#pragma once

// Declarations
```

### Include Order
```cpp
// 1. Related header (for .cpp files)
#include "myclass.hpp"

// 2. C system headers
#include <cstdio>
#include <cstring>

// 3. C++ standard library headers
#include <iostream>
#include <string>
#include <vector>

// 4. Third-party libraries
#include <boost/shared_ptr.hpp>

// 5. Project headers
#include "progress/util.hpp"
#include "database/connection.hpp"
```

### Forward Declarations
```cpp
// ✅ Correct: Forward declare when possible
class Transaction;  // Forward declaration

class TransactionManager
{
public:
    void addTransaction(std::unique_ptr<Transaction> transaction);
    
private:
    std::vector<std::unique_ptr<Transaction>> transactions_;
};

// ❌ Incorrect: Unnecessary include
#include "transaction.hpp"  // Not needed in header if only using pointers
```

---

## Copyright Headers (MANDATORY)

### C++ Source Files (.cpp, .cc, .cxx)
```cpp
/*
 * Copyright (c) 2025-2026 Progress Software Corporation and/or its subsidiaries or
 * affiliates. All Rights Reserved.
 */
```

### Header Files (.hpp, .hh, .hxx)
```cpp
/*
 * Copyright (c) 2025-2026 Progress Software Corporation and/or its subsidiaries or
 * affiliates. All Rights Reserved.
 */
```

**If you are the first to modify a file in 2026, update the copyright year.**

---

## Testing Standards (Required)

### Unit Testing Requirements (MANDATORY)
- **Test framework**: Google Test (googletest)
- **Mocking framework**: Google Mock (gmock)
- Develop tests for all new functionality
- Cover all code paths including error conditions
- Test both success and error scenarios
- Mock external dependencies using Google Mock
- Verify RAII (no resource leaks)
- Test exception safety
- Test thread safety where applicable

### Test Structure
```cpp
TEST(MyClassTest, ConstructorInitializesCorrectly)
{
    // Arrange
    const int expectedValue = 42;
    
    // Act
    MyClass obj(expectedValue);
    
    // Assert
    EXPECT_EQ(obj.getValue(), expectedValue);
}

TEST(MyClassTest, ThrowsOnInvalidInput)
{
    // Arrange
    MyClass obj;
    
    // Act & Assert
    EXPECT_THROW(obj.processInvalidData(), std::invalid_argument);
}
```

### Testing Best Practices
- Use meaningful test names
- Arrange-Act-Assert pattern
- Test fixtures for common setup
- Parameterized tests for multiple inputs
- Test boundary conditions
- Memory leak detection (Valgrind, AddressSanitizer)
- Document test requirements

---

## Summary

All C++ code must follow these standards:

### Critical Rules (Must Pass Review)
1. ✅ Use modern C++ features (smart pointers, RAII, auto, range-for, lambdas)
2. ✅ Follow naming conventions (PascalCase classes, camelCase methods)
3. ✅ Apply RAII principle (automatic resource management)
4. ✅ Const correctness (const methods, const references, constexpr)
5. ✅ Rule of Zero/Three/Five (explicit special member control)
6. ✅ Use smart pointers (unique_ptr, shared_ptr)
7. ✅ Exception safety (noexcept destructors/moves, RAII cleanup)
8. ✅ Format code correctly (4 spaces, NO tab characters, braces on separate lines)
9. ✅ Header guards/pragma once
10. ✅ Include proper documentation
11. ✅ Write comprehensive unit tests
12. ✅ Pass Sonarqube quality checks
13. ✅ Compile without warnings on all platforms
14. ✅ Avoid global mutable state
15. ✅ Type safety (enum class, no C-style casts, use static_cast/dynamic_cast)

### Before Submitting Code
- [ ] All naming conventions followed
- [ ] RAII applied, no manual new/delete
- [ ] Const correctness applied
- [ ] Smart pointers used appropriately
- [ ] Rule of Zero/Three/Five followed
- [ ] Exception safety considered
- [ ] Code formatted correctly (4 spaces, NO tabs)
- [ ] Unit tests written and passing
- [ ] Sonarqube checks passing
- [ ] No warnings on all platforms
- [ ] Documentation complete
- [ ] Code reviewed against this document

---
