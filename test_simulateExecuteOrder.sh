#!/bin/bash
set -euo pipefail

# define the env vars
export ARBITRUM_RPC_URL="http://localhost:8545"
export weth=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
export usdc=0xaf88d065e77c8cC2239327C5EDb3A432268e5831
export index_token=0xfe1Aac2CD9c5cC77b58EeCfE75981866ed0c8b7a

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

echo "Contract deployed to: $CONTRACT_ADDR"
export cnt=$CONTRACT_ADDR

# exchange 1ETH for USDC through uniswapV2
echo "Swapping 1 ETH for USDC..."
cast send \
    --private-key=$privkey \
    --rpc-url=$ARBITRUM_RPC_URL \
    --value=$(cast tw 30) \
    $uni2_router \
    "swapExactETHForTokens(uint256,address[],address,uint256)" 0 "[$weth, $usdc]" $cnt $(cast maxu)

# verify contract balance
echo "Checking USDC balance..."
cast balance --erc20 $usdc $cnt --rpc-url=$ARBITRUM_RPC_URL

# call longETH()
echo "Calling longETH()..."
RAW_TX=$(cast send \
  --private-key="$privkey" \
  --rpc-url="$ARBITRUM_RPC_URL" \
  --value=$(cast tw 0.00093189148) \
  --gas-limit=10000000 \
  --json \
  "$cnt" "longETH()")
echo "Raw tx: $RAW_TX"

TX_HASH=$(echo "$RAW_TX" | jq -r '.transactionHash')
if [ -z "$TX_HASH" ] || [ "$TX_HASH" = "null" ]; then
    echo "No tx hash found. Did the tx revert?"
    exit 1
fi

echo "Transaction hash: $TX_HASH"
# Check if tx succeeded
TX_STATUS=$(cast receipt "$TX_HASH" --json | jq -r '.status')
if [ "$TX_STATUS" != "0x1" ]; then
    echo "Transaction failed with status: $TX_STATUS"
    cast receipt "$TX_HASH" --json | jq .
    kill $ANVIL_PID
    exit 1
fi

# Get event signature
EVENT_SIG=$(cast keccak "OrderCreated(bytes32)")
# Extract order key from topics[1] (because event arg is indexed)
ORDER_KEY=$(cast receipt "$TX_HASH" --json | \
  jq -r --arg ADDR "$(echo $cnt | tr '[:lower:]' '[:upper:]')" \
        --arg SIG "$EVENT_SIG" \
        '.logs[] | select((.address|ascii_upcase)==$ADDR and .topics[0]==$SIG) | .topics[1]' \
  | head -n1)

if [ -z "$ORDER_KEY" ] || [ "$ORDER_KEY" = "null" ]; then
    echo "Failed to extract order key. Logs from contract:"
    cast receipt "$TX_HASH" --json | jq -r --arg ADDR "$(echo $cnt | tr '[:lower:]' '[:upper:]')" \
        '.logs[] | select((.address|ascii_upcase)==$ADDR)'
    #kill $ANVIL_PID
    exit 1
fi

echo "Order key: $ORDER_KEY"
# Simulate order with prices
echo "Simulating order with prices..."

INDEX_PRICE_MIN=600990405127
INDEX_PRICE_MAX=601054544971

# 10^(30-18) = 10^12 formatted as 12 decimal places, = approx. $3742.437801860489
ETH_PRICE_MIN=3693638120501195
ETH_PRICE_MAX=3693638120501195

# 10^(30-6) = 10^24 formatted as 24 decimal places, = approx. $1.00
USDC_PRICE_MIN=999896565056655350000000
USDC_PRICE_MAX=999896565056655350000000

TOKENS="[$index_token, $weth, $usdc]"
PRICES_MIN="[$INDEX_PRICE_MIN, $ETH_PRICE_MIN, $USDC_PRICE_MIN]"
PRICES_MAX="[$INDEX_PRICE_MAX, $ETH_PRICE_MAX, $USDC_PRICE_MAX]"

# First, call to get return values
echo "Calling simulateOrderWithPrices to get return values..."
CALL_RESULT=$(cast call \
  --rpc-url=$ARBITRUM_RPC_URL \
  $cnt "simulateOrderWithPrices(bytes32,address[],uint256[],uint256[])(bool,bytes)" \
  "$ORDER_KEY" "$TOKENS" "$PRICES_MIN" "$PRICES_MAX")

# Parse return values
SUCCESS=$(echo "$CALL_RESULT" | head -n1 | tr -d '\r\n')
REVERT_DATA=$(echo "$CALL_RESULT" | tail -n1 | tr -d '\r\n')

if [ "$SUCCESS" = "true" ]; then
  echo "Simulation succeeded"
else
  echo "Simulation failed"
  echo "Revert data: $REVERT_DATA"
fi