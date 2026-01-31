// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetAttestor_Integration_Test is Integration_Test {
    address internal newAttestor;

    function setUp() public virtual override {
        // Make `users.campaignCreator` the caller for this test.
        setMsgSender(users.campaignCreator);

        newAttestor = makeAddr("newAttestor");
    }

    function test_RevertWhen_CallerNotComptrollerOrAdmin() external {
        setMsgSender(users.eve);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleSignature_CallerNotComptrollerOrAdmin.selector,
                address(comptroller),
                users.campaignCreator,
                users.eve
            )
        );
        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);
    }

    function test_RevertGiven_AttestorAlreadySetByAdmin() external whenCallerComptroller {
        // First, have admin set the attestor to mark `attestorSetByAdmin` as true.
        setMsgSender(users.campaignCreator);
        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);

        // Now switch to comptroller caller.
        setMsgSender(address(comptroller));

        vm.expectRevert(Errors.SablierMerkleSignature_AttestorAlreadySetByAdmin.selector);
        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);
    }

    function test_GivenAttestorNotSetByAdmin() external whenCallerComptroller {
        address previousAttestor = ISablierMerkleSignature(address(merkleBase)).attestor();

        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleSignature.SetAttestor({
            caller: address(comptroller),
            previousAttestor: previousAttestor,
            newAttestor: newAttestor
        });

        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);

        assertEq(ISablierMerkleSignature(address(merkleBase)).attestor(), newAttestor, "attestor");
        assertFalse(ISablierMerkleSignature(address(merkleBase)).attestorSetByAdmin(), "attestor set by admin");
    }

    function test_WhenCallerCampaignCreator() external whenCallerCampaignCreator {
        address previousAttestor = ISablierMerkleSignature(address(merkleBase)).attestor();

        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleSignature.SetAttestor({
            caller: users.campaignCreator,
            previousAttestor: previousAttestor,
            newAttestor: newAttestor
        });

        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);

        assertEq(ISablierMerkleSignature(address(merkleBase)).attestor(), newAttestor, "attestor");
        assertTrue(ISablierMerkleSignature(address(merkleBase)).attestorSetByAdmin(), "attestor set by admin");
    }
}
