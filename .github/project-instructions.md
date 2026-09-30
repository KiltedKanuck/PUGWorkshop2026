# Project Instructions

## Project Overview
This is an **OpenEdge ABL (Advanced Business Language)** project maintained by Progress Software. The project uses a Gradle build system with a structured directory layout optimized for ABL development with integrated AI-powered documentation and code analysis capabilities.

**Purpose**: A comprehensive load and performance test suite designed for baseline testing of OpenEdge installations. This suite helps establish performance benchmarks when migrating between OpenEdge versions or tuning system configurations.

**Test Coverage**: The project provides three implementation patterns (Classes, Functions, and Procedures) to test:
- Math Operations (INTEGER, INT64, and DECIMAL arithmetic)
- String Manipulation (Short and long character string operations)
- Database Operations (CRUD operations on Thrasher database tables)
- Temp-Table Operations (Static and dynamic temp-table creation and manipulation)
- Stress Testing (High-volume operation testing for performance validation)

## Architecture & Structure

### Directory Layout
```
src/
├── main/
│   ├── abl/
│   └── resources/          # Application resources
└── test/
    ├── abl/
    └── resources/          # Test-specific resources
```

**Critical**: Maintain strict separation between application code (`src/main/abl`) and test code (`src/test/abl`). Keep all non-code resources in their respective `resources/` folders.

## GitHub Copilot Workflow

When working with GitHub Copilot on this project:

### Discuss Before Implementing
- Copilot will always discuss problems and propose solutions **before** making any code changes
- Multiple approaches will be presented with trade-offs explained
- This applies to all modifications, whether small fixes or larger refactors

### Clear Recommendations & Context
- Recommendations will include fenced code blocks showing proposed changes
- Direct file references will be provided with line numbers: `[src/main/abl/file.cls](src/main/abl/file.cls#L123)`
- Before/after comparisons will be shown with surrounding context
- Rationale for each change will be documented

### Explicit Confirmation Required
- Copilot will wait for your explicit confirmation before implementing any code changes
- Approval keywords: "go ahead", "implement this", "do it", "yes", or similar clear affirmation
- Once approved, Copilot will execute changes with full confidence
- During discussion phase, use "discuss more", "other options", or questions to continue the conversation without triggering implementation

