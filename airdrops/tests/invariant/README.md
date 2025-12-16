### List of Invariants

#### For all campaigns:

1. token.balanceOf(campaign) = total deposit - $\sum$ claimed - $\sum$ clawbacked
2. `hasClaimed` should never change its value from `true` to `false`

#### For VCA campaign:

1. total forgone = $\sum$ claim requested - $\sum$ claimed
2. If redistribution is enabled, redistribution rewards per token should never decrease.
3. If redistribution is enabled and vesting has ended, redistribution rewards per token should never change.
