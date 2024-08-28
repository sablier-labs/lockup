// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as CoreErrors } from "src/core/libraries/Errors.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

abstract contract Clawback_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(CoreErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleBase.clawback({ to: users.eve, amount: 1 });
    }

    function test_WhenFirstClaimNotMade() external whenCallerAdmin {
        test_Clawback(users.admin);
    }

    function test_GivenSevenDaysNotPassed() external whenCallerAdmin whenFirstClaimMade {
        vm.warp({ newTimestamp: getBlockTimestamp() + 6 days });
        test_Clawback(users.admin);
    }

    function test_RevertGiven_CampaignNotExpired() external whenCallerAdmin whenFirstClaimMade givenSevenDaysPassed {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_ClawbackNotAllowed.selector,
                getBlockTimestamp(),
                defaults.EXPIRATION(),
                defaults.FIRST_CLAIM_TIME()
            )
        );
        merkleBase.clawback({ to: users.admin, amount: 1 });
    }

    function test_GivenCampaignExpired(address to) external whenCallerAdmin whenFirstClaimMade givenSevenDaysPassed {
        vm.warp({ newTimestamp: defaults.EXPIRATION() + 1 seconds });
        vm.assume(to != address(0));
        test_Clawback(to);
    }

    function test_Clawback(address to) internal {
        uint128 clawbackAmount = uint128(dai.balanceOf(address(merkleBase)));
        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ to: to, value: clawbackAmount });
        // It should emit a {Clawback} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit Clawback({ admin: users.admin, to: to, amount: clawbackAmount });
        merkleBase.clawback({ to: to, amount: clawbackAmount });
    }
}
