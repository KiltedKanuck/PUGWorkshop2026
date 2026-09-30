---
applyTo: '**/*.{c,h}'
---

Provide project context and coding guidelines that AI should follow when generating C code, answering questions, or reviewing changes. This document is specifically for **C programming** (not C++ or C#).

## Related Documentation

**IMPORTANT**: All code must also comply with [code-review-C-standards.md](code-review-C-standards.md), which contains comprehensive mandatory code review rules. Review those standards before submitting code.

**IMPORTANT**: Use Progress secure string APIs as documented in [secure-string-operations.md](secure-string-operations.md). Prefer `p_strcpy_s`/`p_strncpy_s`/`p_strcat_s`/`p_strncat_s`/`p_zeromem_s` over unsafe CRT alternatives.

---

## C-Specific Guidelines

### Language Fundamentals
- **Pure C Programming**: This is for C code only - not C++, C#, or Objective-C
- **Standard**: Follow ANSI C standards with Progress-specific extensions
- **Platform Compatibility**: Code must compile without warnings on:
  - 64-bit Windows
  - 32-bit Windows
  - Linux (various distributions)
- **PASOE Multi-Threading**: Be aware of PASOE agent threading requirements when writing code

### Naming Conventions (MANDATORY)

#### Variable Names
- **Must be meaningful and comprehensible** - no abbreviations except approved ones
- **Lower camelCase**: `firstName`, `lastName`, `transactionId`
- **Pointer prefixes**: `p` for pointer, `pp` for pointer-to-pointer
  - Example: `pTransactionId`, `ppSleepTime`
- **Acronyms follow camelCase**: `Dom` (not DOM), `Xml` (not XML)
- **No single-letter names** - including loop counters (use `idx`, `count`, etc.)
- **Cannot match global variable names**
- **Approved abbreviations**: `Mgr` (Manager), `Chk` (Check)

#### Function Names
- **MANDATORY prefix**: Use subsystem abbreviation (`bf`, `cr`, `cso`, `dr`, `dt`, `fd`, `fm`, `hli`, `io`, `nc`, `nss`, `rn`, `sm`, `sn`, `um`)
- **CamelCase after prefix**: `bmLockDownMasterBlock()` not `bklocmb()`
- **Local (static) functions**: May omit subsystem prefix but still follow conventions

#### Structure Names
- **Prefix with subsystem**: 2-letter prefix (e.g., `struct smLayout`)
- **Descriptive and unique**: No conflicts with 3rd party software
- **AUTODITM suffix**: Always append `ditem` to AUTODITM structures (e.g., `AUTODITM(uicDitem)`)

### Data Types (MANDATORY)

#### Approved Types
- `TEXT` - For character data (not `char`)
- `COUNT` - 2-byte signed integer (-32768 to +32767)
- `UCOUNT` - 2-byte unsigned (0 to 65535)
- `LONG` - 4-byte signed integer (-2B to +2B)
- `ULONG` - 4-byte unsigned (0 to 4B)
- `LONG64` - 8-byte signed integer
- `ULONG64` - 8-byte unsigned integer
- `VOID` - Use instead of `void`
- `DOUBLE` - For floating point
- `TTINY` - 1-byte unsigned (0-255)
- `int` - Preferred return type for performance; preferred for parameters expecting #define constants
- `BYTES` - Unsigned integer large enough for `sizeof(...)`

#### Prohibited Types (Do NOT Use)
- `BOOL`, `TBOOL` - Use `int` instead (0 or 1)
- `SMALL` - Use `TTINY` or `int`
- `BIT` - Use `TTINY`, `COUNT`, or `LONG`
- `INTERN` - Use `COUNT` or `int`
- `UTEXT` - Use `TEXT`
- `METACH` - Use `COUNT` or `int`
- `FAST` - Remove when found
- `register` - Obsolete
- `void` - Use `VOID`

#### 64-bit Considerations
- **NEVER cast pointers to `ULONG` or `LONG`** on 64-bit systems
- `sizeof(LONG)` = 32 bits, but `sizeof(long)` = 64 bits ⚠️
- `sizeof(void *)` = 64 bits on 64-bit systems
- Always use uppercase types: `LONG` not `long`

### Type Definitions
- **Do NOT use macros** for type definitions (except fundamental types)
- **Avoid typedef for structures** - use `struct` directly
- **When typedef exists**: Follow existing pattern but avoid for new code

### Global Variables (AVOID)
- **Do NOT add new global variables** - use alternatives
- **Exception**: Read-only constants using `PROCONST_CODE` macro
- **PASOE Threading Issues**: Global variables require special handling for multi-threading
- **Alternative**: Add variables to `pvm_context` structure, access via `pg_pvm`
- **Naming Conflicts**: Structure element names cannot match global variable names

### Memory Management (MANDATORY)

#### Parameter Stack (Short-term, <100K)
```c
stkpsh();  // Push stack frame
// ... use stack
stkpop();  // Always match with push
```

#### Pool Memory (Multiple small allocations)
```c
stget();              // Allocate from pool
strent()/stvacate();  // When tracking needed
```

#### System Memory (Large allocations)
```c
utmalloc();  // Use this, not malloc()
utfree();    // Use this, not free()
```

### Code Formatting (MANDATORY)

#### Indentation and Spacing
- **4 spaces per level** (never tabs)
- **Spaces around operators**: `a + b` not `a+b`
- **Spaces after keywords**: `if (condition)` not `if(condition)`
- **Blank line after control structures**: Required after all `if`/`switch`/`while`/`for`

#### Curly Braces (MANDATORY)
- **Separate line, left-justified**
- **Aligned with their pair**
- **Mandatory for loops**: All `for`, `while`, `do` statements
- **Mandatory if multi-line**: Any part of if-else requires braces everywhere
- **Empty loops**: Use `{ }` not `;`

#### Statements
- **One statement per line**
- **One assignment per statement** (no `a = b = c`)
- **No combined if-action**: `if` condition and action on separate lines

### Function Standards (MANDATORY)

#### Function Prototypes
- **All functions must be prototyped** in:
  - Public header file for public functions
  - `LOCALF` in source file for local functions
- **No parameters in stub functions** to avoid maintenance issues

#### Function Headers (MANDATORY)
```c
/* PROGRAM: functionName - short description
 *
 * Additional description if needed
 * 
 * RETURNS: List of return values or None for VOID
 */
return_type
functionName(
    parameter1,  /* description */
    parameter2,  /* description */
    parameter3)  /* description */
{
    /* Function body */
}
```

#### Function Return Values
- **Return status only** - use parameters for result values
- **Prefer `int` return type** for performance
- **Use `int` for parameters** expecting #define constants

### Error Handling (MANDATORY)

#### ASSERT Usage
- **Use ASSERT for validation** (not FASSERT unless shutdown required)
- **ASSERT is disabled in release builds** - no performance impact
- **Prefer return codes** over fatal errors
- **Internal errors**: Prefix with "SYSTEM ERROR:"
- **Error messages**: May re-word for clarity, avoid re-using for different purposes

### Header Files (MANDATORY)

#### Organization
- **Each .c file has matching .h file** (e.g., `rnproc.c` → `rnproc.h`)
- **Include guards required**:
  ```c
  #ifndef FILENAME_H
  #define FILENAME_H
  /* declarations */
  #endif /* FILENAME_H */
  ```
- **API header files**: Public function prototypes and structures
- **Layer-specific headers**: `<layerPrefix>misc.h` for shared structures

#### Include Dependencies
- **Caller responsible** for including required headers
- **Order matters** - include dependencies before API headers
- **Minimize includes** - only include what's needed

### Copyright Headers (MANDATORY)

#### C Source Files (.c)
```c
/*************************************************************/
/* Copyright (c) 1984-2026 by Progress Software Corporation  */
/*                                                           */
/* All rights reserved.  No part of this program or document */
/* may be reproduced in any form  or by  any means without   */
/* permission in writing from Progress Software Corporation. */
/*************************************************************/
```

#### Header Files (.h)
```c
/****************************************************************************/
/*                                                                          */
/* Copyright (c) 2026 by Progress Software Corporation                     */
/*                                                                          */
/* All rights reserved.  No part of this program or document                */
/* may be reproduced in any form or by any means without                    */
/* permission in writing from Progress Software Corporation.                */
/****************************************************************************/
```

**If you are the first to modify a file in 2026, update the copyright year.**

### Threading Considerations (CRITICAL)
- **Avoid global and static variables** for thread safety
- **Be careful with memory allocation** in threaded contexts
- **PASOE agent compatibility**: Test with `-DMTAPSV` compilation flag
- **Symbol table tracking**: Global variables tracked for multi-threading

### Best Practices

#### Code Quality
- **Add comments liberally** for clarity
- **Avoid `goto`** except for error/exit
- **Limit return statements** within functions
- **Always include `default`** in switch statements
- **Avoid overuse of macros** - debuggers don't handle them well
- **Avoid machine-dependent** conditional compilation

#### Code Readability
- **Avoid double negatives**: Use affirmative logic (`if (found)` not `if (!notfound)`)
- **Use parentheses with bitwise operations**: `if ((flags & MASK) != 0)`
- **White space is good** - improves readability
- **Avoid mixed expressions** - don't compare signed to unsigned

#### Variable Initialization
- **Only initialize if needed** before use without assignment
- **Avoid unnecessary initialization**:
  ```c
  /* ❌ Incorrect */
  int ret = 0;
  ret = someFunction();
  
  /* ✅ Correct */
  int ret;
  ret = someFunction();
  ```

#### Unused Parameters
```c
#define PSC_UNUSED_PARAM(a) (void)a

int myFunc(int needed, int unused)
{
    PSC_UNUSED_PARAM(unused);
    /* Function body using 'needed' */
}
```

### Sonarqube Compliance (MANDATORY)
- **Keep functions small** and focused
- **Maximum 7 parameters** per function (use structures for more)
- **Avoid nesting beyond 3 levels**
- **No code duplication**
- **Remove commented-out code** (use source control instead)
- **Minimize cognitive complexity**

### File Naming
- **Start with subsystem name**: 2-3 letter prefix
- **Check for conflicts** before creating new files
- **Header files**: Typically `<subsystem>mgr.h`
- **Exceptions**: `um` subsystem (separate headers), `sm` subsystem (uses `smprocs.h`)

---

## Testing Standards

### Unit Testing Requirements (MANDATORY)
- **Develop tests for all new functionality**
- **Cover all new code paths**
- **Test both success and error scenarios**
- **Use debugger to verify behavior**
- **Provide unit tests to QA** for testing infrastructure
- **Associate tests with Enhancement CRs**

### Testing Best Practices
- Use meaningful test names
- Test boundary conditions
- Verify memory management (no leaks)
- Test thread safety where applicable
- Document test setup and expected results

---

## Summary

All C code must follow these guidelines and the comprehensive rules in [code-review-C-standards.md](code-review-C-standards.md). 

Key mandatory rules:

1. ✅ Use approved data types only (no BOOL, FAST, register, void)
2. ✅ Follow naming conventions (camelCase variables, prefixed functions)
3. ✅ Use proper memory management (utmalloc/utfree, not malloc/free)
4. ✅ Format code correctly (4 spaces, braces on separate lines)
5. ✅ Include function prototypes and headers
6. ✅ Avoid global variables
7. ✅ Write unit tests for all new code
8. ✅ Pass Sonarqube quality checks
9. ✅ Compile without warnings on all platforms

---