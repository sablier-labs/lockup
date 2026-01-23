### List of Invariants

#### For all campaigns:

1. token.balanceOf(campaign) = total deposit - $\\sum$ claimed - $\\sum$ clawbacked
2. `hasClaimed` should never change its value from `true` to `false`
3. `minFeeUSD` should never increase

#### For VCA campaign:

1. total forgone amount = $\\sum$ claim amount requested - $\\sum$ claimed amount
2. total forgone amount should never decrease
