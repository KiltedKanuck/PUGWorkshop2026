---
applyTo: '**/*.{p,cls,w,i,t}'
---

# Code Review Rules for ABL

## Overview

This document contains 101 mandatory code review rules for OpenEdge ABL code, organized by severity level:
- **BLOCKER**: Must be fixed immediately - blocks release
- **CRITICAL**: Must be fixed before merge - causes bugs, security issues, or compilation failures
- **MAJOR**: Should be fixed - impacts performance, maintainability, or quality
- **MINOR**: Recommended to fix - improves code quality and consistency
- **INFO**: Information or low-priority improvements

**Related Documentation**: See [general-abl-instructions.md](general-abl-instructions.md) for additional coding guidelines, best practices, and project structure requirements.

## MCP Server Validation

Use the **openEdge-abl-mcp-server** to validate code against these rules:
- Query the **12.8 collection** for ABL language reference and syntax validation
- Verify built-in functions, statements, and keywords
- Check grammar and language constructs

---

## Critical & Blocker Rules

### 1. Empty Statement (CRITICAL)
Empty statements (double periods) are usually introduced by mistake.

**Noncompliant:**
```abl
define variable xx as int no-undo..
```

**Compliant:**
```abl
define variable xx as int no-undo.
```

### 2. Dot Comment (BLOCKER)
Statements starting with a period are comments and not highlighted by editors.

**Noncompliant:**
```abl
.MESSAGE "Hello world!".
```

**Compliant:**
```abl
// MESSAGE "Hello world!".
```

### 3. Class Name Casing (CRITICAL)
Class name case must match file name case. Different case causes UNIX compilation problems.

**Noncompliant:**
```abl
// File: MyClass.cls
PUBLIC CLASS myclass:
END CLASS.
```

**Compliant:**
```abl
// File: MyClass.cls
PUBLIC CLASS MyClass:
END CLASS.
```

### 4. Include Name Casing (CRITICAL)
Include file reference case must match file name case for UNIX compatibility.


### 5. Backslash Curly Brace (CRITICAL)
Code compiles on UNIX but not Windows.

**Noncompliant:**
```abl
DISPLAY "My \{ string".
```

**Compliant:**
```abl
DISPLAY "My ~{ string".
```

### 6. Shared Variables (CRITICAL)
Avoid SHARED variables - they create tight coupling.


### 7. FOR FIRST/LAST with BY Clause (CRITICAL)
FOR FIRST/LAST returns first record by index, NOT by BY clause.

**Noncompliant:**
```abl
FOR FIRST Customer WHERE Customer.City BEGINS 'Abil' BY Customer.City BY Customer.Name.
  DISPLAY CustNum City CustName.
```

**Compliant:**
```abl
FOR EACH Customer WHERE Customer.City BEGINS 'Abil' BY Customer.City BY Customer.Name:
  DISPLAY CustNum City CustName.
  LEAVE.
END.
```

### 8. UNDO Without Option (CRITICAL)
UNDO without RETRY/LEAVE/THROW/NEXT defaults to RETRY.

**Noncompliant:**
```abl
LoopName:
DO WHILE condition:
  UNDO LoopName.
END.
```

**Compliant:**
```abl
LoopName:
DO WHILE condition:
  UNDO, RETRY LoopName.
END.
```

### 9. Wrong ASSIGN WHEN (BLOCKER)
WHEN clause evaluated before assignment, not after.

**Noncompliant:**
```abl
assign
  var2 = "xxx" when var1 = "something"
  var3 = "yyy" when var2 = "xxx".  // Evaluated BEFORE first assignment!
```

**Compliant:**
```abl
assign var2 = "xxx" when var1 = "something".
assign var3 = "yyy" when var2 = "xxx".
```

### 10. Expression No Effect (CRITICAL)
Expression statement has no effect.

**Noncompliant:**
```abl
count + count + 1.  // Should be: count = count + 1
```

### 11. Serializable Error (CRITICAL)
Classes inheriting Progress.Lang.AppError must be serializable.

