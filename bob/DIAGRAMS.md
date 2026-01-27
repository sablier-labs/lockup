# Bob Architecture Diagrams

High-level architectural overview of the SablierBob protocol.

## Contract Architecture

```
                                    ┌─────────────────────┐
                                    │  SablierComptroller │
                                    │  (fee management)   │
                                    └──────────┬──────────┘
                                               │
                              fee queries + admin configuration
                                               │
                                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              SablierBob                                      │
│                                                                              │
│  Central contract managing price-target vaults                               │
│  • Creates and tracks vaults                                                 │
│  • Coordinates deposits and redemptions                                      │
│  • Routes to adapter when yield-bearing                                      │
└─────────────────────────────────────────────────────────────────────────────-┘
         │                    │                     │
         │                    │                     │
    yield-bearing        share token           non-adapter
    vault actions        management            token custody
         │                    │                     │
         ▼                    ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ SablierBob-     │  │ BobVaultShare   │  │ Deposit Tokens  │
│ Adapter         │  │ (per vault)     │  │ (ERC20)         │
│                 │  │                 │  │                 │
│ Stakes tokens   │  │ ERC20 shares    │  │ Held directly   │
│ for yield       │  │ representing    │  │ by SablierBob   │
│ (e.g. Lido)     │  │ vault deposits  │  │ for non-adapter │
└─────────────────┘  └─────────────────┘  │ vaults          │
         │                    │           └─────────────────┘
         │           notifies on transfer
         │                    │
         └────────────────────┘
              wstETH attribution sync
```

## Vault Lifecycle

```
                              ┌─────────────┐
                              │   CREATE    │
                              │   VAULT     │
                              └──────┬──────┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                                ACTIVE                                        │
│                                                                              │
│  • Users can deposit tokens and receive shares                               │
│  • Users can exit within grace period (refund)                               │
│  • Price can be synced from oracle                                           │
│                                                                              │
│  Transitions to SETTLED when:                                                │
│  • Price reaches target (via sync)                                           │
│  • Expiry time passes                                                        │
└───────────────────────────────────────────────────────────────────────────---┘
                                     │
           ┌─────────────────────────┴─────────────────────────┐
           │                                                   │
           ▼                                                   ▼
    ┌──────────────┐                                 ┌──────────────┐
    │ Price Target │                                 │    Expiry    │
    │   Reached    │                                 │    Passed    │
    └──────┬───────┘                                 └──────┬───────┘
           │                                                │
           └───────────────────┬────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                               SETTLED                                        │
│                                                                              │
│  • Deposits blocked                                                          │
│  • Users can redeem shares for tokens                                        │
│  • For adapter vaults: unstaking converts yield tokens to deposit tokens     │
│  • Grace period exits still allowed (if within window)                       │
└──────────────────────────────────────────────────────────────────────────────┘
```

## User Flows

