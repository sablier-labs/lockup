# Sablier EVM Utils

Shared utilities and comptroller contract used across all Sablier protocols.

@../CLAUDE.md

## Package Overview

Two main components:

### Comptroller

Standalone admin contract with:

- Fee management across all Sablier protocols
- Authority over admin functions
- Oracle integration for fee calculations

### Utility Contracts

Reusable base contracts:

- `Adminable`: Admin role management
- `Batch`: Batch transaction support
- `NoDelegateCall`: Prevent delegate calls

## Package Structure

```
src/
├── SablierComptroller.sol      # Fee and admin management
├── Adminable.sol               # Admin base contract
├── Batch.sol                   # Batch operations
├── NoDelegateCall.sol          # Security modifier
├── interfaces/                 # Public interfaces
├── mocks/                      # Test mocks
└── tests/                      # Test helpers
tests/
├── integration/
│   ├── concrete/               # BTT-based tests
│   └── fuzz/                   # Fuzz tests
scripts/
└── solidity/                   # Deployment scripts
```

## Commands

```bash
just utils::build            # Build
just utils::test             # Run tests
just utils::test-lite        # Fast tests (no optimizer)
just utils::coverage         # Coverage report
just utils::full-check       # All checks
```

## Import Paths

```solidity
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";
```
