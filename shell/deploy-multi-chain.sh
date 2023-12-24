#!/usr/bin/env bash

# Usage: ./shell/deploy-multi-chain.sh [options] [[chain1 chain2 ...]]
#   Enters interactive mode if .env.deployment not found
# Options:
#  --all              Deploy on all chains.
#  --broadcast        Broadcast the deployment and verify on Etherscan.
#  --deterministic    Deploy using the deterministic script.
#  -h, --help         Show available command-line options and exit.
#  -i, --interactive  Enters interactive mode and ignore .env.deployment.
#  --print            Simulate and show the deployment command.
#  -s, --script       Script to run from /script folder.
#  --with-gas-price   Specify gas price for transaction.
# Example: ./shell/deploy-multi-chain.sh # By default, deploys only to Sepolia
# Example: ./shell/deploy-multi-chain.sh --broadcast optimism mainnet
# Example: ./shell/deploy-multi-chain.sh --broadcast --deterministic --print mainnet

# Make sure you set-up your `.env.deployment` file first.

# Pre-requisites:
# - bash >=4.0.0
# - foundry (https://getfoundry.sh)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Color codes
EC='\033[0;31m' # Error Color
IC='\033[0;36m' # Info Color
NC='\033[0m' # No Color
SC='\033[0;32m' # Success Color
WC='\033[0;33m' # Warn Color

# Unicode characters for tick
TICK="\xE2\x9C\x94"

# Check: Bash >=4.0.0 is required for associative arrays
if ((BASH_VERSINFO[0] < 4)); then
    echo -e "${EC}Error:\nThis script requires Bash version 4.0.0 or higher.
    \nYou are currently using Bash version ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}.
    \nPlease upgrade your Bash version and try again.${NC}"
    exit 1
fi

# Define usage
usage="\nUsage: ./shell/deploy-multi-chain.sh [-h] [--help] [--print] [-i] [--interactive] [-s] [--script]
                                     [--broadcast] [--deterministic] [--with-gas-price] [--all]
                                     [[chain1 chain2 ...]]
Examples:
    ./shell/deploy-multi-chain.sh # By default, deploys only to Sepolia
    ./shell/deploy-multi-chain.sh --broadcast optimism mainnet
    ./shell/deploy-multi-chain.sh --broadcast --deterministic mainnet"

# Create deployments directory
deployments=./deployments
rm -rf ${deployments}
mkdir ${deployments}

# Addressed taken from https://docs.sablier.com/contracts/v2/deployments
ARBITRUM_COMPTROLLER="0x17Ec73692F0aDf7E7C554822FBEAACB4BE781762"
ARBITRUM_SEPOLIA_COMPTROLLER="0xA6A0cfA3442053fbB516D55205A749Ef2D33aed9"
AVALANCHE_COMPTROLLER="0x66F5431B0765D984f82A4fc4551b2c9ccF7eAC9C"
BASE_COMPTROLLER="0x7Faaedd40B1385C118cA7432952D9DC6b5CbC49e"
BSC_COMPTROLLER="0x33511f69A784Fd958E6713aCaC7c9dCF1A5578E8"
GNOSIS_COMPTROLLER="0x73962c44c0fB4cC5e4545FB91732a5c5e87F55C2"
MAINNET_COMPTROLLER="0xC3Be6BffAeab7B297c03383B4254aa3Af2b9a5BA"
OPTIMISM_COMPTROLLER="0x1EECb6e6EaE6a1eD1CCB4323F3a146A7C5443A10"
POLYGON_COMPTROLLER="0x9761692EDf10F5F2A69f0150e2fd50dcecf05F2E"
SCROLL_COMPTROLLER="0x859708495E3B3c61Bbe19e6E3E1F41dE3A5C5C5b"
SEPOLIA_COMPTROLLER="0x2006d43E65e66C5FF20254836E63947FA8bAaD68"

# Declare the chain IDs
ARBITRUM_CHAIN_ID="42161"
ARBITRUM_SEPOLIA_CHAIN_ID="421614"
AVALANCHE_CHAIN_ID="43114"
BASE_CHAIN_ID="8453"
BSC_CHAIN_ID="56"
GNOSIS_CHAIN_ID="100"
MAINNET_CHAIN_ID="1"
OPTIMISM_CHAIN_ID="10"
POLYGON_CHAIN_ID="137"
SCROLL_CHAIN_ID="534352"
SEPOLIA_CHAIN_ID="11155111"

# Flag for broadcast deployment
BROADCAST_DEPLOYMENT=false

# Flag for deterministic deployment
DETERMINISTIC_DEPLOYMENT=false

# Flag for gas price
GAS_PRICE=0
WITH_GAS_PRICE=false

