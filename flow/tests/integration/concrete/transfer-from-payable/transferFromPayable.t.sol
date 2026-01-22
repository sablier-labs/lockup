// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract TransferFromPayable_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function setUp() public virtual override {
        Shared_Integration_Concrete_Test.setUp();

        // Prank the recipient for this test.
        setMsgSender(users.recipient);
    }

    function test_WhenETHValueIsGreaterThanZero() external {
        // It should emit {MetadataUpdate} and {Transfer} events.
        vm.expectEmit({ emitter: address(flow) });
        emit IERC721.Transfer({ from: users.recipient, to: users.operator, tokenId: defaultStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        flow.transferFromPayable{ value: FLOW_MIN_FEE_WEI }({
            from: users.recipient,
            to: users.operator,
            streamId: defaultStreamId
        });

        // It should transfer the NFT.
        address actualRecipient = flow.getRecipient(defaultStreamId);
        address expectedRecipient = users.operator;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
