### List of Invariants

#### For all campaigns:

1. token.balanceOf(campaign) = total deposit - $\sum$ claimed - $\sum$ clawbacked
2. `hasClaimed` should never change its value from `true` to `false`

#### For VCA campaign:

1. total forgone = $\sum$ full amount requested - $\sum$ claimed
2. If vesting has ended, total forgone amount should never change.
3. If redistribution is enabled and campaign is sufficiently funded,
   - Redistribution rewards per token should never decrease.
   - If vesting has ended, redistribution rewards per token should never change.
   - `calculateRedistributionRewardsPerToken` should never revert.
   - Rewards distributed should never exceed total forgone amount.
4. If redistribution is enabled and campaign is not sufficiently funded,
   - `calculateRedistributionRewardsPerToken` should return 0.
