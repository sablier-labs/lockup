### List of Invariants

#### For all campaigns:

1. token.balanceOf(campaign) = total deposit - $\sum$ claimed - $\sum$ clawbacked
2. `hasClaimed` should never change its value from `true` to `false`

#### For VCA campaign:

1. For MerkleVCA campaigns, total forgone = $\sum$ claim requested - $\sum$ claimed
