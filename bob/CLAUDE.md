# Sablier Bob and Escrow

@../CLAUDE.md

This package contains the following protocols:

## Sablier Bob

Price-gated vault protocol for conditional token releases with optional yield generation.

### Protocol Overview

Bob enables depositing ERC-20 tokens into vaults that release based on price conditions. Key features:

- **Price-gated vaults**: Tokens locked until target price reached or expiry
- **Oracle integration**: Chainlink-compatible price feeds
- **Yield adapters**: Optional integrations for staking of deposited tokens

Uses singleton architecture - all vaults managed in `SablierBob` contract.

## Key Concepts

- **Vault ID**: Unique identifier for each vault
- **Share Token**: ERC-20 minted on deposit (1:1 with deposited tokens)
- **Grace Period**: To exit after deposit without settlement
- **Settlement**: When price target is met or vault expiry is reached
- **Adapter**: Optional yield strategy for staking of deposited tokens

## Sablier Escrow

Over-the-counter (OTC) token swap protocol that allows users to swap ERC-20 tokens with each other.

## Key Concepts

- **Order ID**: Unique identifier for each order
- **Seller**: The address that created the order and deposited the sell token
- **Buyer**: The address that filled the order
- **Sell Token**: The ERC-20 token being sold, deposited by the seller when the order is created
- **Buy Token**: The ERC-20 token the seller wants to receive
- **Sell Amount**: The amount of sell token that the seller is willing to exchange
- **Min Buy Amount**: The minimum amount of buy token that the seller is willing to accept
- **Expire At**: The Unix timestamp when the order expires

## Commands

```bash
just build              # Build
just full-check         # All checks
just test               # Run tests
just test-bulloak       # Verify BTT structure
just coverage           # Coverage report
```
