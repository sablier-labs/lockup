// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract EnableRedistribution_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_RevertWhen_CallerNotCampaignCreator() external {
        // Set Eve as the caller.
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.campaignCreator, users.eve)
        );
        merkleVCA.enableRedistribution();
    }

    function test_RevertGiven_RedistributionEnabled() external whenCallerCampaignCreator {
        // Enable redistribution so that its enabled already.
        merkleVCA.enableRedistribution();

        // It should revert.
        vm.expectRevert(Errors.SablierMerkleVCA_RedistributionAlreadyEnabled.selector);
        merkleVCA.enableRedistribution();
    }

    function test_GivenRedistributionNotEnabled() external whenCallerCampaignCreator {
        // It should emit {RedistributionEnabled} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.RedistributionEnabled();

        merkleVCA.enableRedistribution();

        // It should enable redistribution.
        assertTrue(merkleVCA.isRedistributionEnabled(), "isRedistributionEnabled");
    }
}
