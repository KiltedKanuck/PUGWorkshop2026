# C Pre-Commit Code Review

## How to Use

1. **Open your changed C files** in VS Code
2. **Open GitHub Copilot Chat** (Ctrl+Alt+I or Cmd+Alt+I)
3. **Reference this prompt file** using @review-c.prompt.md
4. **Submit** and review the results
5. **Fix issues** and commit with confidence

---

## The Prompt

**⚠️ MOST IMPORTANT: Comprehensive Industry Best Practices First**

When reviewing code, prioritize industry best practices and established software engineering principles alongside the specific rules defined in this document. The rules below complement, not replace, fundamental coding standards such as:
- memory management and pointer safety is paramount
- SOLID principles
- Clean Code principles (readability, maintainability, simplicity)
- DRY (Don't Repeat Yourself)
- Security by design
- Performance and efficiency
- Error handling and resilience

The full prompt checks ALL standards organized by category:
- Variable naming conventions (MANDATORY)
- Function naming standards (MANDATORY)
- Global variable restrictions (CRITICAL)
- AUTODITM variables (MANDATORY)
- Type definitions (MANDATORY)
- Data type guidelines (MANDATORY)
- Code formatting rules (MANDATORY)
- Memory management (CRITICAL)
- Best practices (Required)
- Sonarqube compliance (MANDATORY)
- Header file organization (MANDATORY)
- Copyright requirements (MANDATORY)
- Testing standards (Required)

---

## 💡 Quick Tips

**For focused reviews**, you can add specific instructions:
- "Focus on memory management only"
- "Check data types and type definitions"
- "Review function naming and headers"
- "Verify PASOE thread safety"

**For learning**, ask:
- "Explain the approved data types with examples"
- "Why can't I use void, long, or char?"
- "Show me the correct function header format"

**False positives?**
- "Is line 42 really a violation?"
- "This pattern is required by [legacy code] - is it acceptable?"

---

## 🔗 Related Resources

- **Full Standards**: [code-review-C-standards.md](../instructions/c/code-review-C-standards.md)
- **General Guidelines**: [general-c-instructions.md](../instructions/c/general-c-instructions.md)
- **Global Standards**: [../instructions/global-instructions.md](../instructions/global-instructions.md)