**Noncompliant:**
```abl
class rssw.serial03 inherits AppError:
end class.
```

**Compliant:**
```abl
class rssw.serial03 inherits AppError serializable:
end class.
```

### 12. Log or Rethrow Exception (CRITICAL)
Exception not accessed in CATCH block means silently ignored.

**Noncompliant:**
```abl
CATCH caught AS Progress.Lang.Error:
  DISPLAY "Error".  // caught not accessed
END CATCH.
```

**Compliant:**
```abl
CATCH uncaught AS Progress.Lang.Error:
  DISPLAY "Error".
END CATCH.
```

### 13. Nested DO Same Variable (CRITICAL)
Nested DO statements using same variable.

**Noncompliant:**
```abl
do x1 = 1 to 10:
  do x1 = 1 to 10:  // Should be x2
  end.
end.
```

### 14. Record Search by Constant (CRITICAL)
Use explicit WHERE clause instead of constant.

**Noncompliant:**
```abl
find customer 15.
```

**Compliant:**
```abl
find customer where customer.custnum = 15.
```

### 15. Indentation Check (CRITICAL)
Incorrect indentation indicates potential bugs.


### 16. Sort Access Whole Index (BLOCKER)
Combined SORT-ACCESS and WHOLE-INDEX = extremely slow query.


### 17. Dynamic Object Leak (BLOCKER)
Dynamically created objects must be released.

**Compliant:**
```abl
finally:
  if valid-handle(bCust) then delete object bCust.
  if valid-handle(qCust) then delete object qCust.
end finally.
```

### 18. RECID Keyword (BLOCKER)
Use ROWID instead of deprecated RECID.

**Noncompliant:**
```abl
DEFINE VARIABLE test AS RECID.
ASSIGN test = RECID(Customer).
```

**Compliant:**
```abl
DEFINE VARIABLE test AS ROWID.
ASSIGN test = ROWID(Customer).
```

## Major Rules

### 19. Share Lock (MAJOR)
**MANDATORY**: Always specify NO-LOCK or EXCLUSIVE-LOCK explicitly. Never rely on default locking behavior.

**Noncompliant:**
```abl
FOR EACH Customer:
  DISPLAY Customer.
END.
```

**Compliant:**
```abl
FOR EACH Customer NO-LOCK:
  DISPLAY Customer.
END.
```

### 20. Too Many Parameters (MAJOR)
Methods should not have too many parameters (default max: 8).


### 21. TABLE-SCAN and WHERE (MAJOR)
WHERE clause with TABLE-SCAN explicitly disables indexes.


### 22. Unused Parameter (MAJOR)
Remove unused parameters.


### 23. Invalid USE-INDEX (MAJOR)
Invalid index name in USE-INDEX is silently discarded.


### 24. USE-INDEX Keyword (MAJOR)
USE-INDEX prevents query engine from selecting best index.


### 25. Whole Index (MAJOR)
WHOLE-INDEX means no optimized key references possible.


### 26. Unused Buffer (MAJOR)
Remove unused buffers.


### 27. OF Keyword (MAJOR)
Use explicit WHERE instead of OF keyword.

**Noncompliant:**
```abl
FOR EACH Order, EACH OrderLine OF Order:
END.
```

**Compliant:**
```abl
FOR EACH Order, EACH OrderLine WHERE OrderLine.OrderNum = Order.OrderNum:
END.
```

### 28. NO-UNDO (MAJOR)
**MANDATORY**: Always use NO-UNDO for temporary variables to avoid before-image overhead. Only omit NO-UNDO when transaction rollback capability is explicitly required for the variable.

**Noncompliant:**
```abl
DEFINE VARIABLE myVar AS CHARACTER.
```

**Compliant:**
```abl
DEFINE VARIABLE myVar AS CHARACTER NO-UNDO.
```

### 29. Avoid NO-ERROR (MAJOR)
Use structured error handling instead of NO-ERROR.

