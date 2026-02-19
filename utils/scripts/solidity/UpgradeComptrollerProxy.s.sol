// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Options, Upgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

/// @notice Upgrades the Sablier Comptroller.
/// @dev The deployed Sablier Comptroller is set as the implementation of the existing proxy.
///
/// The following upgrade script runs a storage collision check between the new implementation contract and the previous
/// version. The function requires access to the previous version of the contract. Therefore, to perform the upgrade,
/// follow the steps below:
/// 1. Flatten the previous version of the Comptroller contract by using the following command on
/// https://github.com/sablier-labs/evm-utils/blob/main/src/SablierComptroller.sol:
///  - `forge flatten src/SablierComptroller.sol > SablierComptrollerV1.sol`
/// 2. Place it in `src/legacy` directory in this repo.
/// 3. Run the upgrade script from the `utils/` directory:
///  - `just build`
///  - `forge script scripts/solidity/UpgradeComptrollerProxy.s.sol:UpgradeComptrollerProxy --rpc-url <CHAIN>`
contract UpgradeComptrollerProxy is BaseScript {
    function run() public broadcast returns (address implementation) {
        // Declare the constructor parameters of the implementation contract.
        Options memory opts;
        opts.constructorData = abi.encode(getAdmin());

        // Disable the constructor check for the implementation contract.
        // See https://docs.openzeppelin.com/upgrades-plugins/faq#how-can-i-disable-checks
        opts.unsafeAllow = "constructor";

        // Set the reference contract for the storage layout comparison.
        opts.referenceContract = "SablierComptrollerV1.sol:SablierComptroller";

        // Get comptroller proxy address.
        address comptrollerProxy = getComptroller();

        // Perform the following steps:
        // 1. Deploys the Comptroller.
        // 2. Sets the implementation of the proxy to the address of the deployed Comptroller.
        Upgrades.upgradeProxy({
            proxy: comptrollerProxy,
            contractName: "SablierComptroller.sol:SablierComptroller",
            data: "",
            opts: opts
        });

        implementation = Upgrades.getImplementationAddress(comptrollerProxy);
    }
}
