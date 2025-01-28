import { Addressable } from "ethers";
import hre from "hardhat";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { Wallet, Provider } from "zksync-ethers";

// First you need to deploy the public libraries: `npx hardhat deploy-zksync:libraries --network zkSyncMainnet/zkSyncTestnet --private-key-or-index $PRIVATE_KEY`
// Then deploy the rest of the contracts: `npx hardhat deploy-zksync --script deploy.ts --network zkSyncMainnet/zkSyncTestnet
export default async function () {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const provider = new Provider(hre.network.config.url);
  const deployerAddressPV = new Wallet(process.env.PRIVATE_KEY as string).connect(provider);
  const deployerAddress = deployerAddressPV.address;

  if (!deployerAddress) {
    console.error("Please set the PRIVATE_KEY in your .env file");
    return;
  }

  console.table({
    contract: "LockupNFTDescriptor & SablierLockup & SablierBatchLockup",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
  });

  const deployer = new Deployer(hre, deployerAddressPV);

  const artifactNFTDescriptor = await deployer.loadArtifact("LockupNFTDescriptor");
  const artifactBatchLockup = await deployer.loadArtifact("SablierBatchLockup");
  const artifactLockup = await deployer.loadArtifact("SablierLockup");

  const admineoa = "0xb1bef51ebca01eb12001a639bdbbff6eeca12b9f";

  // Deploy the NFTDescriptor contract
  const nftDescriptor = await deployer.deploy(artifactNFTDescriptor, []);
  const nftDescriptorAddress =
    typeof nftDescriptor.target === "string" ? nftDescriptor.target : nftDescriptor.target.toString();
  console.log("LockupNFTDescriptor deployed to:", nftDescriptorAddress);
  await verifyContract(nftDescriptorAddress, []);

  // Deploy the SablierLockup contract
  const lockup = await deployer.deploy(artifactLockup, [admineoa, nftDescriptorAddress, "2000"]);
  const lockupAddress = typeof lockup.target === "string" ? lockup.target : lockup.target.toString();
  console.log("SablierLockup deployed to:", lockupAddress);
  await verifyContract(lockupAddress, [admineoa, nftDescriptorAddress, "2000"]);

  // Deploy the BatchLockup contract
  const batchLockup = await deployer.deploy(artifactBatchLockup, []);
  const batchLockupAddress =
    typeof batchLockup.target === "string" ? batchLockup.target : batchLockup.target.toString();
  console.log("SablierBatchLockup deployed to:", batchLockupAddress);
  await verifyContract(batchLockupAddress, []);
}

const verifyContract = async (contractAddress: string | Addressable, verifyArgs: string[]): Promise<boolean> => {
  console.log("\nVerifying contract...");
  await new Promise((r) => setTimeout(r, 20000));
  try {
    await hre.run("verify:verify", {
      address: contractAddress.toString(),
      constructorArguments: verifyArgs,
      noCompile: true,
    });
  } catch (e) {
    console.log(e);
  }
  return true;
};