# Flag for all chains
ON_ALL_CHAINS=false

# Flag for displaying deployement command
READ_ONLY=false

# Flag to enter interactive mode in case .env.deployment not found or --interactive is provided
INTERACTIVE=false

# Script to execute
sol_script=""

# Provided chains
provided_chains=()

# Declare the chains array
declare -A chains

# define function to initialize all configurations
function initialize {
    chains["arbitrum"]="$ARBITRUM_RPC_URL $ARBISCAN_API_KEY $ARBITRUM_CHAIN_ID $ARBITRUM_ADMIN $ARBITRUM_COMPTROLLER"
    chains["arbitrum_sepolia"]="$ARBITRUM_SEPOLIA_RPC_URL $ARBISCAN_API_KEY $ARBITRUM_SEPOLIA_CHAIN_ID $ARBITRUM_SEPOLIA_ADMIN $ARBITRUM_SEPOLIA_COMPTROLLER"
    chains["avalanche"]="$AVALANCHE_RPC_URL $SNOWTRACE_API_KEY $AVALANCHE_CHAIN_ID $AVALANCHE_ADMIN $AVALANCHE_COMPTROLLER"
    chains["base"]="$BASE_RPC_URL $BASESCAN_API_KEY $BASE_CHAIN_ID $BASE_ADMIN $BASE_COMPTROLLER"
    chains["bnb_smart_chain"]="$BSC_RPC_URL $BSCSCAN_API_KEY $BSC_CHAIN_ID $BSC_ADMIN $BSC_COMPTROLLER"
    chains["gnosis"]="$GNOSIS_RPC_URL $GNOSISSCAN_API_KEY $GNOSIS_CHAIN_ID $GNOSIS_ADMIN $GNOSIS_COMPTROLLER"
    chains["mainnet"]="$MAINNET_RPC_URL $ETHERSCAN_API_KEY $MAINNET_CHAIN_ID $MAINNET_ADMIN $MAINNET_COMPTROLLER"
    chains["optimism"]="$OPTIMISM_RPC_URL $OPTIMISTIC_API_KEY $OPTIMISM_CHAIN_ID $OPTIMISM_ADMIN $OPTIMISM_COMPTROLLER"
    chains["polygon"]="$POLYGON_RPC_URL $POLYGONSCAN_API_KEY $POLYGON_CHAIN_ID $POLYGON_ADMIN $POLYGON_COMPTROLLER"
    chains["sepolia"]="$SEPOLIA_RPC_URL $ETHERSCAN_API_KEY $SEPOLIA_CHAIN_ID $SEPOLIA_ADMIN $SEPOLIA_COMPTROLLER"
    chains["scroll"]="$SCROLL_RPC_URL $SCROLLSCAN_API_KEY $SCROLL_CHAIN_ID $SCROLL_ADMIN $SCROLL_COMPTROLLER"
}

# define function to initialize limited configurations
function initialize_interactive {
    # load values from the terminal prompt
    echo -e "1. Enter admin address: \c"
    read admin

    echo -e "2. Enter etherscan API key: \c"
    read api_key

    echo -e "3. Enter max segment count: \c"
    read MAX_SEGMENT_COUNT

    # chain id and comptroller only
    chains["arbitrum"]="$ARBITRUM_CHAIN_ID $ARBITRUM_COMPTROLLER"
    chains["arbitrum_sepolia"]="$ARBITRUM_SEPOLIA_CHAIN_ID $ARBITRUM_SEPOLIA_COMPTROLLER"
    chains["avalanche"]="$AVALANCHE_CHAIN_ID $AVALANCHE_COMPTROLLER"
    chains["base"]="$BASE_CHAIN_ID $BASE_COMPTROLLER"
    chains["bnb_smart_chain"]="$BSC_CHAIN_ID $BSC_COMPTROLLER"
    chains["gnosis"]="$GNOSIS_CHAIN_ID $GNOSIS_COMPTROLLER"
    chains["mainnet"]="$MAINNET_CHAIN_ID $MAINNET_COMPTROLLER"
    chains["optimism"]="$OPTIMISM_CHAIN_ID $OPTIMISM_COMPTROLLER"
    chains["polygon"]="$POLYGON_CHAIN_ID $POLYGON_COMPTROLLER"
    chains["sepolia"]="$SEPOLIA_CHAIN_ID $SEPOLIA_COMPTROLLER"
    chains["scroll"]="$SCROLL_CHAIN_ID $SCROLL_COMPTROLLER"
}

if [ -f .env.deployment ]; then
    # Source the .env.deployment file to load the variables
    source .env.deployment

    # initialize chains with all the configurations
    initialize
