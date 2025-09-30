# GMX V2 Integration

A Solidity integration for GMX V2 protocol that enables automated order creation and simulation for ETH long positions using USDC collateral on Arbitrum.

## Features

- **Automated Order Creation**: Create GMX MarketIncrease orders for ETH long positions
- **Order Simulation**: Simulate order execution with custom oracle price data
- **USDC Collateral Support**: Full integration with USDC as collateral token
- **Arbitrum Native**: Built specifically for Arbitrum network
- **Automated Testing**: Complete test suite with real GMX protocol interaction
- **Price Oracle Integration**: Custom price simulation for order testing

## Contract Overview

### `GMXIntegration.sol`

The main contract provides two core functions:

- **`longETH()`**: Creates a complete GMX order for ETH long position
  - Sends execution fee to GMX Order Vault
  - Approves and transfers USDC collateral
  - Creates MarketIncrease order with predefined parameters
  - Emits `OrderCreated` event with order key

- **`simulateOrderWithPrices(bytes32 key, address[] tokens, uint256[] minPrices, uint256[] maxPrices)`**: Simulates order execution
  - Takes order key and price data as input
  - Returns success status and revert data
  - Handles GMX oracle simulation properly
  - Note: `EndOfOracleSimulation()` revert indicates successful simulation

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Anvil](https://book.getfoundry.sh/anvil/) for local testing
- Arbitrum RPC access

### Setup

1. **Clone and setup**:
   ```bash
   git clone https://github.com/hMitov/gmx.git
   cd gmx
   forge install
   ```

2. **Start local Arbitrum fork**:
   ```bash
   anvil --fork-url https://api.zan.top/arb-one --fork-block-number 365839831   
   ```

3. **Run the complete test**:
   ```bash
   chmod +x test_simulateExecuteOrder.sh
   ./test_simulateExecuteOrder.sh
   ```

## Usage

The contract automatically handles the complete order creation process. See the test scripts for working examples.

## Test Scripts

### `test_simulateExecuteOrder.sh`

This is the main test script that demonstrates the full workflow:

1. **Deploy Contract**: Creates GMXIntegration instance
2. **Fund with USDC**: Swaps 30 ETH for USDC via Uniswap V2
3. **Create Order**: Calls `longETH()` to create GMX order
4. **Extract Order Key**: Parses transaction logs for order key
5. **Simulate Order**: Tests order execution with custom prices

**Usage**:
```bash
# Start anvil first
   anvil --fork-url https://api.zan.top/arb-one --fork-block-number 365839831   

# Run the complete test
./test_simulateExecuteOrder.sh
```

### `test_longETH.sh`

Basic test that only creates an order without simulation:

```bash
./test_longETH.sh
```

## Configuration

### Network Settings

- **Arbitrum Mainnet**: `https://arb1.arbitrum.io/rpc`
- **Local Fork**: `http://localhost:8545`

### Contract Addresses (Arbitrum)

```solidity
GMX_ORDER_VAULT = 0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5
GMX_EXCHANGE_ROUTER = 0x602b805EedddBbD9ddff44A7dcBD46cb07849685
GMX_ROUTER = 0x7452c558d45f8afc8c83dAe62C3f8A5BE19c71f6
GMX_MARKET = 0x450bb6774Dd8a756274E0ab4107953259d2ac541
GMX_MARKET_TOKEN = 0x9F159014CC218e942E9E9481742fE5BFa9ac5A2C
USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
```

### Order Parameters

- **Position Size**: $10 USD
- **Collateral**: 10 USDC
- **Execution Fee**: 0.00093189148 ETH
- **Acceptable Price**: $3742.437801860489

## Development

```bash
# Compile
forge build

# Deploy
forge create --private-key=<PRIVATE_KEY> --rpc-url=<RPC_URL> src/GMXIntegration.sol:GMXIntegration
```

## Troubleshooting

- **Transaction Reverts**: Ensure contract has USDC balance
- **Insufficient Gas**: Increase gas limit for complex operations
- **Price Simulation Fails**: Check price data format and token addresses

## License

UNLICENSED

---

**Disclaimer**: This integration is for educational and testing purposes only. Always test thoroughly before using with real funds on mainnet.