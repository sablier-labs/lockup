// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

contract MerkleMock {
    function IS_SABLIER_MERKLE() external pure returns (bool) {
        return true;
    }

    function lowerMinFeeUSD(uint256 newMinFeeUSD) external { }

    function setAttestor(address newAttestor) external { }
}

contract MerkleMockReverting {
    function IS_SABLIER_MERKLE() external pure returns (bool) {
        return true;
    }

    function lowerMinFeeUSD(uint256) external pure {
        revert("Not gonna happen");
    }

    function setAttestor(address) external pure {
        revert("Not gonna happen");
    }
}
