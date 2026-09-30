# Python Pre-Commit Code Review

## How to Use

1. **Open your changed Python files** in VS Code
2. **Open GitHub Copilot Chat** (Ctrl+Alt+I or Cmd+Alt+I)
3. **Reference this prompt file** using @review-python.prompt.md
4. **Submit** and review the results
5. **Fix issues** and commit with confidence


---

## The Prompt

**⚠️ MOST IMPORTANT: Comprehensive Industry Best Practices First**

When reviewing code, prioritize industry best practices and established software engineering principles alongside the specific rules defined in this document. The rules below complement, not replace, fundamental coding standards such as:
- proper resource and memory management (use context managers, avoid unnecessary circular references, and close file/network resources)
- SOLID principles
- Clean Code principles (readability, maintainability, simplicity)
- DRY (Don't Repeat Yourself)
- Security by design
- Performance and efficiency
- Error handling and resilience

The full prompt checks ALL 12 categories:
- Naming Conventions (MANDATORY)
- Code Formatting and Style (MANDATORY)
- Type Hints and Annotations (CRITICAL)
- Function and Method Design (MAJOR)
- Class Design and SOLID (CRITICAL)
- Exception Handling (CRITICAL)
- Imports and Module Organization (MANDATORY)
- Documentation and Comments (MANDATORY)
- Testing and Coverage (MANDATORY)
- Security (CRITICAL)
- Performance (MAJOR)
- Code Complexity (MAJOR)

---

## 💡 Quick Tips

**For focused reviews**, you can add specific instructions:
- "Focus on type hints and type safety only"
- "Check exception handling patterns"
- "Review for SOLID principles violations"
- "Verify security and input validation"
- "Check test coverage and mocking patterns"

**For learning**, ask:
- "Explain why catching Exception is bad with examples"
- "Show me proper type hint patterns"
- "What are the code complexity issues here?"
- "How should I structure this to follow SOLID?"

**False positives?**
- "Is line 42 really a violation?"
- "This pattern is required by [framework] - is it acceptable?"
- "Should I use a different exception type here?"

---

## 🔗 Related Resources

- **Full Standards**: [code-review-PYTHON-standards.md](../instructions/python/code-review-PYTHON-standards.md)
- **General Guidelines**: [general-python-instructions.md](../instructions/python/general-python-instructions.md)
- **Global Standards**: [instructions/global-instructions.md](../instructions/global-instructions.md)

---

**Before Committing:**
Run these tools locally to validate your code:
```bash
black --check src/
flake8 src/
mypy src/
pytest --cov=src
```

The Copilot review will check compliance with these tools.


