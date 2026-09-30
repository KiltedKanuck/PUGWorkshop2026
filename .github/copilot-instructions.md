# GitHub Copilot Instructions

## Overview

These instructions define GitHub Copilot's behavior when generating and reviewing code across different programming languages. All generated code must adhere to the coding standards defined in the referenced documentation files.

## Non-Negotiable Approval Gate

- Never modify any workspace file unless the user explicitly asks to implement changes in the current turn.
- Analysis, issue identification, and proposed diffs are allowed without implementation approval.
- A previous turn that involved edits does not grant permission for new edits in later turns.
- If approval is missing or ambiguous, stop and ask a direct yes/no implementation question.
- Refactors, cleanups, or opportunistic improvements always require explicit approval, even when related to the current topic.

## Default Execution Mode: Strict Scope

Unless the user explicitly requests refactoring, optimization, cleanup, or modernization, use strict scope mode.

In strict scope mode:
- Edit only the file(s) and symbol(s) explicitly requested.
- Make the smallest possible diff to satisfy the request.
- Do not refactor, rename, reformat, reorder, or improve unrelated code.
- Do not add new patterns unless explicitly requested.
- Do not change comments/messages/headers unless explicitly requested.
- If an additional or follow-on change seems necessary, stop and ask first.
- If the user did not explicitly request implementation in the current turn, do not edit.

**For all code changes**: Follow the Problem-Solving Protocol below, which requires discussion and explicit confirmation before implementation.

Definition of done:
- Requested change is present.
- No unrelated edits were made.

---

## Language-Specific Standards

### C Programming Standards
All C code must adhere to the coding standards defined in [general-c-instructions.md](instructions/c/general-c-instructions.md).

All C code reviews must adhere to the code review standards contained in [code-review-C-standards.md](instructions/c/code-review-C-standards.md).

### C++ Programming Standards
All C++ code must adhere to the coding standards defined in [general-cpp-instructions.md](instructions/cpp/general-cpp-instructions.md).

All C++ code reviews must adhere to the code review standards contained in [code-review-CPP-standards.md](instructions/cpp/code-review-CPP-standards.md).

### OpenEdge ABL Standards
All OpenEdge ABL code must adhere to the coding standards defined in [general-abl-instructions.md](instructions/abl/general-abl-instructions.md).

All OpenEdge ABL code reviews must adhere to the code review standards contained in [code-review-ABL-standards.md](instructions/abl/code-review-ABL-standards.md).

### Java Programming Standards
All Java code must adhere to the coding standards defined in [general-java-instructions.md](instructions/java/general-java-instructions.md).

All Java code reviews must adhere to the code review standards contained in [code-review-JAVA-standards.md](instructions/java/code-review-JAVA-standards.md).

### C# Programming Standards
All C# code must adhere to the coding standards defined in [general-csharp-instructions.md](instructions/csharp/general-csharp-instructions.md).

All C# code reviews must adhere to the code review standards contained in [code-review-CSHARP-standards.md](instructions/csharp/code-review-CSHARP-standards.md).

For additional references, see:
- Global settings: [global-instructions.md](instructions/global-instructions.md)
- Project-specific: [project-instructions.md](project-instructions.md)

---

## Author Information

When generating code that requires author information (such as copyright headers or file documentation):
- Retrieve the author name from git global config: `git config --global user.name`
- Retrieve the author email from git global config: `git config --global user.email`
- Use this information for copyright headers, file documentation, and other author-related metadata

---

## Universal Code Generation Principles

All code should follow the guidelines set forth in the book "Clean Code: A Handbook of Agile Software Craftsmanship" by Robert C. Martin.

### Standards Compliance
- Always follow language-specific coding standards
- Generate code that passes static analysis tools (Sonarqube, linters)
- Ensure all variable names, function names, and type definitions follow established conventions
- Maintain consistency with existing codebase patterns

### Code Quality Requirements
Before suggesting code, verify:
- Variable names are meaningful and follow language conventions
- Function names include proper prefixes/namespaces where required
- No obsolete or prohibited data types are used
- Memory management follows established patterns
- Code complexity is within acceptable limits
- No code duplication exists

---

## Documentation and Comments

### General Documentation
- Strictly follow JSDoc style comments for all documentation
- Add descriptive comments for complex logic
- Follow the standard function/method header format for all new functions
- Document parameters, return values, and any side effects
- Document the business purpose of programs, methods, procedures, and functions
- Include usage examples for complex functionality
- Keep comments up-to-date when code changes
- Include copyright headers with current year (2026) for new files

Refer to language and project-specific instructions for exact header formats.

---

## Testing and Quality Assurance

### Testing Standards
- Maintain comprehensive test coverage with parallel structure to main code
- Test both success and error scenarios
- Use meaningful test names that describe what is being tested

Refer to language and project-specific instructions for testing.

### Quality Checks
- Generate code that passes Sonarqube quality checks
- Ensure code complexity is within acceptable limits
- Verify no code duplication exists
- Check for proper error handling patterns
- Validate memory management practices

---

## Problem-Solving Protocol

When addressing user requests, follow this workflow:

### 1. Discuss First
- **Always** analyze the problem and potential solutions before making code changes
- Identify relevant files, methods, and context
- Propose multiple approaches if applicable
- Explain trade-offs and implications
- Do NOT implement code changes until user confirms

### 2. Make Clear Recommendations
- Use fenced code blocks to show concrete code examples or changes
- Reference specific files with line numbers using markdown links: `[file.cls](file.cls#L123)`
- Provide before/after comparisons when helpful
- Include code context (3-5 lines before/after changes) in recommendations
- Explain the rationale behind each recommended change

### 3. Confirm Implementation
- Wait for explicit user approval before executing code changes
- If user says "go ahead", "implement this", or "do it", then proceed with full confidence
- If user is exploring options or asking questions, continue the discussion
- Only after agreement is reached should code modifications happen
- If there is no explicit implementation approval in the current turn, make zero file edits
- If approval is ambiguous, ask one direct confirmation question and wait

### Example Workflow
```
User: "I need to add error logging to this handler"
You: Analyze current code → propose solution with code examples → reference specific files/lines
User: "Looks good, go ahead"
You: Implement the changes with confidence
```

---

## Interactive Assistance

- Answer questions about the coding standards
- Explain rationale behind specific conventions
- Provide examples of correct vs incorrect patterns
- Help debug issues related to standard violations
- Reference appropriate MCP servers for language-specific queries
