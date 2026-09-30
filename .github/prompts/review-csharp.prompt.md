# C# Pre-Commit Code Review

## How to Use

**Quick Method (Recommended):**
1. **Type the snippet prefix** in VS Code: `review-csharp`
2. **Press Tab** to expand the full prompt into Copilot Chat
3. **Submit** and review the results

**Alternative Method:**
1. **Open your changed C# files** in VS Code
2. **Open GitHub Copilot Chat** (Ctrl+Alt+I or Cmd+Alt+I)
3. **Find the prompt** in this file or code snippets
4. **Paste** into Copilot Chat and submit
5. **Fix issues** and commit with confidence

---

## The Prompt 

**⚠️ MOST IMPORTANT: Comprehensive Industry Best Practices First**

When reviewing code, prioritize industry best practices and established software engineering principles alongside the specific rules defined in this document. The rules below complement, not replace, fundamental coding standards such as:
- correct implementation and usage of `IDisposable` and resource cleanup patterns
- SOLID principles
- Clean Code principles (readability, maintainability, simplicity)
- DRY (Don't Repeat Yourself)
- Security by design
- Performance and efficiency
- Error handling and resilience

The full prompt checks ALL 8 categories:
- Naming Conventions (MANDATORY)
- Asynchronous Programming (CRITICAL)
- Exception Handling (CRITICAL)
- Resource Management (CRITICAL)
- Class & Method Design (MAJOR)
- Security (CRITICAL)
- Performance (MAJOR)
- Testing (MANDATORY)


---

## 💡 Quick Tips

**For focused reviews**, you can add specific instructions:
- "Focus on async/await usage only"
- "Check for proper IDisposable patterns"
- "Review for LINQ performance issues"
- "Verify null safety handling"

**For learning**, ask:
- "Explain why async void is bad with examples"
- "Show me proper using statement patterns"
- "What are the common pitfalls with Task.Run here?"

**False positives?**
- "Is line 42 really a violation?"
- "This pattern is required by [framework] - is it acceptable?"

---

## 🔗 Related Resources

- **Full Standards**: [code-review-CSHARP-standards.md](../instructions/csharp/code-review-CSHARP-standards.md)
- **General Guidelines**: [general-csharp-instructions.md](../instructions/csharp/general-csharp-instructions.md)
- **Global Standards**: [instructions/global-instructions.md](../instructions/global-instructions.md)

---

**Pro Tip**: Use the `review-csharp` snippet prefix in VS Code for instant access to the full prompt!
