---
applyTo: '**/*.{c,h}'
---

# Code Review Standards for C Programming

## Overview

This document contains comprehensive mandatory code review rules for **C programming** (not C++ or C#). All code must comply with these standards before merge.

**Severity Indicators**:
- **MANDATORY**: Must be followed - code will be rejected if not compliant
- **CRITICAL**: Causes bugs, security issues, or compilation failures
- **Required**: Standard practice that should always be followed
- **Recommended**: Best practice that improves code quality

**Related Documentation**: See [general-c-instructions.md](general-c-instructions.md) for quick-reference coding guidelines, best practices, and project structure requirements.

---

## Standards Overview

This document covers:
1. Variable naming conventions (MANDATORY)
2. Function naming standards (MANDATORY)  
3. Global variable restrictions (CRITICAL)
4. AUTODITM variables (MANDATORY)
5. Type definitions (MANDATORY)
6. Data type guidelines (MANDATORY)
7. Code formatting rules (MANDATORY)
8. Memory management (CRITICAL)
9. Best practices (Required)
10. Sonarqube compliance (MANDATORY)
11. Header file organization (MANDATORY)
12. Copyright requirements (MANDATORY)
13. Testing standards (Required)

---

## Coding Standards

## Variable Names (MANDATORY)
- Must be meaningful and comprehensible words
- Cannot match any global variable names
- Should use full words with allowed abbreviations:
  - `Mgr` for Manager
  - `Chk` for Check
- Follow lower camel case:
  - Start with lowercase
  - Capitalize subsequent words
  - Example: `firstName`, `lastName`
- Special prefixes:
  - Pointer variables begin with `p`
  - Pointers to pointers begin with `pp`
- Acronyms follow camel case:
  - `Dom` for DOM
  - `Xml` for XML
- No single-letter names (including loop counters)

### Example Variable Names

❌ Incorrect:
```c
LONG *trid;      // unclear abbreviation
DBKEY fib;       // ambiguous naming
int **st;        // too short
```

✅ Correct:
```c
LONG   *pTransactionId;
DBKEY   firstIndexBlock;
int   **ppSleepTime;
```

## Function Names (MANDATORY)

- Must be prefixed with subsystem abbreviation:
  - `bf`, `cr`, `cso`, `dr`, `dt`, `fd`, `fm`
  - `hli`, `io`, `nc`, `nss`, `rn`, `sm`, `sn`, `um`
- Local (static) functions:
  - May omit subsystem prefix
  - Still should follow naming conventions

### Example Function Names

❌ Incorrect:
```c
VOID bklocmb() { ... }
```

✅ Correct:
```c
VOID bmLockDownMasterBlock() { ... }
```

## Global Variable Names (CRITICAL)

### General Rules
- Avoid adding new global variables
- Exception: read-only constants using `PROCONST_CODE` macro

### Read-Only Constants Example
```c
GLOBAL TEXT PROCONST_CODE szDBTYPE_PROGRESS[] = "PROGRESS";
```

### PASOE Multi-Threading Considerations
- Global variables are tracked in symbol table database
- Each thread needs local storage version
- Code compiled with `-DMTAPSV` for PASOE agent
- Symbol table uses witch database to identify read-only variables

### Alternative to Global Variables
- Add new variables to `pvm_context` structure
- De-reference using `pg_pvm` global variable

### Renaming Global Variables
- Requires updating symbol database
- Needs regeneration of PASOE auto-generated code
- Avoid using structure names as variable names

### Example of Incorrect Usage
```c
LOCAL struct tblInfo tblInfo;    // This will fail in PASOE agent
```

### Important Notes
- Avoid naming conflicts between local and global variables
- C compiler allows but may cause preprocessing issues
- PASOE agent compilation will catch these problems

## AUTODITM Variables (MANDATORY)

### General Guidelines
- Use `AUTODITM` macro for defining ditem on stack
- Initialize using `INITDITM` macro
- Always append "ditem" suffix to structure names

### Naming Rules
- Structure names must be unique in codebase
- Append `ditem` suffix to prevent conflicts
- Avoid using existing structure names

### Example Usage

❌ Incorrect:
```c
AUTODITM(uic);              // Conflicts with typedef struct uic
```

✅ Correct:
```c
AUTODITM(uicDitem);         // Clear distinction from struct uic
```

## Type Definitions (MANDATORY)

### General Rules
- Do NOT use macros for type definitions
- Use macros only for fundamental data types
- Avoid using `typedef` for new structures
- Prefix structure names with subsystem two-letter prefix

### Structure Naming
- Must be descriptive and unique
- Should not conflict with 3rd party software
- Cannot use global variable names for structure elements

### Examples

❌ Incorrect Usage:
```c
Long myLong;    // Incorrect case for type

#define SMLAYOUT struct smLayout    // Don't use macro for struct
struct smLayout
{
    smFRAME       *psmFrame;
    rnFRAME       *prnFrame;
    struct smUIC  *psmuic;
};
```

✅ Correct Usage:
```c
LONG myLong;    // Correct case for type

struct smLayout    // Direct struct definition
{
    smFRAME       *psmFrame;
    rnFRAME       *prnFrame;
    struct smUIC  *psmuic;
};
```

### Legacy Code with typedef
When working with existing code that uses typedef:

```c
typedef struct smLayout
{
    smFRAME       *psmFrame;
    rnFRAME       *prnFrame;
    struct smUIC  *psmuic;
} smLAYOUT;
```

### PASOE Agent Considerations
❌ Incorrect - Will Fail Compilation:
```c
struct cpTableData
{
    struct collTableData *pHeadAttrChain;    // Fails: pHeadAttrChain is a global variable
    // ...
};
```

### Important Notes
- Structure element names must not match global variables
- PASOE agent uses #define scheme for global variables
- Matching names will cause preprocessor conflicts
- Compilation will fail if structure elements match global variables

## Data Type Guidelines (MANDATORY)

### Approved Data Types

- `TEXT` - For character data (not `char`)
- `COUNT` - 2-byte integer (-32768 to +32767)
- `UCOUNT` - 2-byte unsigned (0 to 65535)
- `LONG` - 4-byte integer (-2B to +2B)
- `ULONG` - 4-byte unsigned (0 to 4B)
- `LONG64` - 8-byte signed integer
- `ULONG64` - 8-byte unsigned integer
- `VOID` - Same as void
- `DOUBLE` - For floating point
- `TTINY` - 1-byte unsigned (0-255)
- `TEXTC` - For string literal casts only
- `PNULL` - For null pointer parameters

### Obsolete Types (Do Not Use)
- `BOOL` - Use `int` instead (0 or 1)
- `TBOOL` - Use `int` or `TTINY`
- `SMALL` - Use `TTINY` or `int`
- `BIT` - Use `TTINY`, `COUNT`, or `LONG`
- `INTERN` - Use `COUNT` or `int`
- `UTEXT` - Use `TEXT`
- `METACH` - Use `COUNT` or `int`
- `FAST` - Remove when found

### Prohibited Types
- `register` - Obsolete
- `void` - Use `VOID`

### Additional Approved Types
- `BYTES` - Unsigned integer large enough to hold any SIZEOF(...)
- `char` - Only use when calling OS routines expecting 'char' type (not for general programming)
- `int` - Preferred return type for performance; preferred for parameters expecting #define constants
- `GLOBAL` - Data which is global to all routines (declare exactly once)
- `IMPORT` - Global data declared elsewhere
- `LOCAL` - Data local to a single source file
- `LOCALF` - Local function declaration

### Data Type Bit Traps and Pitfalls

#### Size of Data Types (64-bit considerations):
- `sizeof(char)` = 8 bits
- `sizeof(short)` = 16 bits
- `sizeof(int)` = 32 bits
- `sizeof(LONG)` = 32 bits
- `sizeof(long)` = 64 bits (different from LONG!)
- `sizeof(LONGLONG)` = 64 bits
- `sizeof(void *)` = 64 bits

#### Shifting Rules:
- Shifting more bits than the data type size has undefined behavior
- Left shifts always fill with 0s
- Right shifts on unsigned always fill with 0s
- Right shifts on signed are machine-dependent (use unsigned to force zero-fill)
- Always use uppercase types: `LONG` not `long`
- Avoid suffix type casting: use `(LONG64)1 << 33` not `1L << 33`

#### Pointer and Integer Casting:
- `sizeof(ULONG) != sizeof(void *)` on 64-bit machines
- Never cast pointers to ULONG or LONG on 64-bit systems
- Never make anything something it is not

## Code Formatting Rules (MANDATORY)

### Indentation and Spacing
1. Use spaces instead of tabs (4 spaces per indentation level)
2. Configure your editor to insert 4 spaces when Tab key is pressed
3. Use spaces between if/while/for/switch, expressions and operators for readability
4. Indent parameters of multi-line function calls to align with the first parameter

### Statements and Assignments
1. Only one statement per line
2. Do not combine an `if` condition and its action on the same line
3. Only one assignment per statement (avoid chained assignments like `a = b = c`)
4. All if/if-else/switch/while/for statements must be followed by a blank line

### Curly Braces
1. Curly braces must be on a separate line
2. Curly braces must be left-justified and aligned with their pair
3. Curly braces are mandatory if any part of an if-else body has multiple lines
4. Curly braces required if condition spans multiple lines
5. Curly braces mandatory for all loop statements (for, while, do)
6. Curly braces required for empty for/while blocks (not just semicolon)
7. No whitespace or comments between if/else and their bodies
8. Curly braces are not required for single-line `if` statements, provided they adhere to all previous rules
9. If any part of an if-else-if chain requires braces, all parts must have braces

## Memory Management (CRITICAL)

1. Parameter Stack:
   - Use stkpsh()/sttkpop() for short-term needs (<100K)
   - Ensure matching pop/push calls

2. Pool Memory:
   - Use stget() for multiple small allocations
   - Use strent()/stvacate() when tracking is needed

3. System Memory:
   - Use utmalloc()/utfree() for large allocations
   - Avoid direct malloc()/free() calls

## Best Practices (Required)

1. Code Structure:
   - Add comments liberally.
   - Avoid `goto` except for error/exit.
   - Limit return calls within functions.
   - Always include `default` in `switch` statements.
   - Avoid machine-dependent conditional compilation.
   - **Function Prototypes**:
     - All functions must be prototyped either in the appropriate public header file or as `LOCALF` function prototypes in the `.c` source file itself.
   - **Function Headers**:
     - All functions must conform to the following standard header format:
       ```c
       /* PROGRAM: name - short description
        *
        * Additional description
        * 
        * RETURNS: List of return values or None for VOID
        */
       return type
       function name(
           1st parameter (description of the parameter),
           2nd parameter (description of the parameter),
           ...
       )
       {
           Function body
       }
       ```

2. Error Handling:
   - Use ASSERT for validation (not FASSERT unless shutdown is required)
   - ASSERT is disabled in released code and has no performance impact
   - Return codes preferred over fatal errors
   - Internal errors prefix: "SYSTEM ERROR:"
   - Avoid re-using existing error messages for new purposes
   - You can re-word existing error messages to improve clarity

2a. Bitwise Operations:
   - Surround bitwise `&` expressions with parentheses for readability
   - Example: `if ((puic->status & UC_DYNAMIC) && puic->lvl == UC_FRMLVL)`

2b. Code Readability:
   - Avoid double and triple negatives
   - Use affirmative logic when possible (e.g., `if (found)` instead of `if (!notfound)`)
   - White space and code readability are desirable
   - Avoid mixed expressions (mixing types, comparing signed to unsigned)
   - Be aware that `sizeof()` returns an unsigned value

3. Threading Considerations:
   - Avoid globals and static values
   - Be careful with memory allocation
   - Consider thread-safe alternatives

4. Unit Testing:
   - Develop tests for new functionality
   - Cover all new code
   - Use debugger to verify behavior
   - Provide unit tests to QA for testing infrastructure
   - Associate unit tests with Enhancement CRs

5. General Best Practices:
   - Add comments liberally to improve readability
   - Avoid `goto` except for error/exit conditions
   - Limit use of return calls within a function
   - Switch statements must always include a `default` case
   - Avoid overuse of macros (debuggers don't handle them well)
   - Avoid machine-dependent conditional compilation in high-level code
   - Avoid globals and static values for threading purposes
   - Don't use FAST/register variables
   - Comment out dead code only for documentation; summarize instead of keeping large blocks
   - Code must compile without warnings on 64-bit Windows, 32-bit Windows, and Linux

6. Function Stubs:
   - When adding stubs to satisfy unresolved symbols (e.g., n2pserv.c, n2scdbg.c)
   - Do not add parameters to stub function declarations
   - This avoids maintenance issues when parameter lists change

## Additional Coding Standards

### Unused Parameters
```c
#define PSC_UNUSED_PARAM(a) (void)a

int myFunc(int numdbs, int flags)
{
    int i;
    PSC_UNUSED_PARAM(flags);
    // ... function body
}
```

### Variable Declarations
```c
// Correct
int MyFunc()
{
    int numdbs;
    int numqrys;
    // ... function body
}
```

### Variable Initialization
- Only initialize variables if the intended behavior is to use them without an assignment
- Avoid unnecessary initialization:

❌ Incorrect:
```c
main()
{
    int ret = 0;
    ret = dbRemoveExtent();
    return ret;
}
```

✅ Correct:
```c
main()
{
    int ret;
    ret = dbRemoveExtent();
    return ret;
}
```

### Function Return Values
- Functions should only return status
- Result values should be returned via parameters
- Use `int` as the preferred return data type for improved runtime performance
- Use `int` for function parameters when expecting #define constants

### Type Definitions
```c
// Preferred
typedef ULONG64 handle_psc_t;
handle_psc_t myHandle;
```

### Copyright Year
- The copyright date in the file header must always include the current year.
- Example:
  ```c
  /****************************************************************************/
  /*                                                                          */
  /* Copyright (c) 2000-2016,2018-2026 by Progress Software Corporation */
  /*                                                                          */
  /* All rights reserved.  No part of this program or document                */
  /* may be reproduced in any form or by any means without                    */
  /* permission in writing from Progress Software Corporation.                */
  /****************************************************************************/
  ```
- Always use the current year (2026) in copyright notices.
- If you are the first to modify a file in a new year, update the copyright year range.

## Sonarqube Guidelines (MANDATORY)

1. Function Size:
   - Keep functions small and focused
   - Minimize cognitive complexity

2. Parameter Limits:
   - Maximum 7 parameters per function
   - Use structures for multiple related parameters

3. Nesting:
   - Avoid nesting beyond 3 levels
   - Keep conditions simple and readable

4. Code Quality:
   - Avoid code duplication
   - Remove commented-out code
   - Keep conditions simple (minimize complex && and || combinations)

## File Names

- Start with 2-3 letter subsystem name
- Check for naming conflicts before creating new files
- Header files typically follow `<subsystem prefix>mgr.h`

### Exceptions for Header Files
- `um` subsystem: separate headers per .c file
- `sm` subsystem: uses `smprocs.h`

## Structure Flags (Required)

- Use structure-specific prefixes:
  - Example: `uicFlags` for struct `uic`
- When extending existing flags:
  - Add number suffix if prefix exists
  - Example: `prochdrflgs2` extends `prochdrflgs`

## Header Files (MANDATORY)

### General Standards
- Each C source file must have an associated API header file
- Header file names match source files (e.g., `rnproc.c` → `rnproc.h`)
- All new files must follow these standards
- Update existing files to conform when possible

### Header File Organization
1. **API Header Files**
   - Contain all public function prototypes
   - Include file-specific structure definitions
   - Named same as source file (e.g., `rnproc.h` for `rnproc.c`)

2. **Source File Organization**
   - Local functions/structures at top after includes
   - Common structures in layer-specific headers
   - Large structure groups in role-specific headers

3. **Layer-Specific Headers**
   - Named `<layerPrefix>misc.h` (e.g., `rnmisc.h`)
   - Contain structures shared across multiple files
   - Layer ownership based on first definition

### Header File Template
```c
#ifndef RNMGR_H
#define RNMGR_H

/* Public interface declarations */

#endif /* RNMGR_H */
```

### Include File Dependencies
- Caller responsible for including required headers
- Include order matters
- Required headers must be included before API headers
- Example: include `**misc.h` before specific role headers

### Best Practices
- Always use include guards
- Place include guards as first lines
- Group related declarations together
- Document public interfaces clearly
- Keep dependencies minimal and explicit

## C Source Files (MANDATORY)

### Copyright Headers
Each .c source file must begin with this copyright notice:

```c
/*************************************************************/
/* Copyright (c) 1984-2026 by Progress Software Corporation  */
/*                                                           */
/* All rights reserved.  No part of this program or document */
/* may be reproduced in any form  or by  any means without   */
/* permission in writing from Progress Software Corporation. */
/*************************************************************/
```

- If you are the first to change a .c file in a new year, update the copyright date
- The `$Log$`, `$Header$`, and `$Id$` directives are unnecessary and should be removed

### Include Files
- Do not `#include` unnecessary header files (causes unnecessary re-compilation)
- `syscall.h` should not be included; include system header files directly

---

## Testing Standards (Required)

### Unit Testing Requirements
All new functionality must include comprehensive unit tests:

1. **Test Coverage**:
   - Write tests for all new functions and features
   - Cover all code paths (success and error scenarios)
   - Test boundary conditions and edge cases

2. **Test Quality**:
   - Use meaningful test names that describe what is being tested
   - Document test setup and expected results
   - Verify behavior using debugger where appropriate

3. **Memory Testing**:
   - Verify no memory leaks using appropriate tools
   - Test proper cleanup of allocated resources
   - Validate correct use of memory management functions

4. **Threading Tests**:
   - Test thread safety where applicable
   - Verify PASOE agent compatibility when relevant
   - Test with `-DMTAPSV` compilation flag for multi-threading

5. **Integration**:
   - Provide unit tests to QA for testing infrastructure
   - Associate unit tests with Enhancement CRs
   - Document test dependencies and requirements

### Test Organization
```c
/* Test file naming: test_<module>.c */
/* Example: test_rnproc.c for rnproc.c */

/*************************************************************/
/* Copyright (c) 1984-2026 by Progress Software Corporation  */
/*************************************************************/

/* Test functions should be clearly named */
int testFunctionName_successCase(void)
int testFunctionName_errorCase(void)
int testFunctionName_boundaryCondition(void)
```

### Example Test Structure
```c
/* PROGRAM: testBmLockDownMasterBlock - Test master block locking
 *
 * Tests the bmLockDownMasterBlock function with various scenarios
 * 
 * RETURNS: 0 on success, non-zero on failure
 */
int
testBmLockDownMasterBlock_success(void)
{
    int result;
    
    /* Setup */
    setupTestEnvironment();
    
    /* Execute */
    result = bmLockDownMasterBlock();
    
    /* Verify */
    if (result != 0)
    {
        fprintf(stderr, "Test failed: expected 0, got %d\n", result);
        return 1;
    }
    
    /* Cleanup */
    cleanupTestEnvironment();
    
    return 0;  /* Success */
}
```

---

## Summary

All C code must comply with these mandatory standards before merge:

✅ **Variable Naming**: Meaningful camelCase names, pointer prefixes, no single letters
✅ **Function Naming**: Subsystem prefix required, descriptive names
✅ **Data Types**: Use approved types only (no BOOL, FAST, void, register)
✅ **Memory Management**: Use utmalloc/utfree, proper cleanup, match push/pop
✅ **Code Formatting**: 4 spaces, braces on separate lines, one statement per line
✅ **Global Variables**: Avoid - use alternatives like pvm_context structure
✅ **Type Definitions**: No macros for structs, use direct struct definitions
✅ **Header Files**: Each .c has .h, include guards, proper organization
✅ **Copyright**: Current year (2026), update when first to modify in new year
✅ **Function Standards**: Prototypes required, proper headers, return status only
✅ **Error Handling**: Use ASSERT (not FASSERT), return codes preferred
✅ **Threading**: No globals/statics, PASOE compatibility, test with -DMTAPSV
✅ **Sonarqube**: Max 7 params, no deep nesting, no duplication, low complexity
✅ **Testing**: Unit tests for all new code, cover all paths, verify memory
✅ **Platform Compatibility**: Compile without warnings on Windows (32/64-bit) and Linux

Use code quality tools and linters to validate compliance before submitting for review. Refer to [general-c-instructions.md](general-c-instructions.md) for additional quick-reference guidelines and best practices.
