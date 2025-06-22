#!/usr/bin/env bash

# Pre-requisites:
# - foundry (https://getfoundry.sh)
# - bun (https://bun.sh)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Generate the artifacts with Forge
forge build

# Delete the current artifacts
artifacts=./artifacts
rm -rf $artifacts

# Create the new artifacts directories
mkdir $artifacts \
  "$artifacts/interfaces" \
  "$artifacts/libraries" \
  "$artifacts/erc20" \
  "$artifacts/erc721"

################################################
####                LOCKUP                  ####
################################################

lockup=./artifacts/
cp out/LockupNFTDescriptor.sol/LockupNFTDescriptor.json $lockup
cp out/SablierLockup.sol/SablierLockup.json $lockup
cp out/SablierBatchLockup.sol/SablierBatchLockup.json $lockup

lockup_interfaces=./artifacts/interfaces
cp out/ISablierBatchLockup.sol/ISablierBatchLockup.json $lockup_interfaces
cp out/ILockupNFTDescriptor.sol/ILockupNFTDescriptor.json $lockup_interfaces
cp out/ISablierLockupRecipient.sol/ISablierLockupRecipient.json $lockup_interfaces
cp out/ISablierLockupState.sol/ISablierLockupState.json $lockup_interfaces
cp out/ISablierLockup.sol/ISablierLockup.json $lockup_interfaces

lockup_libraries=./artifacts/libraries
cp out/Errors.sol/Errors.json $lockup_libraries
cp out/Helpers.sol/Helpers.json $lockup_libraries
cp out/LockupMath.sol/LockupMath.json $lockup_libraries


################################################
####                OTHERS                  ####
################################################

erc20=./artifacts/erc20
cp out/IERC20.sol/IERC20.json $erc20

erc721=./artifacts/erc721
cp out/IERC721.sol/IERC721.json $erc721
cp out/IERC721Metadata.sol/IERC721Metadata.json $erc721

# Format the artifacts with Prettier
bun prettier --write ./artifacts
