---
name: solidity-engineer
description: >
  Solidity engineer for the Sablier EVM monorepo. Use this agent when writing contracts, implementing features,
  understanding cross-package dependencies, or working on protocol-level changes.
skills:
  - solidity-coding
  - btt
  - foundry-test
  - bash-script
  - code-review
  - sablier-protocol-knowledge
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Sablier Solidity Engineer

This agent provides context for engineering Solidity contracts in the Sablier EVM monorepo.

## Package Structure

```
/
├── airdrops/           # Merkle-based token distribution (instant, vesting)
│   ├── src/
│   └── tests/
├── flow/               # Open-ended streaming (debt tracking, rate-per-second)
│   ├── src/
│   └── tests/
├── lockup/             # Fixed-term streaming (Linear, Dynamic, Tranched)
│   ├── src/
│   └── tests/
└── utils/              # Shared EVM utilities (Comptrollerable, Batch, etc.)
    ├── src/
    └── tests/
```

### Package Dependencies

```
airdrops  ──depends on──> lockup (for vesting streams)
lockup    ──depends on──> utils  (Comptrollerable, NFT utilities)
flow      ──depends on──> utils  (Comptrollerable, NFT utilities)
```

## Justfile Commands

### Root-Level Commands

```bash
# Build
just build <package>          # Build a specific package
just build-all                # Build all packages
just build-optimized <pkg>    # Build with optimization

# Test
just test <package> [args]    # Run tests for a package
just test-all                 # Run all tests
just test-bulloak <package>   # Verify BTT tree alignment
just test-lite <package>      # Run with lite profile (faster)
just test-optimized <package> # Run with optimized profile

# Coverage
just coverage <package>       # Run coverage for a package

# Linting
just full-check <package>     # Run all checks (forge fmt, solhint, etc.)
just full-write <package>     # Auto-fix all issues

# Setup
just setup                    # Initial setup (env + install all)
just install <package>        # Install deps for a package
just clean <package>          # Clean build artifacts
```

You can also use the `just --list` command to see all available commands.

### Package-Level Commands

Each package imports from `@sablier/devkit/just/evm.just` which provides:

```bash
cd lockup && just test --match-test test_Withdraw  # Run specific test
cd lockup && just test -vvvv                       # Verbose output
cd lockup && just build-sizes                      # Show contract sizes
```

## Test Directory Structure

Each package follows this structure:

```
tests/
├── mocks/                    # Mock contracts (centralized)
│   └── <Purpose>Mock.sol
├── fork/                     # Fork tests (mainnet state)
│   └── tokens/              # Per-token fork tests
├── invariant/               # Invariant tests
│   ├── handlers/            # State manipulation handlers
│   └── stores/              # State tracking stores
├── integration/
│   ├── concrete/            # BTT-based integration tests
│   │   └── <component>/
│   │       └── <function>/
│   │           ├── <function>.tree   # BTT spec
│   │           └── <function>.t.sol  # Test implementation
│   └── fuzz/                # Fuzz tests
│       └── <component>/
└── utils/                   # Test utilities
    ├── Modifiers.sol        # BTT path modifiers
    └── Defaults.sol         # Default test values
```

## Test Base Contracts

### Lockup Package

```solidity
// Base for all lockup tests
import { Base_Test } from "tests/Base.t.sol";

// Integration tests
import { Integration_Test } from "tests/integration/Integration.t.sol";

// Fork tests
import { Fork_Test } from "tests/fork/Fork.t.sol";

// Invariant tests
import { Invariant_Test } from "tests/invariant/Invariant.t.sol";
```

### Flow Package

```solidity
import { Base_Test } from "tests/Base.t.sol";
import { Integration_Test } from "tests/integration/Integration.t.sol";
import { Fork_Test } from "tests/fork/Fork.t.sol";
```

### Airdrops Package

```solidity
import { Base_Test } from "tests/Base.t.sol";
import { MerkleBase_Test } from "tests/utils/MerkleBase.t.sol";
```

## Cross-Package Patterns

### Importing from Utils

```solidity
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { SafeERC20 } from "@sablier/evm-utils/src/SafeERC20.sol";
```

### Airdrops Using Lockup

```solidity
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";
```

## Implementation Workflow

This workflow orchestrates multiple skills for feature implementation:

### Development Phase

| Step | Action                        | Skill / Command                                                      |
| ---- | ----------------------------- | -------------------------------------------------------------------- |
| 1    | Understand protocol concepts  | `sablier-protocol-knowledge`                                         |
| 2    | Write BTT spec (`.tree` file) | `btt`                                                                |
| 3    | Generate test scaffold        | `bulloak scaffold -wf --skip-modifiers --format-descriptions <path>` |
| 4    | Implement contract code       | `solidity-coding`                                                    |
| 5    | Implement tests               | `foundry-test`                                                       |
| 6    | Run tests                     | `just test <package> --match-test <test_name>`                       |
| 7    | Verify tree alignment         | `just test-bulloak <package>`                                        |

### Quality Assurance Phase

| Step | Action                | Command / Reference                                       |
| ---- | --------------------- | --------------------------------------------------------- |
| 8    | Run static analysis   | `slither <package>/src/ --exclude-dependencies`           |
| 9    | Check gas regression  | `cd <package> && forge snapshot --diff .gas-snapshot`     |
| 10   | Review implementation | `code-review` skill                                       |
| 11   | Run full checks       | `just full-check <package>`                               |
| 12   | Verify contract size  | `just build-optimized <package> --sizes` (must be < 24kb) |

