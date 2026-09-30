# C++ Pre-Commit Code Review

## How to Use

1. **Open your changed C++ files** in VS Code
2. **Open GitHub Copilot Chat** (Ctrl+Alt+I or Cmd+Alt+I)
3. **Reference this prompt file** using @review-cpp.prompt.md
4. **Submit** and review the results
5. **Fix issues** and commit with confidence

---

## The Prompt

**⚠️ MOST IMPORTANT: Comprehensive Industry Best Practices First**

When reviewing code, prioritize industry best practices and established software engineering principles alongside the specific rules defined in this document. The rules below complement, not replace, fundamental coding standards such as:
- Modern C++ best practices (C++11 standard)
- RAII (Resource Acquisition Is Initialization)
- Exception safety and smart pointer usage
- SOLID principles
- Clean Code principles (readability, maintainability, simplicity)
- DRY (Don't Repeat Yourself)
- Security by design
- Performance and efficiency
- Error handling and resilience

The full prompt checks ALL standards organized by category:
- Variable naming conventions (MANDATORY)
- Function/Method naming standards (MANDATORY)
- Class and namespace naming (MANDATORY)
- Global variable restrictions (CRITICAL)
- Type definitions and aliases (MANDATORY)
- Data type guidelines (MANDATORY)
- Code formatting rules (MANDATORY)
- Memory management and RAII (CRITICAL)
- Const correctness (MANDATORY)
- Class design (Rule of Zero/Three/Five) (MANDATORY)
- Exception handling (MANDATORY)
- Smart pointer usage (MANDATORY)
- Best practices (Required)
- Sonarqube compliance (MANDATORY)
- Header file organization (MANDATORY)
- Copyright requirements (MANDATORY)
- Testing standards (Required)

---

## 💡 Quick Tips

**For focused reviews**, you can add specific instructions:
- "Focus on memory management and RAII only"
- "Check data types and smart pointer usage"
- "Review class design and Rule of Five"
- "Verify exception safety"
- "Check const correctness"

**For learning**, ask:
- "Explain the approved C++11 data types with examples"
- "Why should I use std::unique_ptr instead of raw pointers?"
- "Show me the correct method header format"
- "What is the Rule of Zero/Three/Five?"

**False positives?**
- "Is line 42 really a violation?"
- "This pattern is required by [legacy code] - is it acceptable?"

---

## 🔗 Related Resources

- **Full Standards**: [code-review-CPP-standards.md](../instructions/cpp/code-review-CPP-standards.md)
- **General Guidelines**: [general-cpp-instructions.md](../instructions/cpp/general-cpp-instructions.md)
- **Global Standards**: [../instructions/global-instructions.md](../instructions/global-instructions.md)

---

## Review Instructions

Please perform a comprehensive code review of the C++ files using the standards defined in [code-review-CPP-standards.md](../instructions/cpp/code-review-CPP-standards.md).

---

## Output Format

For each issue found, provide:

1. **Location**: File name and line number(s)
2. **Severity**: MANDATORY, CRITICAL, Required, or Recommended
3. **Issue**: Clear description of the problem
4. **Standard**: Reference to specific standard violated
5. **Fix**: Concrete suggestion with code example

Example:
```
📍 esamApiContext.cpp:42
🔴 MANDATORY: Variable naming violation
❌ Problem: Variable `trid` is unclear abbreviation
📖 Standard: Variable names must be meaningful (code-review-CPP-standards.md)
✅ Fix: Rename to `transactionId`
```

---

## Success Criteria

✅ Code passes when:
- All MANDATORY items are compliant
- All CRITICAL items are addressed
- Required items are followed (or documented exceptions)
- No Sonarqube violations
- Clean compilation on all platforms
- Modern C++11 practices followed
