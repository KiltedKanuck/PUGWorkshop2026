---
applyTo: '**/*.{p,cls,w,i,t}'
---

Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.

### Variable Declaration

- Prefer the `var` statement over `define variable` when declaring variables in ABL code.
- **MANDATORY**: Always use `NO-UNDO` for temporary variables that don't require transaction rollback to avoid before-image overhead.

### Naming Conventions

- Use camelCase for variable names in ABL code (e.g., `customerName`, `totalAmount`).
- Never use hyphens (`-`) in variable names.
- Never use Hungarian notation (prefixes like `str`, `int`, etc.).
- Use only alphanumeric characters in function/method names.

### Keyword and Style Conventions

- Use lowercase ABL keywords (e.g., `class`, `interface`, `define`, `method`, `property`, etc.).

## Related Documentation

**IMPORTANT**: All code must also comply with [code-review-ABL-standards.md](code-review-ABL-standards.md), which contains 101 mandatory code review rules organized by severity (BLOCKER, CRITICAL, MAJOR, MINOR, INFO). Review those standards before submitting code.

## MCP Server Integration

### openEdge-abl-mcp-server
OpenEdge Model Context Protocol server provides:
- Language reference lookups (use **12.8 collection** by default)
- Grammar validation
- Documentation access for built-in functions and statements
- Progress Knowledge Base articles
- Best practice guidance
- ABLUnit documentation and patterns

**Usage**: Query the MCP server to validate syntax, check built-in functions, and verify ABL language constructs.

---

## ABL-Specific Guidelines

### Language Fundamentals
- **openEdge-abl-mcp-server**: Always use the OpenEdge MCP server and reference the 12.8 collection for grammar, language reference, and documentation
- **Case Sensitivity**: ABL string comparisons are case-insensitive by default - avoid unnecessary `LOWER()` or `UPPER()` functions for equality checks
- **File Extensions**: `.p` (procedures), `.cls` (classes), `.w` (windows), `.i` (includes), `.r` (compiled r-code)

