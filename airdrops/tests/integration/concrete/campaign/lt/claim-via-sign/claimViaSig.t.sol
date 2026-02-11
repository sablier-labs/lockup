// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ClaimType } from "src/types/DataTypes.sol";
import { ClaimViaSig_Integration_Test } from "./../../shared/claim-via-sig/claimViaSig.t.sol";
import { MerkleLT_Integration_Shared_Test } from "./../MerkleLT.t.sol";

contract ClaimViaSig_MerkleLT_Integration_Test is ClaimViaSig_Integration_Test, MerkleLT_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLT_Integration_Shared_Test, ClaimViaSig_Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
        ClaimViaSig_Integration_Test.setUp();
    }

    function test_RevertGiven_ClaimTypeATTEST() external {
        merkleBase = merkleLTAttest;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_UnsupportedClaimType.selector, ClaimType.DEFAULT, ClaimType.ATTEST
            )
        );
        claimViaSig();
    }

    function test_WhenSignatureValidityTimestampNotInFuture()
        external
        override
        givenClaimTypeNotAttest
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
        whenSignerSameAsRecipient
    {
        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        eip712Signature = generateSignature(users.recipient, address(merkleLT));

        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLT.ClaimLTWithVesting(
            index,
            users.recipient,
            CLAIM_AMOUNT,
            expectedStreamId,
            users.eve,
            true
        );

        expectCallToTransferFrom({ from: address(merkleLT), to: address(lockup), value: CLAIM_AMOUNT });
        expectCallToClaimViaSigWithMsgValue(address(merkleLT), AIRDROP_MIN_FEE_WEI);

        // Claim the airstream.
        claimViaSig();

        assertTrue(merkleLT.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }

    function test_WhenRecipientImplementsIERC1271Interface()
        external
        override
        givenClaimTypeNotAttest
        whenToAddressNotZero
        givenRecipientIsContract
    {
        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree(users.smartWalletWithIERC1271);

        eip712Signature = generateSignature(users.smartWalletWithIERC1271, address(merkleLT));

        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLT.ClaimLTWithVesting(
            index,
            users.smartWalletWithIERC1271,
            CLAIM_AMOUNT,
            expectedStreamId,
            users.eve,
            true
        );

        expectCallToTransferFrom({ from: address(merkleLT), to: address(lockup), value: CLAIM_AMOUNT });

        // Claim the airstream.
        claimViaSig(users.smartWalletWithIERC1271, CLAIM_AMOUNT);

        assertTrue(merkleLT.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
