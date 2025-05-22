import * as dotenv from "dotenv";
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

dotenv.config();

let deployPrivateKey = process.env.PRIVATE_KEY as string;
if (!deployPrivateKey) {
  // default first account deterministically created by local nodes like `npx hardhat node` or `anvil`
  throw "No deployer private key set in .env";
}

module.exports = {
  solidity: {
    version: "0.8.26",
    evmVersion: "paris",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
      viaIR: true,
    },
    // @ts-ignore
  },
  networks: {
    iotex: {
      chainId: 4689,
      url: "https://babel-api.mainnet.iotex.io",
      accounts: [deployPrivateKey],
    },
    tangle: {
      chainId: 5845,
      url: "https://rpc.tangle.tools",
      accounts: [deployPrivateKey],
    },
    ultra: {
      chainId: 19991,
      url: "https://evm.ultra.eosusa.io/",
      accounts: [deployPrivateKey],
    },
  },
  etherscan: {
    apiKey: {
      iotex: "empty",
      tangle: "empty",
      ultra: "empty",
    },
    customChains: [
      {
        network: "iotex",
        chainId: 4689,
        urls: {
          apiURL: "https://IoTeXscout.io/api",
          browserURL: "https://IoTeXscan.io",
        },
      },
      {
        network: "tangle",
        chainId: 5845,
        urls: {
          apiURL: "https://explorer.tangle.tools/api",
          browserURL: "http://explorer.tangle.tools",
        },
      },
      {
        network: "ultra",
        chainId: 19991,
        urls: {
          apiURL: "https://evmexplorer.ultra.io/api",
          browserURL: "https://evmexplorer.ultra.io/",
        },
      },
    ],
  },
};