**Noncompliant:**
```abl
ASSIGN xx = INTEGER(zz) NO-ERROR.
IF ERROR-STATUS:ERROR THEN DO:
  MESSAGE "Error".
END.
```

**Compliant:**
```abl
DO ON ERROR UNDO, RETURN:
  ASSIGN xx = INTEGER(zz).
  CATCH caught AS Progress.Lang.Error:
    MESSAGE "Error".
  END CATCH.
END.
```

### 30. FIND Without NO-ERROR (MAJOR)
FIND without NO-ERROR may raise runtime error.

**Noncompliant:**
```abl
FIND FIRST Customer NO-LOCK.
```

**Compliant:**
```abl
FIND FIRST Customer NO-LOCK NO-ERROR.
```

### 31. Commented Out Code (MAJOR)
Delete commented code - use source control instead.

## Performance Rules

### 32. No Routine in Loop (MINOR)
Avoid function calls in loop conditions.

**Noncompliant:**
```abl
do xx = 1 to GetMaxVal():
end.
```

**Compliant:**
```abl
assign zz = GetMaxVal().
do xx = 1 to zz:
end.
```

### 33. No Routine in WHERE (CRITICAL)
Don't use functions in WHERE clause - unpredictable behavior.


### 34. NO-WAIT (INFO)
Use NO-WAIT with EXCLUSIVE-LOCK to avoid timeout waits.

**Compliant:**
```abl
FIND FIRST Customer EXCLUSIVE-LOCK NO-WAIT.
IF AVAILABLE Customer THEN DO:
END 
ELSE IF LOCKED Customer THEN DO:
END.
```

## Code Quality Rules

### 35. Disable Triggers (INFO)
Don't use DISABLE TRIGGERS in application code.


### 36. Nested Comments (INFO)
Avoid nested comments - hard to know where comment ends.


### 37. No RETURN in Function (INFO)
Function/method must have RETURN statement.

**Compliant:**
```abl
FUNCTION f1 RETURNS INTEGER:
  DEF VAR xxx AS INT.
  xxx = /* logic */.
  RETURN xxx.
END FUNCTION.
```

### 38. Block Label (MINOR)
Use block labels with NEXT/LEAVE for clarity.

**Compliant:**
```abl
audit_salesrep:
FOR EACH SalesRep:
  FOR EACH customer OF SalesRep:
    IF condition THEN
      NEXT audit_salesrep.
  END.
END.
```

### 39. RETURN ERROR (INFO)
RETURN ERROR should have message argument.

**Noncompliant:**
```abl
RETURN ERROR.
```

**Compliant:**
```abl
RETURN ERROR "Text message".
```

### 40. Empty FIELDS List (INFO)
In OpenEdge 12+, FIELDS() returns no fields (breaking change).


### 41. Undefined Named Include (CRITICAL)
Named include parameter must have value assigned.

**Noncompliant:**
```abl
{ include.i &param1 &param2=2 }
```

**Compliant:**
```abl
{ include.i &param1=1 &param2=2 }
```

## Portability Rules

### 42. Backslash in String (INFO)
Use tilde escape instead of backslash for UNIX compatibility.

**Noncompliant:**
```abl
DISPLAY "My \\ string".
```

**Compliant:**
```abl
DISPLAY "My ~\ string".
```

## Convention Rules

### 43. Abbreviated Keywords (INFO)
Don't abbreviate keywords - use full names.

**Noncompliant:**
```abl
MESSAGE SUBST("Test &1", "Param1").
```

**Compliant:**
```abl
MESSAGE SUBSTITUTE("Test &1", "Param1").
```

**Default Excluded:** DEFINE, VARIABLE, CHARACTER, INTEGER, DECIMAL, LOGICAL, PARAMETER


### 44. Colon-T Trim (MINOR)
:T attribute trims leading/trailing spaces.

**Noncompliant:**
```abl
MESSAGE " Test":T.  // Spaces will be trimmed
```

**Compliant:**
```abl
MESSAGE "Test":T.
```

### 45. Wildcard Imports (MINOR)
Don't use wildcard USING statements.

