---
applyTo: '**/*.{cs,csproj}'
---

# Code Review Standards for C# Programming

## Overview

This document contains comprehensive mandatory code review rules for **C# programming**. All code must comply with these standards before merge and follow Microsoft's C# Coding Conventions and SonarQube rules.

**Severity Indicators**:
- **BLOCKER**: Must be fixed immediately - blocks release
- **CRITICAL**: Must be fixed before merge - causes bugs, security issues, or compilation failures
- **MAJOR**: Should be fixed - impacts performance, maintainability, or quality
- **MINOR**: Recommended to fix - improves code quality and consistency
- **INFO**: Information or low-priority improvements

**Related Documentation**: See [general-csharp-instructions.md](general-csharp-instructions.md) for quick-reference coding guidelines, best practices, and project structure requirements.

---

## Standards Overview

This document enforces:
1. Naming Conventions (MANDATORY)
2. Asynchronous Programming (CRITICAL)
3. Exception Handling (CRITICAL)
4. Resource Management (CRITICAL)
5. Class & Method Design (MAJOR)
6. Security (CRITICAL)
7. Performance (MAJOR)
8. Testing (MANDATORY)

---

## 1. Naming Conventions (MANDATORY)

### Types and Members
- **Classes/Methods/Properties**: PascalCase.
- **Interfaces**: Start with 'I'.
- **Parameters/Locals**: camelCase.
- **Private Fields**: `_camelCase` (underscore prefix).

**Noncompliant:**
```csharp
public class customerService {} // Class should be PascalCase
public void get_data() {} // Method should be PascalCase, no underscores
private string name; // Private fields should match _camelCase convention (or minimal camelCase if underscore not used, but _ is preferred for distinction)
```

**Compliant:**
```csharp
public class CustomerService
{
    private readonly string _name;
    
    public void GetData() {}
}
```

---

## 2. Asynchronous Programming (CRITICAL)

### Async/Await Guidelines
- **Avoid `async void`**: Use `async Task` instead. `async void` is only for event handlers.
- **Suffix**: Async methods must end with `Async`.
- **Check Returns**: Do not ignore the task returned by an async method.
- **Cancellation**: Accept `CancellationToken` in async methods where applicable.

**Noncompliant:**
```csharp
public async void SaveData() { ... } // Crash risk
public async Task Process() { ... } // Missing Async suffix
```

**Compliant:**
```csharp
public async Task SaveDataAsync(CancellationToken cancellationToken) { ... }
```

---

## 3. Exception Handling (CRITICAL)

### Guidelines
- **Preserve Stack Trace**: Use `throw;` inside catch blocks, never `throw ex;`.
- **Specific Catching**: Avoid `catch (Exception)`.
- **Fail Fast**: Validate arguments at the beginning of methods (`ArgumentNullException`).

**Noncompliant:**
```csharp
catch (Exception ex)
{
    throw ex; // Destroys stack trace
}
```

**Compliant:**
```csharp
catch (SqlException ex)
{
    _logger.LogError(ex, "DB Error");
    throw; // Preserves stack trace
}
```

---

## 4. Resource Management (CRITICAL)

### IDisposable
- **Use `using`**: Always wrap `IDisposable` objects in `using` statements or declarations.
- **Implementation**: If a class owns unmanaged resources or other `IDisposable` objects, it must implement `IDisposable`.

**Noncompliant:**
```csharp
var client = new HttpClient(); // Might leak if not disposed
client.GetAsync(...);
```

**Compliant:**
```csharp
using var client = new HttpClient();
await client.GetAsync(...);
```

---

## 5. Class & Method Design (MAJOR)

### Methods
- **Complexity**: Keep Cyclomatic Complexity under 10 (SonarQube).
- **Arguments**: Limit method parameters to 7 or fewer.
- **Extensions**: Place extension methods in a dedicated `static` class named `*Extensions`.

### Classes
- **Static**: Static classes should not have instance constructors.
- **Initialization**: Use object initializer syntax for DTOs/POCOs.

---

## 6. Security (CRITICAL)

- **Secrets**: NEVER hardcode secrets or connection strings. Use `IConfiguration`.
- **SQL Injection**: Use Parameterized Queries or ORM (Entity Framework). Never concatenation.
- **XSS**: Encode output in web views.

---

## 7. Performance (MAJOR)

- **String Concatenation**: Use `StringBuilder` for loops.
- **Collections**: Use `List<T>` or `Dictionary<TKey, TValue>` generally. Use `IEnumerable<T>` for APIs.
- **Arrays**: Prefer `Array.Empty<T>()` over `new T[0]`.

---

## 8. Testing (MANDATORY)

- **Naming**: Tests should follow `MethodName_StateUnderTest_ExpectedBehavior`.
- **Assertions**: Use one logical assertion per test.
- **Frameworks**: xUnit or NUnit are preferred.
- **Mocking**: Use Moq or NSubstitute for dependencies.
