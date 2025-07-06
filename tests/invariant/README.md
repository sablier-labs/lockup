List of Invariants Implemented in Invariant.t.sol

1. For the Lockup contract:
   token.balanceOf(Lockup) ≥ Σ deposited amounts - Σ refunded amounts - Σ withdrawn amounts

2. For any stream:
   deposited amount ≥ streamed amount

3. For any stream:
   deposited amount ≥ withdrawable amount

4. For any stream:
   deposited amount ≥ withdrawn amount

5. For any stream:
   deposited amount ≠ 0 (stream non-null)

6. For any stream:
   end time > start time

7. For the Lockup contract:
   next stream ID = last stream ID + 1

8. For any stream:
   start time > 0

9. For any canceled stream:
   refunded amount > 0
   refundable amount = 0
   withdrawable amount > 0
   stream not cancelable

10. For any depleted stream:
    deposited amount - refunded amount = withdrawn amount
    refundable amount = 0
    withdrawable amount = 0
    stream not cancelable

11. For any pending stream:
    refunded amount = 0
    withdrawn amount = 0
    refundable amount = deposited amount
    streamed amount = 0
    withdrawable amount = 0

12. For any settled stream:
    refunded amount = 0
    refundable amount = 0
    streamed amount = deposited amount
    stream not cancelable

13. For any streaming stream:
    refunded amount = 0
    streamed amount < deposited amount

14. Valid status transitions:
    If previous status = Pending:
      Cannot transition to Depleted
    If previous status = Streaming:
      Cannot transition to Pending
    If previous status = Settled:
      Cannot transition to Pending
      Cannot transition to Streaming
      Cannot transition to Canceled
    If previous status = Canceled:
      Cannot transition to Pending
      Cannot transition to Streaming
      Cannot transition to Settled
    If previous status = Depleted:
      Must remain Depleted

15. For any stream:
    streamed amount ≥ withdrawable amount

16. For any stream:
    streamed amount ≥ withdrawn amount

17. For any dynamic stream:
    segment timestamps strictly increasing

18. For any linear stream:
    if cliff time > 0: cliff time > start time

19. For any linear stream:
    end time > cliff time

20. For any tranched stream:
    tranche timestamps strictly increasing