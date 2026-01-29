// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetAttestor_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        factoryMerkleBase.setAttestor(users.eve);
    }

    function test_WhenCallerComptroller() external whenCallerComptroller {
        address newAttestor = makeAddr("newAttestor");
        address previousAttestor = factoryMerkleBase.attestor();

        // It should emit a {SetAttestor} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.SetAttestor({
            comptroller: address(comptroller),
            previousAttestor: previousAttestor,
            newAttestor: newAttestor
        });

        // Set attestor.
        factoryMerkleBase.setAttestor(newAttestor);

        // It should set the attestor.
        assertEq(factoryMerkleBase.attestor(), newAttestor, "attestor");
    }
}
