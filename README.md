# GMX V2 Integration

A Solidity integration for GMX V2 protocol that enables order creation and simulation for ETH long positions with USDC collateral.

## Features

- ✅ **Order Creation**: Create GMX orders for ETH long positions
- ✅ **Order Simulation**: Simulate order execution with custom price data
- ✅ **USDC Collateral**: Support for USDC as collateral token
- ✅ **Arbitrum Integration**: Built for Arbitrum network
- ✅ **Test Scripts**: Automated testing and simulation scripts

## Contract Overview

### `GMXIntegration.sol`

Main contract that provides:

- **`longETH(uint256 executionFee, uint256 acceptablePrice)`**: Creates a long ETH position order
- **`createOrderAndGetKey(uint256 executionFee, uint256 acceptablePrice)`**: Creates order and returns the order key
- **`simulateOrderWithPrices(bytes32 key, address[] tokens, uint256[] minPrices, uint256[] maxPrices)`**: Simulates order execution with custom price data

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Anvil](https://book.getfoundry.sh/anvil/) for local testing
- Arbitrum RPC access

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/hMitov/gmx.git
   cd gmx
   ```

2. **Install dependencies**:
   ```bash
   forge install
   ```

3. **Start local Arbitrum fork**:
   ```bash
   anvil --fork-url=https://api.zan.top/arb-one --fork-block-number=365839831
   ```

4. **Run tests**:
   ```bash
   ./test_simulateExecuteOrder.sh
   ```

## Usage

### Creating an Order

```solidity
// Deploy the contract
GMXIntegration integration = new GMXIntegration();

// Create a long ETH order
uint256 executionFee = 93189148000000; // 0.00093189148 ETH
uint256 acceptablePrice = 2100000000000000000000000000000; // $2100
bytes32 orderKey = integration.createOrderAndGetKey(executionFee, acceptablePrice);
```

### Simulating an Order

```solidity
// Define price data
address[] memory tokens = [WETH, USDC];
uint256[] memory minPrices = [1990000000000000000000000000000, 1000000000000000000000000000];
uint256[] memory maxPrices = [2010000000000000000000000000000, 1000000000000000000000000000];

// Simulate the order
(bool success, string memory reason) = integration.simulateOrderWithPrices(
    orderKey,
    tokens,
    minPrices,
    maxPrices
);
```

## Test Scripts

### `test_simulateExecuteOrder.sh`

Complete end-to-end test that:
1. Deploys the contract
2. Funds it with USDC
3. Creates an order
4. Simulates the order execution

**Usage**:
```bash
# Start anvil first
anvil --fork-url=https://api.zan.top/arb-one --fork-block-number=365839831

# Run the test
./test_simulateExecuteOrder.sh
```

### `test_longETH.sh`

Simple test for order creation only.

## Configuration

### Network Settings

- **Arbitrum Mainnet**: `https://api.zan.top/arb-one`
- **Local Fork**: `http://localhost:8545`

### Contract Addresses

```solidity
GMX_ORDER_VAULT = 0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5
GMX_EXCHANGE_ROUTER = 0x602b805EedddBbD9ddff44a7dcBD46cb07849685
GMX_ROUTER = 0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6
GMX_MARKET = 0x450bb6774Dd8a756274E0ab4107953259d2ac541
USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
```

## Price Data Format

All prices are scaled to 30 decimals (1e30):

```solidity
// ETH price: $2000
uint256 ethPrice = 2000000000000000000000000000000;

// USDC price: $1.00
uint256 usdcPrice = 1000000000000000000000000000000;
```

## Error Handling

The simulation function returns detailed error information:

- **Success**: `(true, "")`
- **GMX Error**: `(false, "specific error message")`
- **General Failure**: `(false, "Simulation failed")`

## Development

### Compiling

```bash
forge build
```

### Testing

```bash
forge test
```

### Deployment

```bash
forge create --private-key=<PRIVATE_KEY> --rpc-url=<RPC_URL> src/GMXIntegration.sol:GMXIntegration
```

## Dependencies

- **GMX Synthetics**: `lib/gmx-synthetics` (submodule)
- **Forge Std**: `lib/forge-std` (submodule)
- **OpenZeppelin**: `lib/openzeppelin-contracts` (submodule)

## License

UNLICENSED

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For issues and questions, please open an issue on GitHub.

---

**Note**: This integration is for educational and testing purposes. Always test thoroughly before using with real funds.