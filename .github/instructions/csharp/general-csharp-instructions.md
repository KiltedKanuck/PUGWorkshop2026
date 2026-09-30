---
applyTo: '**/*.{cs,csproj}'
---

Provide project context and coding guidelines that AI should follow when generating C# code, answering questions, or reviewing changes. This document is specifically for **C# programming** and adheres to Microsoft's C# Coding Conventions and SonarQube best practices.

## Related Documentation

**IMPORTANT**: All code must also comply with [code-review-CSHARP-standards.md](code-review-CSHARP-standards.md), which contains comprehensive mandatory code review rules organized by severity. Review those standards before submitting code.

---

## C#-Specific Guidelines

### Language Fundamentals
- **C# Version**: Use latest stable C# features (currently C# 12/NET 8 recommended) where supported.
- **Modern C#**: Use File-scoped namespaces, Global usings, Record types, and Pattern matching.
- **Async/Await**: Use `async`/`await` for I/O-bound operations. Avoid `Task.Run` for CPU-bound work on servers.
- **LINQ**: Prefer LINQ for readability in collection processing, but be mindful of performance in hot paths.
- **Null Safety**: Enable Nullable Reference Types (`<Nullable>enable</Nullable>`) in project files.

### Naming Conventions (MANDATORY)

#### Classes, Structs, Enums, Interfaces
- **PascalCase**: `CustomerService`, `OrderProcessor`
- **Interfaces**: Prefix with 'I'. `ICustomerService`.
- **Nouns**: Classes represent things.
- **Single Responsibility**: Name should reflect the single responsibility.

#### Methods
- **PascalCase**: `CalculateTotal`, `FindById`, `ProcessOrder`
- **Async Suffix**: Methods returning `Task`/`Task<T>` should end with `Async` (e.g., `GetDataAsync`).
- **Verbs**: Methods perform actions.

#### Properties and Public Fields
- **PascalCase**: `FirstName`, `TotalAmount`
- **Auto-Properties**: Prefer auto-properties over manual backing fields when possible.

#### Variables, Parameters, Private Fields
- **camelCase**: `firstName`, `orderList`
- **Private Fields**: Prefix with underscore `_camelCase` (e.g., `_logger`, `_repository`).
- **Constants**: `PascalCase` usually (Microsoft standard), sometimes `UPPER_SNAKE_CASE` (more common in general dev, but Microsoft recommends PascalCase for `const`). *Decision: Follow Microsoft PascalCase for consts.*

### Code Formatting (MANDATORY)

#### Indentation and Braces
- **4 spaces per level** (never tabs).
- **Allman Style**: Opening brace on a **new line**.
  ```csharp
  if (condition)
  {
      // code
  }
  ```

#### Using Directives
- Place `using` directives at the top of the file (before namespace) or use Global Usings.
- Remove unused `using` directives.

### Best Practices

#### Variable Declaration
- Use `var` when the type is apparent from the right side of the assignment.
  - `var stream = File.Create(path);` (Good)
  - `var x = GetResult();` (Bad - type unclear)
- Target-typed new: `List<string> list = new();` is acceptable.

#### Exception Handling
- Throw specific exceptions (`ArgumentException`, `InvalidOperationException`).
- Catch specific exceptions.
- Do not swallow exceptions (empty catch blocks).
- Use `throw;` to rethrow to preserve stack trace (not `throw ex;`).

#### Resources
- Use `using` statements (or declarations) for `IDisposable` types to ensure cleanup.
  ```csharp
  using var stream = File.OpenRead("file.txt");
  ```
