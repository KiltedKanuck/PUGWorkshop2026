# Java Pre-Commit Code Review

## How to Use

**Quick Method (Recommended):**
1. **Type the snippet prefix** in VS Code: `review-java`
2. **Press Tab** to expand the full prompt into Copilot Chat
3. **Submit** and review the results

**Alternative Method:**
1. **Open your changed Java files** in VS Code
2. **Open GitHub Copilot Chat** (Ctrl+Alt+I or Cmd+Alt+I)
3. **Find the prompt** in this file or code snippets
4. **Paste** into Copilot Chat and submit
5. **Fix issues** and commit with confidence

---

## The Prompt 

**⚠️ MOST IMPORTANT: Industry Best Practices First**

When reviewing code, prioritize industry best practices and established software engineering principles alongside the specific rules defined in this document. The rules below complement, not replace, fundamental coding standards such as:
- proper resource management and memory-leak avoidance (e.g., try-with-resources, closing streams, managing listeners/callbacks and object lifecycles)
- SOLID principles
- Clean Code principles (readability, maintainability, simplicity)
- DRY (Don't Repeat Yourself)
- Security by design
- Performance and efficiency
- Error handling and resilience

The full prompt checks ALL 10 categories:
- Naming Conventions (MANDATORY)
- Code Formatting (MANDATORY)
- Class Design (CRITICAL)
- Method Design (MAJOR)
- Exception Handling (CRITICAL)
- Concurrency (CRITICAL)
- Performance (MAJOR)
- Security (CRITICAL)
- Testing (MANDATORY)
- Clean Code Principles (MANDATORY)

---

## 💡 Quick Tips

**For focused reviews**, you can add specific instructions:
- "Focus on security issues only"
- "Check exception handling patterns"
- "Review for SOLID principles violations"
- "Verify thread safety and concurrency"

**For learning**, ask:
- "Explain why returning null is bad with examples"
- "Show me proper Optional usage patterns"
- "What are the SOLID principles violations here?"

**False positives?**
- "Is line 42 really a violation?"
- "This pattern is required by [framework] - is it acceptable?"

---

## 🔗 Related Resources

- **Full Standards**: [code-review-JAVA-standards.md](../instructions/java/code-review-JAVA-standards.md)
- **General Guidelines**: [general-java-instructions.md](../instructions/java/general-java-instructions.md)
- **Global Standards**: [../global-instructions.md](../instructions/global-instructions.md)

---

**Pro Tip**: Use the `review-java` snippet prefix in VS Code for instant access to the full prompt!
