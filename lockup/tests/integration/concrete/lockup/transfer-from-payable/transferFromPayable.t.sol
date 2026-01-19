// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract TransferFromPayable_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Set recipient as caller for this test.
        setMsgSender(users.recipient);
    }

    function test_WhenETHValueIsZero() external {
        // It should emit {MetadataUpdate} and {Transfer} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.defaultStream });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC721.Transfer({ from: users.recipient, to: users.alice, tokenId: ids.defaultStream });

        // Transfer the NFT.
        lockup.transferFromPayable({ from: users.recipient, to: users.alice, streamId: ids.defaultStream });

        // It should change the stream recipient (and NFT owner).
        address actualRecipient = lockup.getRecipient(ids.defaultStream);
        address expectedRecipient = users.alice;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }

    function test_WhenETHValueIsGreaterThanZero() external {
        // It should emit {MetadataUpdate} and {Transfer} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.defaultStream });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC721.Transfer({ from: users.recipient, to: users.alice, tokenId: ids.defaultStream });

        // Transfer the NFT.
        lockup.transferFromPayable{ value: LOCKUP_MIN_FEE_WEI }({
            from: users.recipient,
            to: users.alice,
            streamId: ids.defaultStream
        });

        // It should change the stream recipient (and NFT owner).
        address actualRecipient = lockup.getRecipient(ids.defaultStream);
        address expectedRecipient = users.alice;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