**Noncompliant:**
```abl
USING Progress.Lang.*.
```

**Compliant:**
```abl
USING Progress.Lang.Error.
```

### 46. Keyword Case (INFO)
Enforce consistent keyword casing with annotations.

Use `@LowerCase.` or `@UpperCase.` annotations.


### 47. Function Naming (MINOR)
Use only alphanumeric characters in function/method names.

**Noncompliant:**
```abl
PROCEDURE compute!Value:
PROCEDURE définirValeur:
```

**Compliant:**
```abl
PROCEDURE computeValue:
PROCEDURE definirValeur:
```

### 48. Tabs Indent (INFO)
Use spaces, not tabs, for indentation.


### 49. String Attribute (MINOR)
Specify :C, :L, :R, :T, or :U on quoted strings.

**Noncompliant:**
```abl
ASSIGN var1 = 'test'.
```

**Compliant:**
```abl
ASSIGN var1 = 'test':U.
```

### 50. Conditional Expression Brackets (MINOR)
Enclose IF expressions in brackets to avoid ambiguity.

**Compliant:**
```abl
message ( if xx[1] = ? then "" else string(xx[1]) ) + sep.
```

### 51. Buffer Usage in WHERE (CRITICAL - BETA)
Main buffer should be on left side of comparisons.

**Compliant:**
```abl
for each customer where customer.name = "Lift Tours",
    each order where order.custnum = customer.custnum:
end.
```

### 52. FIND FIRST vs Unique Index (MINOR)
Don't use FIRST/LAST with unique index.

**Noncompliant:**
```abl
FIND FIRST Customer WHERE CustNum = 1.
```

**Compliant:**
```abl
FIND Customer WHERE CustNum = 1.
```

### 53. Temp-Table Field Sort (MINOR)
Explicitly specify ASCENDING/DESCENDING on all index components.

**Compliant:**
```abl
define temp-table tt01
  field fld1 as char
  field fld2 as char
  field fld3 as char
  index tt01-i1 is unique fld1 fld2 descending fld3 descending.
```

### 54. CAN-DO in WHERE Clause (MAJOR)
CAN-DO is executed client-side, slowing down query execution.


### 55. Variable in WHERE Changed (MAJOR)
WHERE clause evaluated once - changing variables in block has no effect.

**Noncompliant:**
```abl
define variable zz as integer no-undo initial 10.
for each myTT where myTT.fld1 <= zz:
  assign zz = zz + 10.  // Record #2 will not be read
end.
```

### 56. Unary PLUS Operator (INFO)
Unary + operator is unnecessary.

**Noncompliant:**
```abl
x1 =+ x2.  // Should be x1 += x2 or x1 = x2
```

### 57. Default Property Implementation (MINOR)
Use default GET/SET instead of identical custom implementation.

**Noncompliant:**
```abl
define public property MyProperty01 as character no-undo
  get:
    return MyProperty01.
  end get.
```

**Compliant:**
```abl
define public property MyProperty01 as character no-undo get. set.
```

### 58. Unquoted OS Command Parameter (INFO)
OS-COMMAND and OS-CREATE-DIR should use quoted strings.


### 59. DOS Keyword (MINOR)
Use OS-COMMAND instead of deprecated DOS keyword.


### 60. SUBSTITUTE LONGCHAR Mix (MAJOR)
Mixing CHAR and LONGCHAR in SUBSTITUTE can cause runtime error 2922.


### 61. Variable Read But Not Assigned (MAJOR)
Variable is read but never assigned a value.


### 62. Sort Access (INFO)
BY option requires on-the-fly sorting when no matching index exists.


### 63. Comment Tracker (INFO - Template)
Track comments matching a regular expression.


### 64. Invalid SUBSTITUTE Parameters (INFO)
Parameter count must match placeholders in base string.

**Noncompliant:**
```abl
message substitute("First &1 Second &2 Third &3", "1", "2").  // Missing parameter
message substitute("First &0 Second &2", "1", "2").  // &0 not allowed
```

