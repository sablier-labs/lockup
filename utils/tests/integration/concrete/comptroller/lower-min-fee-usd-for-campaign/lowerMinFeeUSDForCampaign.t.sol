// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "tests/Base.t.sol";
import {
    MerkleMock,
    MerkleMockReverting,
    MerkleMockWithFalseIsSablierMerkle,
    MerkleMockWithMissingIsSablierMerkle
} from "tests/mocks/MerkleMock.sol";

contract LowerMinFeeUSDForCampaign_Comptroller_Concrete_Test is Base_Test {
    MerkleMock internal merkleMock;
    MerkleMockReverting internal merkleMockReverting;
    MerkleMockWithFalseIsSablierMerkle internal merkleMockWithFalseIsSablierMerkle;
    MerkleMockWithMissingIsSablierMerkle internal merkleMockWithMissingIsSablierMerkle;

    function setUp() public override {
        Base_Test.setUp();

        // Deploy mock contracts.
        merkleMock = new MerkleMock();
        merkleMockReverting = new MerkleMockReverting();
        merkleMockWithFalseIsSablierMerkle = new MerkleMockWithFalseIsSablierMerkle();
        merkleMockWithMissingIsSablierMerkle = new MerkleMockWithMissingIsSablierMerkle();
    }

    function test_RevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMock), AIRDROP_MIN_FEE_USD);
    }

    function test_WhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // It should not revert.
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMock), AIRDROP_MIN_FEE_USD);
    }

    function test_RevertWhen_CampaignNotImplementSablierMerkle() external whenCallerAdmin {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_MissingIsSablierMerkle.selector, address(merkleMockWithMissingIsSablierMerkle)
            )
        );
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMockWithMissingIsSablierMerkle), AIRDROP_MIN_FEE_USD);
    }

    function test_RevertWhen_CampaignReturnsFalseForSablierMerkle()
        external
        whenCallerAdmin
        whenCampaignImplementsSablierMerkle
    {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_IsSablierMerkleReturnsFalse.selector,
                address(merkleMockWithFalseIsSablierMerkle)
            )
        );
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMockWithFalseIsSablierMerkle), AIRDROP_MIN_FEE_USD);
    }

    function test_RevertWhen_CallReverts()
        external
        whenCallerAdmin
        whenCampaignImplementsSablierMerkle
        whenCampaignReturnsTrueForSablierMerkle
    {
        // It should revert.
        vm.expectRevert("Not gonna happen");
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMockReverting), AIRDROP_MIN_FEE_USD);
    }

    function test_WhenCallDoesNotRevert()
        external
        whenCallerAdmin
        whenCampaignImplementsSablierMerkle
        whenCampaignReturnsTrueForSablierMerkle
    {
        // It should succeed.
        comptroller.lowerMinFeeUSDForCampaign(address(merkleMock), AIRDROP_MIN_FEE_USD);
    }
}