### UNIX/Cross-Platform Compatibility (CRITICAL)
- **File Name Casing**: Class name case MUST match file name case exactly (e.g., file `MyClass.cls` must contain `CLASS MyClass`). Different case causes UNIX compilation failures.
- **Include File Casing**: Include file reference case MUST match actual file name case for UNIX compatibility.
- **Escape Characters**: Use tilde (`~`) for escape sequences, not backslash (`\`). Example: `"My ~{ string"` not `"My \{ string"`.
- **Path Separators**: Use forward slash (`/`) for path separators when possible, or use `OS-DIR` for OS-specific paths.

### Naming Conventions
- **Variable Names**: Use camelCase for all variable names (e.g., `customerName`, `totalAmount`) - never use hyphens (`-`)
- **No Hungarian Notation**: Do NOT use Hungarian notation prefixes like `str`, `int`, `ch`, etc.
- **Lowercase Keywords**: Always use lowercase ABL keywords (`class`, `interface`, `define`, `method`, `property`, etc.)
- **Descriptive Names**: Use clear, self-documenting variable and method names
- **Class Names**: Use PascalCase for class names (e.g., `CustomerService`, `OrderProcessor`)
- **Package Names**: Use lowercase for package names (e.g., `com.example.services`)

### Variable Declarations (MANDATORY)
- **Prefer `var` statement** over `define variable` when type inference is clear
- **ALWAYS use `NO-UNDO`** for temporary variables to avoid before-image overhead (this is mandatory unless transaction rollback is explicitly needed)
- Initialize variables at declaration when possible
- **Never use deprecated `RECID`** - use `ROWID` instead
- **Never use `SHARED` or `GLOBAL SHARED` variables** - they create tight coupling and maintenance problems

### Parameter Passing
- **Temp-tables and ProDataSets**: Always pass `BY-REFERENCE`
- Use `INPUT`, `OUTPUT`, or `INPUT-OUTPUT` keywords explicitly
- Document parameter purposes in procedure/method headers

### Code Organization
- **Prefer object-oriented patterns** when applicable versus procedural
- Use classes for stateful operations and reusable components
- Use procedures for simple, stateless operations
- Use functions for pure calculations without side effects
- Keep methods and procedures focused and small

### Database Patterns (MANDATORY)
- **ALWAYS specify lock type explicitly**: Use `NO-LOCK` or `EXCLUSIVE-LOCK` - never rely on default locking behavior
- **NO-LOCK**: Use for all read-only operations to improve performance and avoid blocking
- **EXCLUSIVE-LOCK with NO-WAIT**: Use `EXCLUSIVE-LOCK NO-WAIT` to avoid timeout waits, then check `IF AVAILABLE` and `IF LOCKED` conditions
- Use named buffers when working with multiple instances of the same table
- Always explicitly manage transactions with `TRANSACTION` blocks
- Use `FOR EACH`, `FIND FIRST`, `FIND LAST` appropriately
- **FIND statements**: Always add `NO-ERROR` to prevent runtime errors
- When fetching data use the `FIELDS` option to limit retrieved columns
- **Never use `OF` keyword** - use explicit `WHERE` clauses instead (e.g., `WHERE OrderLine.OrderNum = Order.OrderNum` not `OrderLine OF Order`)
- Use explicit `WHERE` clauses instead of constants (e.g., `FIND customer WHERE customer.custnum = 15` not `FIND customer 15`)

### Error Handling (MANDATORY)
- **Use `BLOCK-LEVEL ON ERROR UNDO, THROW`** pattern for proper ABL exception handling in classes
- **Always use `CATCH` blocks** for proper error handling
- **Access caught exceptions**: Never ignore exceptions in `CATCH` blocks - log or rethrow them (accessing the exception variable indicates intentional handling)
- **Use `FINALLY` blocks** wherever applicable for cleanup operations
- **Avoid `NO-ERROR`**: Prefer structured error handling with `CATCH` blocks instead of `NO-ERROR` flag
- **UNDO must specify action**: Never use `UNDO` alone - always specify `RETRY`, `LEAVE`, `THROW`, or `NEXT`
- Provide meaningful error messages
- Log errors appropriately for debugging
- Classes inheriting `Progress.Lang.AppError` must be marked `SERIALIZABLE`

### Memory Management (CRITICAL)
- **Object cleanup is paramount** - do not leave memory leaks
- **Always `DELETE OBJECT`** when done with class instances (use `FINALLY` blocks to ensure cleanup)
- **Always use `NO-UNDO`** for temporary variables unless transaction rollback is explicitly needed
- Clean up dynamic objects, queries, and buffers
- Properly clean up temp-tables and ProDataSets when no longer needed
- Use `VALID-HANDLE()` checks before deleting objects

### ABL Directory Structure
For ABL projects, maintain this structure:
```
src/
├── main/
│   ├── abl/          # Main ABL application code (.p, .cls, .w files)
│   └── resources/    # Application resources (configs, data files, etc.)
└── test/
    ├── abl/          # ABLUnit test code
    └── resources/    # Test-specific resources
```

**Critical**: Maintain strict separation between application code (`src/main/abl`) and test code (`src/test/abl`).

---

### General Guidelines

When contributing to this project, please adhere to the following guidelines:

1. **Project Structure**: Understand the overall structure of the project, including key directories and files. This will help in navigating the codebase and making informed decisions.

2. **Coding Standards**: Follow established coding standards and best practices for the programming languages and frameworks used in the project. This includes naming conventions, code organization, and documentation requirements.

3. **Testing**: Write unit tests and integration tests to ensure code quality and prevent regressions. Familiarize yourself with the ABLUnit testing framework and tools used in the project. Syntax for ABLUnit can be found in the OpenEdge MCP collection "12.8"

4. **Performance**: Consider the performance implications of your code changes. Optimize algorithms and data structures where necessary, and be mindful of memory usage and execution time.

5. **Security**: Keep security best practices in mind when writing code. Validate user input, sanitize outputs, and be aware of common vulnerabilities (e.g., SQL injection, XSS).

6. **Collaboration**: Communicate effectively with team members and stakeholders. Provide clear explanations for your code changes and be open to feedback.

7. **Documentation**: Update documentation to reflect code changes. This includes inline comments, README files, and any relevant design documents.

8. **Version Control**: Use version control (e.g., Git) effectively. Write meaningful commit messages and follow the branching strategy defined by the project.

By adhering to these guidelines, you can help ensure that your contributions are valuable and aligned with the project's goals.