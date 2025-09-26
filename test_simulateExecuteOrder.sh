#!/bin/bash

# IMPORTANT: Start anvil first in a separate terminal:
# anvil --fork-url=https://api.zan.top/arb-one --fork-block-number=365839831

# Set environment variables
export weth=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
export usdc=0xaf88d065e77c8cC2239327C5EDb3A432268e5831
export pubkey=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export privkey=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export uni2_router=0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24

echo "Test simulateExecuteOrder"
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

EXECUTION_FEE=93189148000000
ACCEPTABLE_PRICE=2100000000000000000000000000000

# -----------------------------
# Fund contract with USDC
# -----------------------------
echo "Step 2: Fund contract with USDC"
cast send --private-key=$privkey --value=$(cast tw 1) $uni2_router "swapExactETHForTokens(uint256,address[],address,uint256)" 0 "[$weth, $usdc]" $cnt $(cast maxu)

# -----------------------------
# Check USDC balance
# -----------------------------
echo "Step 3: Check USDC balance"
cast balance --erc20 $usdc $cnt

# -----------------------------
# Create order and capture order key
# -----------------------------
echo "Step 4: Create order and capture order key"

ORDER_KEY=$(cast send \
  --private-key=$privkey \
  --value=$EXECUTION_FEE \
  --gas-limit=10000000 \
  $cnt \
  "longETH(uint256,uint256)" \
  $EXECUTION_FEE \
  $ACCEPTABLE_PRICE | grep -o "0x[a-fA-F0-9]\{64\}" | tail -1)
echo "Order created"
echo "Order key: $ORDER_KEY"


ETH_MIN=1990000000000000000000000000000
ETH_MAX=2010000000000000000000000000000

# USDC = ~1, scaled 1e30
USDC_PRICE=1000000000000000000000000000
# -----------------------------
# Test simulation with captured order key
# -----------------------------
cast send \
  --private-key=$privkey \
  --gas-limit=10000000 \
  $cnt \
  "simulateOrderWithPrices(bytes32,address[],uint256[],uint256[])" \
  "$ORDER_KEY" \
  "[$weth,$usdc]" \
  "[1800000000000000000000,1000000000000000000000000]" \
  "[2000000000000000000000,1000000000000000000000000]"

echo "Simulation done"