# Sablier Airdrops

Merkle-based token distribution with optional vesting via Lockup streams.

@../CLAUDE.md

## Protocol Overview

Distribute ERC-20 tokens using Merkle trees. Three distribution modes:

- **Instant**: Recipients claim tokens immediately
- **Vesting**: Claims create Lockup streams for gradual vesting
- **VCA (Variable Claim Amount)**: Linear unlock; unvested tokens forfeited on claim

Campaign timing options:

- **Absolute**: Vesting starts at fixed timestamp for all
- **Relative**: Vesting starts when each user claims

## Package Structure

```
src/
├── SablierMerkleFactory.sol    # Factory for campaigns
├── SablierMerkleInstant.sol    # Instant distribution
├── SablierMerkleLT.sol         # Lockup Tranched vesting
├── SablierMerkleVCA.sol        # Variable claim amount
├── interfaces/                  # Campaign interfaces
└── types/                       # Structs, enums
tests/
├── integration/
│   ├── concrete/               # BTT-based tests
│   └── fuzz/                   # Fuzz tests
└── fork/                       # Fork tests
scripts/
└── solidity/                   # Deployment scripts
```

## Commands

```bash
just airdrops::build         # Build
just airdrops::test          # Run tests
just airdrops::test-lite     # Fast tests (no optimizer)
just airdrops::coverage      # Coverage report
just airdrops::full-check    # All checks
```

## Key Concepts

- **Merkle root**: Hash of all eligible recipients and amounts
- **Campaign**: Deployed airdrop contract with fixed parameters
- **Claim**: User proves eligibility via Merkle proof
- **Expiration**: Optional deadline after which admin can claw back

## Import Path

```solidity
import { ISablierMerkleFactory } from "@sablier/airdrops/src/interfaces/ISablierMerkleFactory.sol";
```
