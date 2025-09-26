#!/bin/bash

# Fork arbitrum locally in a separate terminal
# anvil --fork-url=<YOUR ARBITRUM RPC> --fork-block-number=365839831

# Define the env vars 
export weth=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
export usdc=0xaf88d065e77c8cC2239327C5EDb3A432268e5831
export pubkey=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export privkey=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export uni2_router=0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24

echo "Test longETH"
echo "WETH: $weth"
echo "USDC: $usdc"
echo "Public key: $pubkey"

# -----------------------------
# Deploy GMXIntegration contract
# -----------------------------
echo "Step 1: Deploy contract"
cnt=$(forge create --private-key=$privkey --broadcast src/GMXIntegration.sol:GMXIntegration | grep "Deployed to:" | awk '{print $3}')
export cnt
echo "Contract deployed at: $cnt"

# You will see the contract's deployed address defined as "Deployed to <addr>" - export it to env var.
# export cnt=<DEPLOYED CONTRACT ADDR>

# Exchange 1ETH for USDC through uniswapV2
# and directly transfer them to the contract - we'll use the funds to open an ETH-USDC long on GMX through our custom contract's longETH()
echo "Step 2: Fund contract with USDC"
cast send \
    --private-key=$privkey \
    --value=$(cast tw 1) \
    $uni2_router \
    "swapExactETHForTokens(uint256,address[],address,uint256)" 0 "[$weth, $usdc]" $cnt $(cast maxu)

# Verify that the contract has >0 USDC balance after the swap
echo "Step 3: Check USDC balance"
cast balance --erc20 $usdc $cnt

# Finally, call `GmxInteraction`'s `longETH()`, triggering a new ETH long position
# executionFee: 0.00093189148 ETH (in wei: 931891480000000)
# acceptablePrice: 3742437801860489 (from original hardcoded value)
cast send \
    --private-key=$privkey \
    --value=$(cast tw 0.00093189148) \
    --gas-limit=10000000 \
    $cnt "longETH(uint256,uint256)" 93189148000000 3742437801860489
