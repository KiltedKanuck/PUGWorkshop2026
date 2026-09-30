# ABL Pre-Commit Code Review

## How to Use

1. **Open your changed ABL files** in VS Code
2. **Open GitHub Copilot Chat** (Ctrl+Alt+I or Cmd+Alt+I)
3. **Reference this prompt file** using @review-abl.prompt.md
4. **Submit** and review the results
5. **Fix issues** and commit with confidence

---

## The Prompt

**⚠️ MOST IMPORTANT: Comprehensive Industry Best Practices First**

When reviewing code, prioritize industry best practices and established software engineering principles alongside the specific rules defined in this document. The rules below complement, not replace, fundamental coding standards such as:
- object cleanup, DELETE OBJECT usage, and memory management are paramount
- SOLID principles
- Clean Code principles (readability, maintainability, simplicity)
- DRY (Don't Repeat Yourself)
- Security by design
- Performance and efficiency
- Error handling and resilience

The full prompt checks ALL 101 rules organized by category:
- Critical & Blocker Rules
- Major Rules
- Performance Rules
- Code Quality Rules
- Portability Rules
- Convention Rules
- Security Rules
- Compiler Warning Rules
- Testing Standards

**Note**: The prompt includes guidance to use openEdge-abl-mcp-server (collection 12.8) to validate ABL syntax if needed.

---

## 💡 Quick Tips

**For focused reviews**, you can add specific instructions:
- "Focus on security issues only"
- "Check database operations and locking"
- "Review naming conventions"
- "UNIX compatibility check"

**For learning**, ask:
- "Explain rule #15 with examples"
- "Why is this a CRITICAL issue?"
- "Show me the compliant way to do this"

**False positives?**
- "Is line 42 really a violation of rule #X?"
- "This pattern is required by [framework] - is it acceptable?"

---

## 🔗 Related Resources

- **Full Standards**: [code-review-ABL-standards.md](../instructions/abl/code-review-ABL-standards.md)
- **General Guidelines**: [general-abl-instructions.md](../instructions/abl/general-abl-instructions.md)
- **Global Standards**: [global-instructions.md](../instructions/global-instructions.md)


