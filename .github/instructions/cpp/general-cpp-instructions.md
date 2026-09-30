---
applyTo: '**/*.{cpp,hpp,cc,hh,cxx,hxx}'
---

Provide project context and coding guidelines that AI should follow when generating C++ code, answering questions, or reviewing changes. This document is specifically for **C++ programming** (not C or C#).

**IMPORTANT**: This project uses **C++11 standard only**. C++14 and C++17 features are NOT YET available.

## Related Documentation

**IMPORTANT**: All code must also comply with [code-review-CPP-standards.md](code-review-CPP-standards.md), which contains comprehensive mandatory code review rules. Review those standards before submitting code.

---

## C++-Specific Guidelines

### Language Fundamentals
- **C++11 Standard**: Follow C++11 standard with Progress-specific extensions
  - **Note**: C++14 and C++17 features are NOT YET available
- **Platform Compatibility**: Code must compile without warnings on:
  - 64-bit Windows (MSVC)
  - 32-bit Windows (MSVC)
  - Linux (GCC/Clang - various distributions)
- **PASOE Multi-Threading**: Be aware of PASOE agent threading requirements when writing code
- **Exception Safety**: Provide at least basic exception safety guarantee
- **RAII Principle**: Use Resource Acquisition Is Initialization for resource management

### Naming Conventions (MANDATORY)

#### Variable Names
- **Must be meaningful and comprehensible** - no abbreviations except approved ones
- **Lower camelCase**: `firstName`, `lastName`, `transactionId`
- **Acronyms follow camelCase**: `Dom` (not DOM), `Xml` (not XML)
- **No single-letter names** - including loop counters (use `idx`, `count`, etc.)
  - **Exception**: Standard iterator patterns (`i`, `j` acceptable in ranged-for or iterator contexts)
- **Cannot match global variable names**
- **Approved abbreviations**: `Mgr` (Manager), `Chk` (Check)

#### Class Names
- **PascalCase**: `TransactionManager`, `DatabaseConnection`, `XmlParser`
- **Descriptive and unique**: No conflicts with 3rd party software or STL

#### Method Names
- **CamelCase**: `processTransaction()`, `validateInput()`, `getConnectionStatus()`
- **Public methods**: Use descriptive verbs (get, set, process, validate, create, destroy)
- **Private methods**: Use descriptive verbs (get, set, process, validate, create, destroy)
- **Accessors/Mutators**: Prefer `getValue()`/`setValue()` pattern

#### Function Names (Non-member)
- **CamelCase**: `processTransaction()`, `validateInput()`, `getConnectionStatus()`

#### Namespace Names
- **lowercase**: `namespace progress::database`, `namespace util`
- **Avoid deeply nested namespaces** (maximum 3 levels preferred)
- **Use namespace aliases** for long names: `namespace pdb = progress::database;`

#### Structure Names
- **PascalCase**: `struct LayoutInfo`, `struct ConnectionData`

#### Constants and Enums
- **ALL_CAPS**: `const int MAX_BUFFER_SIZE = 1024;`
- **Enum class preferred**: `enum class Status { Success, Failure, Pending };`
- **Legacy enumerations**: Follow existing patterns for compatibility

### Data Types (MANDATORY)

#### Modern C++ Types (Preferred)
- `std::string` - For string data (preferred over `TEXT*`)
- `std::vector<T>` - For dynamic arrays
- `std::array<T, N>` - For fixed-size arrays
- `std::unique_ptr<T>` - For exclusive ownership
- `std::shared_ptr<T>` - For shared ownership
- `std::weak_ptr<T>` - For non-owning references
- `std::optional<T>` - For optional values (C++17)
- `std::variant<T...>` - For type-safe unions (C++17)
- `size_t` - For sizes and indices
- `nullptr` - For null pointers (not NULL or 0)

#### Prohibited Types (Do NOT Use)
- `BOOL`, `TBOOL` - Use `bool` instead
- `SMALL` - Use `TTINY` or `int`
- `BIT` - Use `TTINY`, `COUNT`, `LONG`, or `bool`
- `INTERN` - Use `COUNT` or `int`
- `UTEXT` - Use `TEXT` or `unsigned char`
- `METACH` - Use `COUNT` or `int`
- `FAST` - Remove when found
- `register` - Obsolete keyword
- `auto_ptr` - Deprecated, use `std::unique_ptr`

#### 64-bit Considerations
- **NEVER cast pointers to `ULONG` or `LONG`** on 64-bit systems
- Use `uintptr_t` or `intptr_t` for pointer arithmetic
- `sizeof(LONG)` = 32 bits, but `sizeof(long)` = 64 bits ⚠️
- `sizeof(void *)` = 64 bits on 64-bit systems

### Type Definitions
- **Use `using` instead of `typedef`**: `using StringPtr = std::shared_ptr<std::string>;`
- **Avoid macros** for type definitions
- **Type aliases in namespaces**: Keep type definitions organized
- **Template aliases**: `template<typename T> using Vec = std::vector<T>;`

### Global Variables (AVOID)
- **Do NOT add new global variables** - use alternatives
- **Exception**: Constants declared as `constexpr` or `const`
- **Use namespaces** for constants: `namespace constants { constexpr int MAX_SIZE = 1024; }`
- **Singleton pattern**: If truly global state needed, use Meyer's singleton
- **PASOE Threading Issues**: Global variables require special handling for multi-threading
- **Alternative**: Add variables to context structures, access via references or pointers

### Memory Management (MANDATORY)

#### C++ RAII (Preferred)
- **Use smart pointers** for dynamic memory:
  - `std::unique_ptr<T>` - For exclusive ownership
  - `std::shared_ptr<T>` - For shared ownership (use sparingly)
  - **Note**: `std::make_unique` is C++14, use `std::unique_ptr<T>(new T())` in C++11
  - `std::make_shared<T>()` is available in C++11
- **Use STL containers** instead of raw arrays
- **Stack allocation** preferred over heap when appropriate
- **Avoid `new`/`delete`** - use smart pointers or containers

#### Progress Legacy Memory Management
When interfacing with C code or legacy systems:

**Parameter Stack (Short-term, <100K)**
```cpp
stkpsh();  // Push stack frame
// ... use stack
stkpop();  // Always match with push
```

**Pool Memory (Multiple small allocations)**
```cpp
stget();              // Allocate from pool
strent()/stvacate();  // When tracking needed
```

**System Memory (Large allocations)**
```cpp
utmalloc();  // Use this, not malloc()
utfree();    // Use this, not free()
```

**Smart Pointer Wrappers**
```cpp
// Create custom deleters for Progress memory functions
auto deleter = [](void* p) { utfree(p); };
std::unique_ptr<MyType, decltype(deleter)> ptr(
    static_cast<MyType*>(utmalloc(sizeof(MyType))), 
    deleter
);
```

### Class Design (MANDATORY)

#### Class Structure
```cpp
class MyClass
{
public:
    // Constructors and destructor
    MyClass();
    explicit MyClass(int value);
    ~MyClass();
    
    // Disable copy if appropriate
    MyClass(const MyClass&) = delete;
    MyClass& operator=(const MyClass&) = delete;
    
    // Enable move if appropriate
    MyClass(MyClass&&) noexcept = default;
    MyClass& operator=(MyClass&&) noexcept = default;
    
    // Public interface
    void publicMethod();
    int getValue() const;
    void setValue(int value);

protected:
    // Protected members for inheritance
    void protectedMethod();

private:
    // Private implementation
    void privateMethod();
    
    // Member variables (with trailing underscore or m_ prefix)
    int value_;
    std::string name_;
};
```

#### Rule of Zero/Three/Five
- **Rule of Zero**: Prefer compiler-generated special members when possible
- **Rule of Three**: If you define destructor, copy constructor, or copy assignment, define all three
- **Rule of Five**: In C++11+, also consider move constructor and move assignment
- **Use `= default`**: Let compiler generate when appropriate
- **Use `= delete`**: Explicitly disable unwanted operations

#### Constructor Guidelines
- **Prefer initialization lists** over assignment in constructor body
- **Use `explicit`** for single-argument constructors (prevents implicit conversion)
- **Delegating constructors**: Reduce code duplication
- **Default member initializers**: Initialize members inline when sensible

#### Virtual Functions
- **Virtual destructor** required for base classes with virtual methods
- **Use `override`** keyword for overridden virtual functions (C++11)
- **Use `final`** to prevent further overriding when appropriate
- **Pure virtual**: `virtual void method() = 0;` for abstract interfaces

### Code Formatting (MANDATORY)

#### Indentation and Spacing
- **NO TAB CHARACTERS ALLOWED** - Use 4 spaces for indentation
- **4 spaces per indentation level** (absolutely no tabs)
- Configure editor to insert spaces (not tabs) when Tab key is pressed
- Set editor to show tab characters to avoid accidental tabs
- **Spaces around operators**: `a + b` not `a+b`
- **Spaces after keywords**: `if (condition)` not `if(condition)`
- **Blank line after control structures**: After `if`/`switch`/`while`/`for`
- **Initialization lists**: One member per line for readability (if more than 2)

#### Curly Braces (MANDATORY)
- **Separate line, left-justified** (Allman style)
- **Aligned with their pair**
- **Mandatory for loops**: All `for`, `while`, `do` statements
- **Mandatory if multi-line**: Any part of if-else requires braces everywhere
- **Empty loops**: Use `{ }` not `;`
- **Class/Function braces**: Opening brace on new line

```cpp
// Correct
if (condition)
{
    doSomething();
}
else
{
    doSomethingElse();
}

// Class definition
class MyClass
{
public:
    void method()
    {
        // body
    }
};
```

#### Statements
- **One statement per line**
- **One declaration per line** (even in declaration lists)
- **No combined if-action**: `if` condition and action on separate lines

### Function/Method Standards (MANDATORY)

#### Function Prototypes
- **All functions must be declared** in header files
- **Member functions**: Declared in class definition
- **Non-member functions**: Declared in namespace or with extern "C" if needed

#### Function/Method Headers (MANDATORY)
```cpp
/**
 * @brief Short description of the function
 * 
 * Detailed description if needed. Explain the purpose,
 * algorithm, or business logic.
 * 
 * @param parameter1 Description of parameter1
 * @param parameter2 Description of parameter2
 * @return Description of return value
 * @throws ExceptionType When this exception might be thrown
 */
int functionName(
    int parameter1,
    const std::string& parameter2)
{
    // Function body
}
```

#### Parameter Guidelines
- **Pass by `const` reference**: For objects (avoid copying)
  - `void process(const std::string& data)`
- **Pass by value**: For primitives and when copying is needed
  - `void setValue(int value)`
- **Pass by non-const reference**: For output parameters
  - `void getValues(int& x, int& y)`
- **Pass by pointer**: When nullptr is valid or C compatibility needed
  - `void process(const char* text)`
- **Use smart pointers**: For ownership transfer
  - `void store(std::unique_ptr<Data> data)`

#### Return Value Guidelines
- **Return by value**: Let RVO/NRVO optimize (don't worry about copying)
  - `std::string getString()`
- **Return by reference**: Only for existing objects (be careful of lifetime)
  - `const std::string& getName() const`
- **Return smart pointers**: For ownership transfer
  - `std::unique_ptr<Data> createData()`
- **Use pair or custom struct**: For optional returns (std::optional is C++17)
  - `std::pair<bool, int> findValue()` // bool indicates found/not found
  - Or return pointer (nullptr if not found)

### Const Correctness (MANDATORY)
- **Mark methods `const`** if they don't modify object state
  - `int getValue() const;`
- **Use `const` references** for input parameters
  - `void process(const Data& data)`
- **Use `const` pointers** appropriately
  - `const Data* pData` - pointer to const data
  - `Data* const pData` - const pointer to data
- **`constexpr`**: For compile-time constants (C++11)
  - `constexpr int MAX_SIZE = 100;`
- **`constexpr` functions**: For compile-time evaluation
  - `constexpr int square(int x) { return x * x; }`

### Error Handling (MANDATORY)

#### Exception Guidelines
- **Use exceptions for exceptional conditions** (not normal control flow)
- **Inherit from `std::exception`** or its derivatives
- **Provide `noexcept`** guarantee when functions won't throw
  - Destructors, move constructors, swap functions should be `noexcept`
- **RAII ensures cleanup**: Resources freed even during exceptions
- **Catch by const reference**: `catch (const std::exception& e)`

#### ASSERT Usage
- **Use ASSERT for validation** (not FASSERT unless shutdown required)
- **ASSERT is disabled in release builds** - no performance impact
- **Use `static_assert`** for compile-time checks (C++11)
  - `static_assert(sizeof(int) == 4, "int must be 4 bytes");`
- **Internal errors**: Prefix with "SYSTEM ERROR:"

#### Error Codes (Legacy Compatibility)
- **Return status codes** when interfacing with C code
- **Prefer exceptions** in pure C++ code
- **Document error codes** clearly in function comments

### Header Files (MANDATORY)

#### Organization
- **Each .cpp file has matching .hpp file** (or .h for C compatibility)
- **Header guards** or `#pragma once`:
  ```cpp
  // Option 1: Include guards
  #ifndef PROGRESS_SUBSYSTEM_FILENAME_HPP
  #define PROGRESS_SUBSYSTEM_FILENAME_HPP
  /* declarations */
  #endif /* PROGRESS_SUBSYSTEM_FILENAME_HPP */
  
  // Option 2: #pragma once (if supported on all platforms)
  #pragma once
  /* declarations */
  ```
- **Forward declarations**: Use when possible to reduce dependencies

#### Include Order (MANDATORY)
1. Related header (for .cpp files)
2. C system headers
3. C++ standard library headers
4. Other libraries' headers
5. Project headers

```cpp
#include "myclass.hpp"      // Related header

#include <cstdio>           // C system headers
#include <cstring>

#include <iostream>         // C++ standard library
#include <string>
#include <vector>

#include <boost/shared_ptr.hpp>  // Third-party libraries

#include "progress/util.hpp"     // Project headers
```

#### Include Dependencies
- **Minimize includes** in headers - use forward declarations
- **Include what you use** - don't rely on transitive includes
- **Use angle brackets** for system/library headers: `#include <vector>`
- **Use quotes** for project headers: `#include "myheader.hpp"`

### Copyright Headers (MANDATORY)

#### C++ Source Files (.cpp, .cc, .cxx)
```cpp
/*
 * Copyright (c) 2025-2026 Progress Software Corporation and/or its subsidiaries or
 * affiliates. All Rights Reserved.
 */
```

#### Header Files (.hpp, .hh, .hxx, .h for C++)
```cpp
/*
 * Copyright (c) 2025-2026 Progress Software Corporation and/or its subsidiaries or
 * affiliates. All Rights Reserved.
 */
```

**If you are the first to modify a file in 2026, update the copyright year.**

### Threading Considerations (CRITICAL)
- **Thread-safe static initialization**: C++11 guarantees (Meyer's singleton)
- **Use `std::atomic`** for lock-free operations
- **Use `std::mutex`**, `std::lock_guard`, `std::unique_lock` for synchronization
- **RAII locking**: Always use lock guards, never manual lock/unlock
- **Avoid global and static mutable state** for thread safety
- **`thread_local`**: For thread-specific storage

### C++11 Features (Available)

#### C++11 Features to Use
- **`auto`**: Type deduction (use judiciously)
  - `auto value = getValue();`
- **Range-based for**: `for (const auto& item : container)`
- **`nullptr`**: Instead of NULL or 0
- **`override` and `final`**: Virtual function clarity
- **Lambda expressions**: For callbacks and algorithms
  - `std::sort(vec.begin(), vec.end(), [](int a, int b) { return a < b; });`
  - **Note**: Generic lambdas with `auto` parameters are C++14, NOT available
- **Smart pointers**: `std::unique_ptr`, `std::shared_ptr`
- **Move semantics**: `std::move()`, move constructors
- **`= default` and `= delete`**: Explicit special member control
- **`constexpr`**: Compile-time constants and functions (limited in C++11)
- **Strongly-typed enums**: `enum class`
- **Static assertions**: `static_assert`
- **Variadic templates**: For template metaprogramming
- **Rvalue references**: `T&&` for perfect forwarding
- **Uniform initialization**: `Type obj{args};`
- **`decltype`**: Type inference

#### C++14/17 Features NOT Available
- ❌ **`std::make_unique`**: Use `std::unique_ptr<T>(new T(args))` instead
- ❌ **Generic lambdas**: Use explicit type parameters
- ❌ **`std::optional`**: Use `std::pair<bool, T>` or pointer alternatives
- ❌ **`std::variant`**: Use inheritance or union alternatives
- ❌ **Structured bindings**: Use `std::tie` or separate assignments
- ❌ **`if` with initializer**: Declare before if statement
- ❌ **`std::string_view`**: Use `const std::string&` or `const char*`
- ❌ **Binary literals and digit separators**: Use hex or decimal

### Best Practices

#### Code Quality
- **Add comments liberally** using Doxygen/JSDoc style
- **Avoid `goto`** except for error/exit handling in C-style code
- **Prefer early return**: Reduce nesting depth
- **Always include `default`** in switch statements or use `enum class`
- **Avoid overuse of macros** - prefer `const`, `constexpr`, inline functions, templates
- **Use STL algorithms**: Replace raw loops with `std::find`, `std::transform`, etc.
- **RAII everywhere**: Automatic resource management

#### Code Readability
- **Avoid double negatives**: Use affirmative logic (`if (found)` not `if (!notFound)`)
- **Use parentheses**: Clarify operator precedence
- **White space is good**: Improves readability
- **Avoid mixing signed and unsigned**: Prevents subtle bugs
- **Use `size_t`** for sizes and indices
- **Prefer `++i`** over `i++` for non-primitive types (avoid unnecessary copy)

#### Initialization
- **Use uniform initialization**: `int x{5};` or `std::vector<int> vec{1, 2, 3};`
- **Initialize in declaration**: Reduce uninitialized variable bugs
- **Member initialization**: Use default member initializers or constructor init lists
- **Avoid narrowing conversions**: Uniform initialization prevents this

#### Type Safety
- **Use `enum class`**: Strongly-typed enumerations
  - `enum class Color { Red, Green, Blue };`
- **Avoid C-style casts**: Use `static_cast`, `const_cast`, `reinterpret_cast`, `dynamic_cast`
- **Use `std::pair` or custom types**: Instead of sentinel values (-1, nullptr patterns) since `std::optional` is C++17
- **Template metaprogramming**: SFINAE, `std::enable_if` for type constraints

#### Interface Design
- **Prefer non-member non-friend functions**: Increases encapsulation
- **Make interfaces easy to use correctly, hard to use incorrectly**
- **Prefer `explicit`**: Prevent accidental conversions
- **Return by value**: Trust RVO/NRVO optimizations
- **Pass containers by reference**: `const std::vector<T>&` for input arrays

### Sonarqube Compliance (MANDATORY)
- **Keep functions small** and focused (single responsibility)
- **Maximum 7 parameters** per function (use structures/objects for more)
- **Avoid deep nesting**: Maximum 3 levels preferred
- **No code duplication**: Extract common code to functions/methods
- **Remove commented-out code** (use source control instead)
- **Minimize cognitive complexity**: Keep logic straightforward
- **Use RAII**: Prevents resource leaks
- **Const correctness**: Apply const everywhere appropriate

### File Naming
- **Lowercase with underscores**: `transaction_manager.cpp`, `database_connection.hpp`
  - **OR PascalCase**: `TransactionManager.cpp`, `DatabaseConnection.hpp`
  - Choose one convention and be consistent per project
- **Check for conflicts** before creating new files
- **Matching pairs**: `myclass.cpp` ↔ `myclass.hpp`

---

## Testing Standards

### Unit Testing Requirements (MANDATORY)
- **Test framework**: Google Test (googletest)
- **Mocking framework**: Google Mock (gmock) - for mocking external dependencies
- **Develop tests for all new functionality**
- **Cover all code paths**: Including error conditions
- **Test both success and error scenarios**
- **Mock external dependencies**: Use Google Mock
- **RAII testing**: Verify resource cleanup (no leaks)
- **Exception safety testing**: Verify behavior under exceptions
- **Thread safety testing**: Where applicable
- **Associate tests with Enhancement CRs**

### Testing Best Practices
- **Use meaningful test names**: `TEST(TransactionManager, HandlesInvalidInputGracefully)`
- **Arrange-Act-Assert pattern**: Structure tests clearly
- **Test fixtures**: Share common setup/teardown
- **Parameterized tests**: Test multiple inputs efficiently
- **Test boundary conditions**: Edge cases, limits, empty inputs
- **Memory leak detection**: Use Valgrind, AddressSanitizer, or similar
- **Document test requirements**: Prerequisites, setup, expected behavior

### Test Structure Example
```cpp
TEST(MyClassTest, MethodNameDoesExpectedBehavior)
{
    // Arrange
    MyClass obj;
    const int expectedValue = 42;
    
    // Act
    obj.setValue(expectedValue);
    int result = obj.getValue();
    
    // Assert
    EXPECT_EQ(result, expectedValue);
}
```

---

## Summary

All C++ code must follow these guidelines and the comprehensive rules in [code-review-CPP-standards.md](code-review-CPP-standards.md).

Key mandatory rules:

1. ✅ Use modern C++ features (smart pointers, RAII, auto, range-for)
2. ✅ Follow naming conventions (PascalCase classes, camelCase methods/variables)
3. ✅ Use appropriate data types (prefer STL, smart pointers over raw)
4. ✅ Apply RAII principle everywhere (automatic resource management)
5. ✅ Const correctness (const methods, const references, constexpr)
6. ✅ Format code correctly (4 spaces, NO tabs, braces on separate lines)
7. ✅ Include function documentation with Doxygen comments
8. ✅ Handle exceptions properly (RAII + exception safety)
9. ✅ Write comprehensive unit tests
10. ✅ Pass Sonarqube quality checks
11. ✅ Compile without warnings on all platforms
12. ✅ Follow Rule of Zero/Three/Five
13. ✅ Use type safety (enum class, no C-style casts)
14. ✅ Thread safety considerations (std::atomic, std::mutex)

---
