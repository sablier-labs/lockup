# Security

This document outlines security considerations, assumptions, and known limitations for the Sablier Bob protocol.

## Bug Bounty

See the main repository [SECURITY.md](../SECURITY.md) for bug bounty details.

## Protocol Assumptions - Sablier Bob

### 1. Trusted Oracles

Vault creators choose their own oracles and bear full responsibility for oracle selection. The protocol intentionally
does not validate oracle staleness or the accuracy of the value returned. Depositors should verify the oracle address
and its reliability before depositing into any vault.

### 2. Supported Tokens

The protocol does not support fee-on-transfer, rebasing, or other non-standard tokens.

### 3. Curve Pool Slippage and Liquidity

The Lido adapter relies on the Curve stETH/ETH pool for converting stETH back to ETH. This has important implications:

- **Grace period exits may receive less than deposited**: When exiting during the grace period from a
  vault with an adapter, the wstETH→stETH→ETH→WETH conversion involves Curve swap slippage. Users may receive slightly
  less than their original deposit.
- **Extreme market conditions**: In extreme market conditions, unstaking may fail due to excessive slippage or
  insufficient liquidity.