```
                              USER INTERACTIONS
                              ═════════════════

    ┌─────────┐
    │  USER   │
    └────┬────┘
         │
         ├─────────── DEPOSIT ──────────────────────────────────────────┐
         │                                                              │
         │            ┌────────────────┐                                │
         │            │  SablierBob    │                                │
         │            │                │                                │
         │            │  Receives      │──── With Adapter ────┐         │
         │            │  tokens,       │                      │         │
         │            │  mints shares  │                      ▼         │
         │            └───────┬────────┘              ┌──────────────┐  │
         │                    │                       │   Adapter    │  │
         │                    │                       │              │  │
         │                    │                       │ Stakes for   │  │
         │                    ▼                       │ yield        │  │
         │            ┌──────────────┐                └──────────────┘  │
         │            │ BobVaultShare│                                  │
         │            │ minted to    │                                  │
         │            │ user         │                                  │
         │            └──────────────┘                                  │
         │                                                              │
         ├─────────── GRACE PERIOD EXIT ────────────────────────────────┤
         │                                                              │
         │            ┌────────────────┐                                │
         │            │  SablierBob    │                                │
         │            │                │                                │
         │            │  Within 4 hrs  │──── With Adapter ────┐         │
         │            │  of deposit    │                      │         │
         │            │                │                      ▼         │
         │            │  Burns shares, │              ┌──────────────┐  │
         │            │  returns       │              │   Adapter    │  │
         │            │  tokens        │◄─────────────│              │  │
         │            │                │  unstakes    │ Unstakes     │  │
         │            │  NO FEE        │  user's      │ user portion │  │
         │            └────────────────┘  portion     └──────────────┘  │
         │                                                              │
         ├─────────── REDEEM (after settlement) ────────────────────────┤
         │                                                              │
         │            ┌────────────────┐                                │
         │            │  SablierBob    │                                │
         │            │                │                                │
         │      ┌─────│  Burns shares, │─────┐                          │
         │      │     │  returns       │     │                          │
         │      │     │  tokens        │     │                          │
         │      │     └────────────────┘     │                          │
         │      │                            │                          │
         │      ▼                            ▼                          │
         │  ┌──────────────┐         ┌──────────────┐                   │
         │  │ No Adapter   │         │ With Adapter │                   │
         │  │              │         │              │                   │
         │  │ Native fee   │         │ Yield fee    │                   │
         │  │ paid by user │         │ taken from   │                   │
         │  │ on redeem    │         │ staking      │                   │
         │  │              │         │ rewards      │                   │
         │  └──────────────┘         └──────────────┘                   │
         │                                                              │
         └─────────── SYNC PRICE ───────────────────────────────────────┘

                      ┌────────────────┐
           Anyone ───►│  SablierBob    │
                      │                │
                      │  Queries       │───────────► Oracle
                      │  oracle,       │◄───────────
                      │  updates       │  price data
                      │  vault price   │
                      └────────────────┘
```

## Adapter Flow (Yield-Bearing Vaults)

```
                           ADAPTER INTEGRATION
                           ════════════════════

    The adapter enables yield generation on deposited tokens.
    Currently implemented: Lido (WETH → wstETH)

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                           ON DEPOSIT                                    │
    │                                                                         │
    │    Deposit Token ───► Yield Token ───► Held by Adapter                  │
    │    (e.g. WETH)        (e.g. wstETH)    (tracks per-user attribution)    │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                       ON SHARE TRANSFER                                 │
    │                                                                         │
    │    Share token notifies SablierBob                                      │
    │    SablierBob notifies Adapter                                          │
    │    Adapter moves yield attribution proportionally                       │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                      ON SETTLEMENT (unstake)                            │
    │                                                                         │
    │    Yield Token ───► Deposit Token ───► Held by SablierBob               │
    │    (all at once)    (e.g. wstETH → WETH via DEX)                        │
    │                                                                         │
    │    Total includes principal + accrued yield                             │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                           ON REDEEM                                     │
    │                                                                         │
    │    User receives: proportional share of total                           │
    │    Yield fee: percentage of positive yield (capped at 20%)              │
    │    Fee is snapshotted at vault creation (immune to later changes)       │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
```

## Fee Model

```
                              FEE STRUCTURE
                              ═════════════

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                      NON-ADAPTER VAULTS                                 │
    │                                                                         │
    │    Fee paid in native token (ETH) at redemption time                    │
    │    Set via Comptroller (per-protocol fee)                               │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                       ADAPTER VAULTS                                    │
    │                                                                         │
    │    No native fee at redemption                                          │
    │    Yield fee: percentage of positive staking rewards                    │
    │    • Capped at 20% maximum                                              │
    │    • Snapshotted when vault is created                                  │
    │    • Sent to comptroller                                                │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                      GRACE PERIOD EXIT                                  │
    │                                                                         │
    │    No fee charged (full refund within 4 hours of deposit)               │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
```
