# Local Testing

OpenEdgeLoadSuite is a comprehensive ABLUnit-based load and stress testing suite for Progress OpenEdge ABL. Its purpose is to measure and validate the performance and correctness of core OpenEdge ABL language constructs by exercising them across three programming paradigms:

- **Classes** - object-oriented style using `CLASS` definitions
- **Functions** - internal functions defined within `.p` procedure files
- **Procedures** - traditional internal `PROCEDURE` blocks within `.p` files

The suite covers four functional domains:

| Domain | Description |
|---|---|
| **Math** | Arithmetic operations (add, subtract, multiply, divide, modulo, power) for `DECIMAL` (float), `INTEGER`, and `INT64` (long) types |
| **Record** | CRUD operations (create, read, update, delete) against the `thrasher` Progress database |
| **String** | String manipulation operations for both long and short string scenarios |
| **TempTable** | Static and dynamic temp-table creation, population, and querying |

Test coverage is validated via ABLUnit. The suite is built and executed using Gradle with the Progress OpenEdge ABL Gradle plugin.

> NOTICE: This document covers the "legacy" testing process for direct execution using a ChUI (CLI) for the included logic. The goal was to reveal differences between OpenEdge installations by testing low-level operations. This needs a potential re-work to adjust the processes and ensure parity with the new API-driven implementation for PASOE instances.

Please refer to the PASOE instructions noted in the main README.md file for PASOE deployment and testing practices. The following is the process for executing the tests locally using a ChUI client. This process has not yet been adapted since migrating toward support for PASOE.

## Legacy Instructions

There are two test targets intended for end users:

| Target | Command | Output | Duration |
|---|---|---|---|
| Language (no DB) | `.\gradlew testLang` | `resultsLang.html` | ~2 minutes |
| Database | `.\gradlew testDB` | `resultsDB.html` | 1+ hour |

**Language test** - exercises math, string, and temp-table operations with no database required:

```powershell
.\gradlew testLang
```

Results are written to `resultsLang.html` in the project root.

**Database test** - exercises all record CRUD operations against the `thrasher` database. This is a long-running suite; plan accordingly:

```powershell
.\gradlew testDB
```

Results are written to `resultsDB.html` in the project root.

## Repository Structure

```text
src/
├── main/
│   ├── abl/
│   │   ├── Class/
│   │   │   └── com/progress/          # OOP class implementations
│   │   │       ├── math/              #   float, integer, long
│   │   │       ├── record/            #   create, delete, read, update
│   │   │       ├── string/            #   long, short
│   │   │       └── temptable/
│   │   ├── Function/
│   │   │   ├── math/                  # Internal-function implementations
│   │   │   │   ├── float/
│   │   │   │   ├── integer/
│   │   │   │   └── long/
│   │   │   ├── record/
│   │   │   │   ├── create/
│   │   │   │   ├── delete/
│   │   │   │   ├── read/
│   │   │   │   └── update/
│   │   │   ├── string/
│   │   │   │   ├── long/
│   │   │   │   └── short/
│   │   │   └── temptable/
│   │   ├── Procedure/                 # Internal-procedure implementations
│   │   │   └── (same structure as Function/)
│   │   └── Common/                    # Shared includes and temp-table definitions
│   │       ├── include/
│   │       └── tt/
│   └── resources/
│       └── schema/                    # thrasher .df and .st files
└── test/
    └── abl/
        └── OpenEdge/
            ├── StressConfig.cls       # Base configuration for stress tests
            ├── SuiteManager.cls       # Top-level ABLUnit suite entry point
            ├── Class/                 # ABLUnit tests targeting Class implementations
            ├── Function/              # ABLUnit tests targeting Function implementations
            └── Procedure/             # ABLUnit tests targeting Procedure implementations
```

## Test Architecture

The test suite is organized into ABLUnit test classes and procedures. The top-level entry point is `OpenEdge.SuiteManager`, which aggregates all sub-suites:

- `OpenEdge.Class.SuiteMathGeneral` - math class tests
- `OpenEdge.Class.SuiteStringGeneral` - string class tests
- `OpenEdge.Class.TestTempTableGeneral` - temp-table class tests
- `OpenEdge.Class.StressGeneral` - stress/load tests for classes
- `Function/SuiteMathGeneral.p` - math function tests
- `Procedure/SuiteMathGeneral.p` - math procedure tests
- `Procedure/SuiteStringGeneral.p` - string procedure tests
