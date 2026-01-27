# Sablier Bob

Price-gated vault protocol for conditional token releases with optional yield generation.

@../CLAUDE.md

## Protocol Overview

Bob enables depositing ERC-20 tokens into vaults that release based on price conditions. Key features:

- **Price-gated vaults**: Tokens locked until target price reached or expiry
- **Oracle integration**: Chainlink-compatible price feeds (must return 8 decimals)
- **Yield adapters**: Optional Lido integration for staking rewards (wstETH)
- **Grace period**: 4-hour window for depositors to exit after deposit

Uses singleton architecture - all vaults managed in `SablierBob` contract.

## Package Structure

```
src/
├── SablierBob.sol          # Main contract
├── SablierLidoAdapter.sol   # Lido yield adapter
├── BobVaultShare.sol       # Vault share ERC20
├── abstracts/              # SablierBobState
├── interfaces/             # ISablierBob, ISablierLidoAdapter
├── libraries/              # Errors, Helpers
└── types/                  # Structs, enums
tests/
├── integration/
│   └── concrete/           # BTT-based tests
└── mocks/                  # MockOracle, MockAdapter
```

## Commands

```bash
just build bob              # Build
just test bob               # Run tests
just test-lite bob          # Fast tests (no optimizer)
just coverage bob           # Coverage report
just full-check bob         # All checks
```

## Key Concepts

- **Vault ID**: Unique identifier for each vault (starts from 1)
- **Share Token**: ERC-20 minted on deposit (1:1 with deposited tokens)
- **Grace Period**: 4 hours to exit after deposit without settlement
- **Settlement**: When price target is met or vault expires
- **Adapter**: Optional yield strategy (e.g., Lido for WETH)
- **Vault States**: ACTIVE (open for deposits), SETTLED (target reached or expired)

## Import Path

```solidity
import { ISablierBob } from "@sablier/bob/src/interfaces/ISablierBob.sol";
```
