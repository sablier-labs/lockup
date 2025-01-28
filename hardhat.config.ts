import * as dotenv from "dotenv";

import "@nomicfoundation/hardhat-foundry";
import "@matterlabs/hardhat-zksync";
import "@nomiclabs/hardhat-solhint";
import "@typechain/hardhat";
import fs from "fs";
import "hardhat-preprocessor";
import { HardhatUserConfig } from "hardhat/config";

dotenv.config();

let deployPrivateKey = process.env.PRIVATE_KEY as string;
if (!deployPrivateKey) {
  // default first account deterministically created by local nodes like `npx hardhat node` or `anvil`
  throw "No deployer private key set in .env";
}

/**
 * Generates hardhat network configuration
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      viaIR: true,
    },
    // @ts-ignore
  },
  networks: {
    sophonMainnet: {
      url: "https://rpc.sophon.xyz",
      ethNetwork: "mainnet",
      verifyURL: "https://verification-explorer.sophon.xyz/contract_verification",
      browserVerifyURL: "https://explorer.sophon.xyz/",
      enableVerifyURL: true,
      zksync: true,
      accounts: [process.env.PRIVATE_KEY as string],
      chainId: 50104,
    },
  },
  paths: {
    sources: "./contracts",
    cache: "./cache_hardhat",
  },
  zksolc: {
    version: "1.5.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
        mode: "z",
        fallback_to_optimizing_for_size: true,
      },
      libraries: {
        "contracts/libraries/Helpers.sol": {
          Helpers: "0x424B27529B49EF4Bfa0727aFcFE4387Ac2932944",
        },
        "contracts/libraries/VestingMath.sol": {
          VestingMath: "0x9971914DA16787F6cCfb27bEfB4404e33C8b869D",
        },
      },
    },
  },
  etherscan: {
    apiKey: {
      sophonMainnet: "",
    },
  },
};

export default config;
