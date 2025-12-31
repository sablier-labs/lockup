### List of Invariants Implemented in [Invariant.t.sol](./Invariant.t.sol)

01. Next stream id = Current stream id + 1

02. For a token:

    - Aggregate amount = (Total deposited - Total refunded - Total withdrawn)
    - token.balanceOf(lockup) $`\ge`$ (Total deposited - Total refunded - Total withdrawn)

03. For a stream:

    - Deposited amount $`\ge`$ Streamed amount
    - Deposited amount $`\ge`$ Withdrawable amount
    - Deposited amount $`\ge`$ Withdrawn amount
    - Deposited amount $`\ge`$ 0
    - End time > Start time
    - Start time $`\ge`$ 0
    - Streamed amount $`\ge`$ Withdrawable amount
    - Streamed amount $`\ge`$ Withdrawn amount

04. For a canceled stream:

    - Refunded amount > 0
    - Stream should not be cancelable anymore
    - Refundable amount = 0
    - Withdrawable amount > 0

05. For a depleted stream:

    - Withdrawn amount = (Deposited amount - Refunded amount)
    - Stream should not be cancelable anymore
    - Refundable amount = 0
    - Withdrawable amount = 0

06. For a pending stream:

    - Refunded amount = 0
    - Withdrawn amount = 0
    - Refundable amount = Deposited amount
    - Streamed amount = 0
    - Withdrawable amount = 0

07. For a settled stream:

    - Refunded amount = 0
    - Stream should not be cancelable anymore
    - Refundable amount = 0
    - Streamed amount = Deposited amount

08. For a streaming stream:

    - Refunded amount = 0
    - Streamed amount < Deposited amount

09. State transitions:

    - PENDING $`\not\to`$ DEPLETED
    - STREAMING $`\not\to`$ PENDING
    - SETTLED $`\not\to`$ { PENDING, STREAMING, CANCELED }
    - CANCELED $`\not\to`$ { PENDING, STREAMING, SETTLED }
    - DEPLETED $`\to`$ DEPLETED

10. Gas usage:

    - Create $`\ge`$ Cancel
    - Create $`\ge`$ Withdraw

11. For a Dynamic stream, segment timestamps should be strictly increasing.

12. For a Linear stream,

    - If Cliff time > 0, $`\implies`$ Cliff time > Start time.
    - End time > Cliff time,
    - The streamed amount should not exceed the amount that would have been streamed if the stream had a granularity
      of 1.

13. For a Tranched stream, tranche timestamps should be strictly increasing.
