// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

abstract contract Burn_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierLockup.burn, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.burn(nullStreamId);
    }

    function test_RevertGiven_PENDINGStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, defaultStreamId));
        lockup.burn(defaultStreamId);
    }

    function test_RevertGiven_STREAMINGStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, defaultStreamId));
        lockup.burn(defaultStreamId);
    }

    function test_RevertGiven_SETTLEDStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, defaultStreamId));
        lockup.burn(defaultStreamId);
    }

    function test_RevertGiven_CANCELEDStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        resetPrank({ msgSender: users.sender });
        lockup.cancel(defaultStreamId);
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, defaultStreamId));
        lockup.burn(defaultStreamId);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, defaultStreamId)
        whenCallerNotRecipient
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Unauthorized.selector, defaultStreamId, users.eve));
        lockup.burn(defaultStreamId);
    }

    function test_RevertWhen_CallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, defaultStreamId)
        whenCallerNotRecipient
    {
        resetPrank({ msgSender: users.sender });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_Unauthorized.selector, defaultStreamId, users.sender)
        );
        lockup.burn(defaultStreamId);
    }

    function test_WhenCallerApprovedThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, defaultStreamId)
        whenCallerNotRecipient
    {
        // Make the third party the caller in this test.
        resetPrank({ msgSender: users.operator });

        // It should burn the NFT.
        _test_Burn(defaultStreamId);
    }

    function test_RevertGiven_NFTNotExist()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, defaultStreamId)
        whenCallerRecipient
    {
        // Burn the NFT so that it no longer exists.
        lockup.burn(defaultStreamId);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, defaultStreamId));
        lockup.burn(defaultStreamId);
    }

    /// @dev For this test, we will skip the `givenDepletedStream` modifier given the `notTransferableStreamId` is not
    /// yet created.
    function test_GivenNonTransferableNFT()
        external
        whenNoDelegateCall
        givenNotNull
        /*  givenDepletedStream(lockup, notTransferableStreamId) */
        whenCallerRecipient
        givenNFTExists
    {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: notTransferableStreamId, to: users.recipient });
        _test_Burn(notTransferableStreamId);
    }

    function test_GivenTransferableNFT()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, defaultStreamId)
        whenCallerRecipient
        givenNFTExists
    {
        _test_Burn(defaultStreamId);
    }

    function _test_Burn(uint256 streamId) private {
        // It should emit a {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Burn the NFT.
        lockup.burn(streamId);

        // It should burn the NFT.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, streamId));
        lockup.getRecipient(streamId);
    }
}