### 65. Split Comma-Separated Strings (MAJOR)
Split translatable comma-separated lists for proper translation.


### 66. i18n Length (MAJOR)
LENGTH/OVERLAY/SUBSTRING must specify type parameter for i18n.

**Noncompliant:**
```abl
MESSAGE LENGTH('乗').  // Returns 1, not character count
```

**Compliant:**
```abl
MESSAGE LENGTH('乗', 'CHARACTER').  // 1 character
MESSAGE LENGTH('乗', 'COLUMN').     // 2 columns
MESSAGE LENGTH('乗', 'RAW').        // 3 bytes in UTF-8
```

### 67. Class Naming Convention (MINOR)
Class names should follow naming convention (default: lowercase packages, PascalCase class).


### 68. Global Shared Variables (CRITICAL)
Avoid GLOBAL SHARED variables.


### 69. Variable Overflow (MAJOR)
Conversion could overflow variable (LONGCHAR→CHAR, INT64→INTEGER).

**Noncompliant:**
```abl
DEFINE VARIABLE lcVar1 AS LONGCHAR NO-UNDO.
DEFINE VARIABLE cVar2  AS CHARACTER NO-UNDO.
ASSIGN cVar2 = "Prefix " + lcVar1.  // Fails if lcVar > 31999 bytes
```

## Security Rules

### 70. ENCODE Keyword (CRITICAL - VULNERABILITY)
Don't use ENCODE for storing secrets - high collision risk.


### 71. Outdated Digest (CRITICAL - VULNERABILITY)
Don't use MD5 or SHA-1 - use SHA-512 instead.

**Noncompliant:**
```abl
md5-digest("xxx").
sha1-digest("xxx").
```

**Compliant:**
```abl
message-digest('sha-512', "xxx").
```

### 72. Authentication-Domain Table (CRITICAL - VULNERABILITY - DEPRECATED)
Don't use _sec-authentication-domain table.


### 73. PROFILER Keyword (MINOR - VULNERABILITY)
Don't use PROFILER in production.


### 74. RANDOM Keyword (MINOR - VULNERABILITY)
Don't use RANDOM in security-sensitive contexts.


### 75. DEBUGGER Keyword (MINOR - VULNERABILITY)
Don't use DEBUGGER in production.


### 76. Hash Without Salt (CRITICAL - VULNERABILITY)
Always use salt with cryptographic hashes.


### 77. GENERATE-UUID Assignment (CRITICAL - VULNERABILITY)
Don't use GENERATE-UUID for record identifiers - values too similar.


### 78. INI File Assignment (CRITICAL - SECURITY HOTSPOT)
Modifying INI/registry could lead to PROPATH modification and code injection.


### 79. Dynamic Query Injection (MINOR - SECURITY HOTSPOT)
Formatting ABL queries is security-sensitive.

**Noncompliant:**
```abl
qry:QUERY-PREPARE("for each customer where name = '" + inputParam + "'").
```

**Compliant:**
```abl
qry:QUERY-PREPARE(SUBSTITUTE("for each customer where name = &1", QUOTER(inputParam))).
```

### 80. External Library Usage (CRITICAL - SECURITY HOTSPOT)
PROCEDURE EXTERNAL calls to non-standard libraries are security-sensitive.


### 81. SESSION:EXPORT (CRITICAL - SECURITY HOTSPOT)
Modifying AppServer export list is security-sensitive.


### 82. Open Redirect (CRITICAL - SECURITY HOTSPOT)
Location header with user input can lead to open redirect.


### 83. Internal Use Keyword (MINOR - SECURITY HOTSPOT)
WEB-CONTEXT keywords marked "Internal Use" shouldn't be used.


### 84. PROPATH Assignment (INFO - SECURITY HOTSPOT)
PROPATH modification could lead to code injection.


### 85. Hard Coded Credentials (CRITICAL - SECURITY HOTSPOT)
CONNECT statements should include -U and -P parameters.


