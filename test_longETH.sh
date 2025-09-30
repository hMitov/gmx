#!/bin/bash



# define the env vars
# Set your Arbitrum RPC URL here - using local anvil fork
export ARBITRUM_RPC_URL="http://localhost:8545" 
export weth=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
export usdc=0xaf88d065e77c8cC2239327C5EDb3A432268e5831

# the default pub/privkey provided by anvil
export pubkey=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export privkey=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

export uni2_router=0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24

# deploy the contract
echo "Deploying contract..."
CONTRACT_ADDR=$(forge create \
    --private-key=$privkey \
    --broadcast \
    --rpc-url=$ARBITRUM_RPC_URL \
    src/GMXIntegration.sol:GMXIntegration | grep "Deployed to:" | awk '{print $3}')

if [ -z "$CONTRACT_ADDR" ]; then
    echo "Failed to deploy contract"
    exit 1
fi

echo "Contract deployed to: $CONTRACT_ADDR"
export cnt=$CONTRACT_ADDR

# exchange 1ETH for USDC through uniswapV2
# and directly transfer them to the contract - we'll use the funds to open an ETH-USDC long on GMX through our custom contract's longETH()
echo "Swapping 1 ETH for USDC..."
cast send \
    --private-key=$privkey \
    --rpc-url=$ARBITRUM_RPC_URL \
    --value=$(cast tw 1) \
    $uni2_router \
    "swapExactETHForTokens(uint256,address[],address,uint256)" 0 "[$weth, $usdc]" $cnt $(cast maxu)

# verify that the contract has >0 USDC balance after the swap
echo "Checking USDC balance..."
cast balance --erc20 $usdc $cnt --rpc-url=$ARBITRUM_RPC_URL

# finally, call `GmxInteraction`'s `longETH()`, triggering a new ETH long position
echo "Calling longETH() function..."
cast send \
    --private-key=$privkey \
    --rpc-url=$ARBITRUM_RPC_URL \
    --value=$(cast tw 0.00093189148) \
    --gas-limit=10000000 \
    $cnt "longETH()"

echo "Script completed successfully!"

# Cleanup: kill anvil if we started it
if [ ! -z "$ANVIL_PID" ]; then
    echo "Stopping anvil (PID: $ANVIL_PID)..."
    kill $ANVIL_PID
fi