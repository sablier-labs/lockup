# Security

This document outlines security considerations, assumptions, and known limitations for the Sablier Bob protocol.

## Bug Bounty

See the main repository [SECURITY.md](../SECURITY.md) for bug bounty details.

## Bob Protocol Assumptions

The following assumptions are made by design and should not be reported as security issues:

### 1. Trusted Oracles

Oracles provided by vault creators are assumed to be trusted and reliable. The protocol intentionally does not validate
oracle staleness, `answeredInRound`, or other freshness checks. This is by design:

- Vault creators choose their own oracles and bear full responsibility for oracle selection
- Users depositing into a vault implicitly trust the oracle chosen by the vault creator
- Different assets/chains have different acceptable staleness thresholds (seconds on L2s vs hours on L1)
- The protocol is permissionless - hardcoding staleness checks would be either too restrictive or provide false security
- Settlement is based on price targets, not time-sensitive arbitrage, reducing staleness impact
- Depositors should verify the oracle address and its reliability before depositing

### 2. Trusted Adapters

Adapters are set by the comptroller (protocol admin) and are assumed to be trusted contracts. The protocol does not
protect against malicious adapters.

### 3. ERC-20 Compliance

Tokens used in vaults are assumed to be standard ERC-20 tokens. Fee-on-transfer, rebasing, or other non-standard tokens
may not work correctly.

### 4. Curve Pool Slippage and Liquidity

The Lido adapter relies on the Curve stETH/ETH pool for converting stETH back to ETH. This has important implications:

- **Grace period exits may receive less than deposited**: When exiting during the grace period from an adapter-enabled
  vault, the wstETH→stETH→ETH→WETH conversion involves Curve swap slippage. Users may receive slightly less than their
  original deposit (typically 0.1-0.5% depending on pool conditions). The grace period protects against vault settlement
  risk, not exchange rate fluctuations.
- **Extreme market conditions**: During stETH depeg events, swaps may fail due to excessive slippage or insufficient
  liquidity. This is an accepted dependency on external protocol availability.
- Users should understand that adapter vaults involve DeFi composability risks inherent to liquid staking and DEX swaps.

### 5. Permissionless Sync

The `sync()` function is intentionally callable by anyone on any vault. This enables trustless settlement without
reliance on vault creators. While this means deposits could be front-run by a `sync()` call that settles the vault, this
is by design - the deposit simply reverts with no financial loss to the user. The vault would have settled anyway once
anyone called `sync()`. Restricting sync callers would create centralization risk where vault creators could refuse to
settle.

### 6. Token Supply Below uint128

The protocol assumes token total supplies do not exceed `type(uint128).max`. This is consistent with Sablier Lockup and
Flow. Amounts use `uint128` for gas efficiency. Since share token total supply cannot exceed the underlying token's
total supply, overflow is impossible under this assumption.

### 7. wstETH Exchange Rate Variability

When users deposit at different times, they receive different amounts of wstETH per WETH due to Lido's appreciating
exchange rate. This is expected liquid staking behavior:

- Early depositors get more wstETH (rate was lower)
- Later depositors get less wstETH (rate appreciated)
- Yield is distributed proportionally to wstETH holdings
- This correctly rewards users based on their time-weighted stake duration

This is not a vulnerability - it's how staking rewards naturally accrue over time.

### 8. Share Transfer wstETH Attribution

When share tokens are transferred between users, wstETH attribution moves proportionally based on the sender's current
share balance. This proportional mechanism is correct and consistent:

- Transferring X% of shares transfers X% of wstETH attribution
- Multiple deposits and transfers result in mathematically correct attribution
- At redemption, each user receives their fair share based on wstETH holdings

### External Dependencies

| Contract             | Address (Mainnet)                            | Risk                   |
| -------------------- | -------------------------------------------- | ---------------------- |
| Lido stETH           | `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84` | Staking protocol risk  |
| Lido wstETH          | `0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0` | Wrapper contract risk  |
| Curve stETH/ETH Pool | `0xDC24316b9AE028F1497c275EB9192a3Ea0f67022` | DEX liquidity/slippage |
| Chainlink Oracles    | Various                                      | Oracle reliability     |
| WETH9                | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` | Canonical wrapped ETH  |

## Escrow Protocol Assumptions

Sablier Escrow has been developed with the following additional assumptions:

- Fee-on-transfer tokens are explicitly NOT supported. The contract records the `sellAmount` specified by the seller
  without measuring the actual tokens received. If a fee-on-transfer token is used, the contract will hold fewer tokens
  than recorded, which could cause order acceptance to fail or drain tokens from other orders using the same token.
  This is documented in the NatSpec but not enforced on-chain.