### 86. OS Command Injection (CRITICAL - SECURITY HOTSPOT)
OS-COMMAND and RUN VALUE() are vulnerable to injection.


### 87. Dynamic CALL (CRITICAL - SECURITY HOTSPOT)
DYNAMIC-CALL can run functions from external libraries.


### 88. ActiveX Component (CRITICAL - SECURITY HOTSPOT)
CREATE CONTROL-FRAME for ActiveX components is security-sensitive.

## Compiler Warning Rules

### 89. All Code Paths Must Return (CRITICAL)
All code paths in function/method must return a value.


### 90. Large Transaction Scope (CRITICAL)
Transaction scope spans entire procedure - may not be desired.


### 91. Dead Code (CRITICAL)
Code will never be executed.


### 92. Abbreviated Keywords Not Authorized (INFO)
All keywords must be fully spelled out (compiler option).


### 93. Valid Yet Clumsy Syntax (BLOCKER)
Avoid clumsy syntax quirks (e.g., method ending with colon, missing periods).


### 94. Subscript in CONTAINS Ignored (MINOR)
Array subscript in CONTAINS phrase is ignored.


### 95. TRANSACTION Within Transaction (CRITICAL)
TRANSACTION keyword within existing transaction has no effect.


### 96. Proparse Error (INFO)
Error during code parsing phase.


### 97. IMPORT UNFORMATTED Multiple Fields (MINOR)
IMPORT UNFORMATTED only reads first field.


### 98. Fields Must Be Qualified (MAJOR)
All buffer references must be fully qualified with table name.


### 99. Expression Evaluates to Constant (MINOR)
Expression compiles to constant - likely a mistake.


### 100. Generic Compiler Warning (MINOR)
Generic warning raised by OpenEdge compiler.


### 101. Translation Exceeds Length (CRITICAL)
Translation in xlate db exceeds initial string size.

---

## Testing Standards

### ABLUnit Test Requirements
- Write comprehensive unit tests using ABLUnit framework
- Maintain parallel test structure: `src/main/abl` code has tests in `src/test/abl`
- Test both success and error scenarios
- Use meaningful test names that describe what is being tested
- Query openEdge-abl-mcp-server collection "12.8" for ABLUnit syntax and patterns
- Follow test naming conventions: `test{MethodName}_{Scenario}` (e.g., `testCalculateTotal_WithValidInput`)
- Use `@Test` annotations for test methods
- Use `@Setup` and `@TearDown` for test initialization and cleanup
- Mock external dependencies where appropriate
- Aim for high code coverage but prioritize meaningful tests over coverage metrics

### Test Organization
```
src/
├── main/
│   └── abl/
│       └── MyClass.cls
└── test/
    └── abl/
        └── MyClassTest.cls
```

### Example Test Structure
```abl
using Progress.Lang.*.using OpenEdge.Core.Assert.*.using MyApp.MyClass.

class MyApp.Test.MyClassTest:
    
    define private variable objMyClass as MyClass no-undo.
    
    @Setup.
    method public void setUp():
        objMyClass = new MyClass().
    end method.
    
    @TearDown.
    method public void tearDown():
        delete object objMyClass.
    end method.
    
    @Test.
    method public void testCalculateTotal_WithValidInput():
        define variable result as decimal no-undo.
        
        result = objMyClass:CalculateTotal(100, 0.10).
        
        Assert:Equals(110.00, result).
    end method.
    
    @Test.
    method public void testCalculateTotal_WithNegativeValue():
        define variable errorThrown as logical no-undo initial false.
        
        catch err as Progress.Lang.Error:
            errorThrown = true.
        end catch.
        
        objMyClass:CalculateTotal(-100, 0.10).
        
        Assert:IsTrue(errorThrown, "Expected error for negative value").
    end method.
    
end class.
```

---

## Summary

All ABL code must pass these 101 code review rules before merge. Use automated tools (openEdge-abl-mcp-server) to validate compliance. Refer to [general-abl-instructions.md](general-abl-instructions.md) for additional coding standards and best practices.