// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable max-line-length,quotes
pragma solidity >=0.8.22;

import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";
import { Constants } from "./Constants.sol";
import { Claim, EIP712Domain } from "./Types.sol";

abstract contract Utils is BaseUtils, Constants {
    /// @notice Computes the EIP-712 domain separator for the provided Merkle contract.
    function computeEIP712DomainSeparator(address merkleContract) internal view returns (bytes32) {
        return vm.eip712HashStruct({
            typeNameOrDefinition: SCHEMA_EIP712_DOMAIN,
            abiEncodedData: abi.encode(
                EIP712Domain({ name: PROTOCOL_NAME, chainId: block.chainid, verifyingContract: merkleContract })
            )
        });
    }

    /// @notice Generates the EIP-712 signature for the given claim parameters and returns it.
    function generateEIP712Signature(
        uint256 signerPrivateKey,
        address merkleContract,
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom
    )
        internal
        view
        returns (bytes memory signature)
    {
        // Concatenate EIP-712 Domain and Claim message types.
        string memory typesJson = string.concat(
            "{",
            '"EIP712Domain":[{"name":"name","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],',
            '"Claim":[{"name":"index","type":"uint256"},{"name":"recipient","type":"address"},{"name":"to","type":"address"},{"name":"amount","type":"uint128"},{"name":"validFrom","type":"uint40"}]',
            "}"
        );

        // Define the primary type.
        string memory primaryType = '"Claim"';

        // Serialize EIP-712 domain parameters.
        string memory domainJson = vm.serializeJsonType(
            SCHEMA_EIP712_DOMAIN,
            abi.encode(EIP712Domain({ name: PROTOCOL_NAME, chainId: block.chainid, verifyingContract: merkleContract }))
        );

        // Serialize Claim message parameters.
        string memory claimMessageJson =
            vm.serializeJsonType(SCHEMA_CLAIM, abi.encode(Claim(index, recipient, to, amount, validFrom)));

        // Construct the typed data JSON.
        string memory typedDataJson = string.concat(
            '{"types":',
            typesJson,
            ',"primaryType":',
            primaryType,
            ',"domain":',
            domainJson,
            ',"message":',
            claimMessageJson,
            "}"
        );

        // Compute the digest.
        bytes32 digest = vm.eip712HashTypedData(typedDataJson);

        // Sign the digest.
        signature = sign(signerPrivateKey, digest);
    }

    /// @notice Signs the provided digest using private key and returns the signature.
    function sign(uint256 signerPrivateKey, bytes32 digest) internal pure returns (bytes memory signature) {
        // Sign the digest.
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        // Return the signature.
        signature = abi.encodePacked(r, s, v);
    }
}