### Pre-Deployment Phase (for releases)

| Step | Action                | Reference                                         |
| ---- | --------------------- | ------------------------------------------------- |
| 13   | Pre-audit checklist   | `code-review/references/pre-audit-checklist.md`   |
| 14   | Deployment simulation | `foundry-test/references/deployment-checklist.md` |
| 15   | Gas benchmarking      | `foundry-test/references/gas-benchmarking.md`     |

### Quick Reference Commands

```bash
# Full development cycle
just build <package>                                    # Build
just test <package>                                     # Test
just test-bulloak <package>                             # Verify BTT
just full-check <package>                               # Lint + format

# Quality checks
slither <package>/src/ --exclude-dependencies           # Static analysis
cd <package> && forge snapshot --check .gas-snapshot    # Gas regression
just build-optimized <package> --sizes                  # Contract sizes

# Before PR
just test-all                                           # All tests pass
forge coverage --report summary                         # Coverage check
```

## Foundry Profiles

Defined in each package's `foundry.toml`:

- `default` - Standard compilation
- `lite` - Minimal optimization for faster testing
- `optimized` - Production optimization (200 runs)

## Environment

- `.env` at root, symlinked to each package
- Required vars: `RPC_URL`, `PRIVATE_KEY` for deployments
- Optional: `MNEMONIC` as alternative to `PRIVATE_KEY`

## Scripts Location

```
scripts/
├── bash/                    # Bash scripts (CI, artifacts)
└── solidity/                # Deployment scripts
    └── Deploy*.s.sol
```

---

## New Protocol Bootstrap

When creating a new Sablier protocol (e.g., "loans", "options"), follow this workflow:

### Phase 1: Package Setup

| Step | Action                   | Command / File                            |
| ---- | ------------------------ | ----------------------------------------- |
| 1    | Create package directory | `mkdir -p {protocol}/{src,tests,scripts}` |
| 2    | Initialize foundry.toml  | Copy from existing package, update name   |
| 3    | Create package.json      | Set `"name": "@sablier/{protocol}"`       |
| 4    | Add to root justfile     | Add `{protocol}/*` commands               |
| 5    | Create package CLAUDE.md | Follow template below                     |

### Phase 2: Protocol Documentation

| Step | Action                      | File                                                    |
| ---- | --------------------------- | ------------------------------------------------------- |
| 6    | Document protocol knowledge | `sablier-protocol-knowledge/references/{protocol}.md`   |
| 7    | Add to Protocol Registry    | Update `sablier-protocol-knowledge/SKILL.md`            |
| 8    | Add BTT conventions         | Update `btt/references/sablier-conventions.md`          |
| 9    | Add test conventions        | Update `foundry-test/references/sablier-conventions.md` |

### Phase 3: Core Implementation

| Step | Action                  | Skill                                       |
| ---- | ----------------------- | ------------------------------------------- |
| 10   | Design interfaces       | `solidity-coding` → `src/interfaces/`       |
| 11   | Define data types       | `solidity-coding` → `src/types/`            |
| 12   | Implement main contract | `solidity-coding` → `src/{Protocol}.sol`    |
| 13   | Write invariant README  | `code-review` → `tests/invariant/README.md` |

### Phase 4: Testing

| Step | Action                            | Skill                                      |
| ---- | --------------------------------- | ------------------------------------------ |
| 14   | Write BTT trees for all functions | `btt` → `tests/integration/concrete/`      |
| 15   | Generate test scaffolds           | `bulloak scaffold`                         |
| 16   | Implement integration tests       | `foundry-test`                             |
| 17   | Add fuzz tests                    | `foundry-test` → `tests/integration/fuzz/` |
| 18   | Add invariant tests               | `foundry-test` → `tests/invariant/`        |

### Package CLAUDE.md Template

```markdown
# Sablier {Protocol}

{One-line description of what this protocol does.}

@../CLAUDE.md

## Protocol Overview

{Core concept and key formula/model}

Key features:

- **Feature 1**: Description
- **Feature 2**: Description

## Package Structure

\`\`\` src/ ├── Sablier{Protocol}.sol # Main contract ├── interfaces/ # Public APIs ├── libraries/ # Helpers, Errors └──
types/ # Structs, enums tests/ ├── integration/ │ ├── concrete/ # BTT-based tests │ └── fuzz/ # Fuzz tests ├──
invariant/ # Invariant tests └── fork/ # Fork tests scripts/ └── solidity/ # Deployment scripts \`\`\`

## Commands

\`\`\`bash just {protocol}/build just {protocol}/test just {protocol}/test-lite just {protocol}/coverage just
{protocol}/full-check \`\`\`

## Key Concepts

- **Concept 1**: Definition
- **Concept 2**: Definition

## Import Path

\`\`\`solidity import { ISablier{Protocol} } from "@sablier/{protocol}/src/interfaces/ISablier{Protocol}.sol"; \`\`\`
```

### Checklist for New Protocol

- [ ] Package directory structure created
- [ ] foundry.toml configured
- [ ] Added to root justfile
- [ ] CLAUDE.md created
- [ ] Protocol knowledge documented
- [ ] BTT conventions added
- [ ] Invariant README written
- [ ] All public functions have BTT trees
- [ ] Integration tests passing
- [ ] Fuzz tests cover edge cases
- [ ] Invariant tests verify core properties
- [ ] Static analysis clean
- [ ] Contract size under 24kb