else
    # Set bool to enter intaractive mode
    INTERACTIVE=true

    # load values from the terminal prompt
    echo -e "${WC}Missing '.env.deployment'. Provide details below: ${NC}\n"

    # initialize chains with chain id and comptroller
    initialize_interactive

fi

# Check for arguments passed to the script
for ((i=1; i<=$#; i++)); do
    # Convert the argument to lowercase
    arg=${!i,,}

    # Check if '--all' flag is provided in the arguments
    if [[ ${arg} == "--all" ]]; then
        ON_ALL_CHAINS=true
        provided_chains=("${!chains[@]}")
    fi

    # Check if '--broadcast' flag is provided the arguments
    if [[ ${arg} == "--broadcast" ]]; then
        BROADCAST_DEPLOYMENT=true
    fi

    # Check if '--deterministic' flag is provided in the arguments
    if [[ ${arg} == "--deterministic" ]]; then
        echo -e "\nWhat version is this deployment? (1.1.1 / 1.1.2): \c"
        read VERSION
        if [[ "${VERSION}" != "1.1.1" && "${VERSION}" != "1.1.2" ]]; then
            echo -e "\n${EC}Invalid version. Please enter either 1.1.1 or 1.1.2${NC}"
            exit 1
        fi
        DETERMINISTIC_DEPLOYMENT=true
    fi

    # Show usage of this command with --help option
    if [[ ${arg} == "--help" || ${arg} == "-h" ]]; then
        echo -e "${usage}"
        # Get all network names from the chains array
        names=("${!chains[@]}")
        # Sort the names
        sorted_names=($(printf "%s\n" "${names[@]}" | sort))
        # Print the header
        printf "\nSupported networks: \n%-20s %-20s\n" "Network" "Chain ID"
        printf "%-20s %-20s\n" "-----------" "-----------"

        # Print the chains and their Chain IDs
        for chain in "${sorted_names[@]}"; do
            IFS=' ' read -r rpc_url api_key chain_id admin comptroller <<< "${chains[$chain]}"

            # Print the chain and Chain ID
            printf "%-20s %-20s\n" "${chain}" "${chain_id}"
        done
        exit 0
    fi

    # Check if '--interactive' flag is provided in the arguments
    if [[ ${arg} == "--interactive" || ${arg} == "-i" ]]; then
        INTERACTIVE=true
        echo -e "Interactive mode activated. Provide details below: \n"

        # initialize only chain id and comptroller
        initialize_interactive
    fi

    # Check if '--print' flag is provided in the arguments
    if [[ ${arg} == "--print" ]]; then
        READ_ONLY=true
    fi

    # Check if '--script' flag is provided in the arguments
    if [[ ${arg} == "--script" || ${arg} == "-s" ]]; then
        files=(script/*.s.sol)

        # Present the list of available scripts
        echo "Please select a script:"
        select file in "${files[@]}"; do
            if [[ -n ${file} ]]; then
                echo -e "${SC}+${NC} You selected ${IC}${file}${NC}"
                sol_script=${file}
                break
            else
                echo -e "${EC}Invalid selection${NC}"
            fi
        done
    fi

    # Check if '--with-gas-price' flag is provided in the arguments
    if [[ ${arg} == "--with-gas-price" ]]; then
        WITH_GAS_PRICE=true

        # Increment index to get the next argument, which should be the gas price
        ((i++))
        GAS_PRICE=${!i}
        if ! [[ ${GAS_PRICE} =~ ^[0-9]+$ ]]; then
            echo -e "${EC}Error: Invalid value for --with-gas-price, must be number${NC}"
            exit 1
        fi
    fi

    # Check for passed chains
    if [[ ${arg} != "--all" &&
            ${arg} != "--broadcast" &&
            ${arg} != "--deterministic" &&
            ${arg} != "--help" &&
            ${arg} != "-h" &&
            ${arg} != "-i" &&
            ${arg} != "--interactive" &&
            ${arg} != "--print" &&
            ${arg} != "-s" &&
            ${arg} != "--script" &&
            ${arg} != "--with-gas-price" &&
            ${ON_ALL_CHAINS} == false
    ]]; then
        # check for synonyms
        if [[ ${arg} == "ethereum" ]]; then
          arg="mainnet"
        fi
        provided_chains+=("${arg}")
    fi
done

# Set the default chain to Sepolia if no chains are provided
if [ ${#provided_chains[@]} -eq 0 ]; then
    provided_chains=("sepolia")
fi

# Compile the contracts
echo "Compiling the contracts..."

# Deploy to the provided chains
for chain in "${provided_chains[@]}"; do
    # Check if the provided chain is defined
    if [[ ! -v "chains[${chain}]" ]]; then
        printf "\n${WC}Warning for '${chain}': Invalid command or network. Get full list of supported networks: ${NC}"
        printf "\n\n\t${IC}./shell/deploy-multi-chain.sh --help${NC}\n"
        continue
    fi

    echo -e "\n${IC}Deployment on ${chain} started...${NC}"

    if [[ ${INTERACTIVE} == true ]]; then
        # load values from the terminal prompt
        echo -e "Enter RPC URL for ${chain} network: \c"
        read rpc_url

        # Get the values from the chains array
        IFS=' ' read -r chain_id comptroller <<< "${chains[$chain]}"
    else
        # Split the configuration into RPC, API key, Chain ID, admin, and comptroller
        IFS=' ' read -r rpc_url api_key chain_id admin comptroller <<< "${chains[$chain]}"
    fi

    # Declare a deployment command
    declare -a deployment_command

    deployment_command=("forge")

    # Construct the deployment command
    if [[ ${DETERMINISTIC_DEPLOYMENT} == true ]]; then
        echo -e "${SC}+${NC} Deterministic address"
        if [[ ${sol_script} == "" ]]; then
            deployment_command+=("script" "script/DeployDeterministicCore3.s.sol")
        else
            deployment_command+=("script" "${sol_script}")
        fi
        deployment_command+=("--rpc-url" "${rpc_url}")

        ####################################################################
        # Distinct ways to construct command with string elements
        # While execution adds single quotes around them while
        # echo removes single quotes
        ####################################################################
        if [[ ${READ_ONLY} == true ]]; then
            deployment_command+=("--sig" "'run(string,address,address,uint256)'")
            deployment_command+=("'ChainID ${chain_id}, Version ${VERSION}'")
        else
            deployment_command+=("--sig" "run(string,address,address,uint256)")
            deployment_command+=("ChainID ${chain_id}, Version ${VERSION}")
        fi
    else
        # Construct the command
        if [[ ${sol_script} == "" ]]; then
            deployment_command+=("script" "script/DeployCore3.s.sol")
        else
            deployment_command+=("script" "${sol_script}")
        fi
        deployment_command+=("--rpc-url" "${rpc_url}")

        if [[ ${READ_ONLY} == true ]]; then
            deployment_command+=("--sig" "'run(address,address,uint256)'")
        else
            deployment_command+=("--sig" "run(address,address,uint256)")
        fi
    fi

    deployment_command+=("${admin}")
    deployment_command+=("${comptroller}")
    deployment_command+=("${MAX_SEGMENT_COUNT}")
    deployment_command+=("-vvv")

    # Append additional options if gas price is enabled
    if [[ ${WITH_GAS_PRICE} == true ]]; then
        gas_price_in_gwei=$(echo "scale=2; ${GAS_PRICE} / 1000000000" | bc)
        echo -e "${SC}+${NC} Max gas price: ${gas_price_in_gwei} gwei"
        deployment_command+=("--with-gas-price" "${GAS_PRICE}")
    fi

    # Append additional options if broadcast is enabled
    if [[ ${BROADCAST_DEPLOYMENT} == true ]]; then
        echo -e "${SC}+${NC} Broadcasting on-chain"
        deployment_command+=("--broadcast" "--verify" "--etherscan-api-key" "${api_key}")
    else
        echo -e "${SC}+${NC} Simulating on forked network"
    fi

    if [[ ${READ_ONLY} == true ]]; then
        # print deployment_command
        echo -e "${SC}+${NC} Printing command without action\n"
        echo -e "FOUNDRY_PROFILE=optimized ${deployment_command[@]}"
    else
        # Execute the deployment command and print the logs in real-time
        output=$(FOUNDRY_PROFILE=optimized "${deployment_command[@]}" |& tee /dev/fd/2) || true

        # Check for error in output
        if [[ ${output} == *"Error"* ]]; then
            exit 1
        fi

        # Create a file for the chain
        chain_file="${deployments}/${chain}.txt"
        touch "${chain_file}"

        # Extract and save contract addresses
        lockupDynamic_address=$(echo "${output}" | awk '/lockupDynamic: contract/{print $NF}')
        lockupLinear_address=$(echo "${output}" | awk '/lockupLinear: contract/{print $NF}')
        nftDescriptor_address=$(echo "${output}" | awk '/nftDescriptor: contract/{print $NF}')

        # Save to the chain file
        {
            echo "SablierV2LockupDynamic = ${lockupDynamic_address}"
            echo "SablierV2LockupLinear = ${lockupLinear_address}"
            echo "SablierV2NFTDescriptor = ${nftDescriptor_address}"
        } >> "$chain_file"

        echo -e "${SC}${TICK} Deployed on ${chain}. You can find the addresses in ${chain_file}${NC}"
    fi
done

echo -e "\nEnd of it."
