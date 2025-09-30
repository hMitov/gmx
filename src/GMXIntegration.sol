pragma solidity ^0.8.30;

import {OracleUtils} from "gmx-synthetics/contracts/oracle/OracleUtils.sol";
import {Price} from "gmx-synthetics/contracts/price/Price.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// Remove the IMarket interface since the market token doesn't have these functions
/*
 * The GMX Interface is assembled from the GMX V2 protocol, found at <https://github.com/gmx-io/gmx-synthetics/tree/main/contracts>
 *
 * structs/enums:
 * OrderType: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/order/Order.sol#L12-L35>
 * DecreasePositionSwapType: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/order/Order.sol#L42-L47>
 * CreateOrderParams: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/order/IBaseOrderUtils.sol#L8-L27>
 * CreateOrderParamsAddresses: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/order/IBaseOrderUtils.sol#L29-L38>
 * CreateOrderParamsNumbers: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/order/IBaseOrderUtils.sol#L40-L57>
 *
 * fns:
 * SendWnt: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/router/BaseRouter.sol#L36-L41>
 * SendTokens: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/router/BaseRouter.sol#L42-L48>
 * CreateOrder: <https://github.com/gmx-io/gmx-synthetics/blob/66b5d7dbd4684d7612c9db6f6a3000be84fa2ff7/contracts/router/ExchangeRouter.sol#L229-L242>
 */
interface GMXInterface {
    enum OrderType {
        MarketSwap,
        LimitSwap,
        MarketIncrease,
        LimitIncrease,
        MarketDecrease,
        LimitDecrease,
        StopLossDecrease,
        Liquidation,
        StopIncrease
    }
    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool autoCancel;
        bytes32 referralCode;
    }

    struct CreateOrderParamsAddresses {
        address receiver;
        address cancellationReceiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 validFromTime;
    }

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(address token, address receiver, uint256 amount) external payable;

    function createOrder(CreateOrderParams calldata params) external payable returns (bytes32);

    function simulateExecuteOrder(bytes32 key, OracleUtils.SimulatePricesParams memory simulatedOracleParams)
        external
        payable;
}

contract GMXIntegration {
    address constant GMX_ORDER_VAULT = 0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5;
    address constant GMX_EXCHANGE_ROUTER = 0x602b805EedddBbD9ddff44A7dcBD46cb07849685;
    address constant GMX_ROUTER = 0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6;
    address constant GMX_MARKET_TOKEN = 0x9F159014CC218e942E9E9481742fE5BFa9ac5A2C;
    address constant GMX_ORACLE = 0x6D5F3c723002847B009D07Fe8e17d6958F153E4e;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    uint256 constant USDC_AMOUNT = 10e6;

    // Create order params addresses constants
    address constant FUNDS_RECEIVER = 0xfF7ABDFc247539016a87257fA144fB95447647d9;
    address constant CANCELLATION_RECEIVER = 0x0000000000000000000000000000000000000000;
    address constant CALLBACK_CONTRACT = 0x0000000000000000000000000000000000000000;
    address constant UI_FEE_RECEIVER = 0xff00000000000000000000000000000000000001;
    address constant GMX_MARKET = 0x450bb6774Dd8a756274E0ab4107953259d2ac541;

    // Create order params numbers constants
    uint256 constant SIZE_DELTA_USD = 10e30; // $10 USD position size
    uint256 constant TRIGGER_PRICE = 0;
    uint256 constant CALLBACK_GAS_LIMIT = 0;
    uint256 constant MIN_OUTPUT_AMOUNT = 0;
    uint256 constant VALID_FROM_TIME = 0;

    bytes4 constant END_OF_ORACLE_SIMULATION_SELECTOR = 0x4e48dcda;


    event OrderCreated(bytes32 indexed orderKey);

    function longETH(uint256 acceptablePrice, uint256 executionFee) public payable {
        GMXInterface gmxRouter = GMXInterface(GMX_EXCHANGE_ROUTER);
        gmxRouter.sendWnt{value: executionFee}(GMX_ORDER_VAULT, executionFee);

        IERC20(USDC).approve(GMX_ORDER_VAULT, USDC_AMOUNT);
        IERC20(USDC).approve(GMX_ROUTER, USDC_AMOUNT);
        gmxRouter.sendTokens(USDC, GMX_ORDER_VAULT, USDC_AMOUNT);

        address[] memory path = new address[](1);
        path[0] = GMX_MARKET_TOKEN;

        GMXInterface.CreateOrderParams memory params = GMXInterface.CreateOrderParams(
            GMXInterface.CreateOrderParamsAddresses(
                FUNDS_RECEIVER,
                CANCELLATION_RECEIVER,
                CALLBACK_CONTRACT,
                UI_FEE_RECEIVER,
                GMX_MARKET,
                USDC,
                path
            ),
            GMXInterface.CreateOrderParamsNumbers(
                SIZE_DELTA_USD,
                USDC_AMOUNT,
                TRIGGER_PRICE,
                acceptablePrice,
                executionFee,
                CALLBACK_GAS_LIMIT,
                MIN_OUTPUT_AMOUNT,
                VALID_FROM_TIME
            ),
            GMXInterface.OrderType(GMXInterface.OrderType.MarketIncrease),
            GMXInterface.DecreasePositionSwapType(GMXInterface.DecreasePositionSwapType.NoSwap),
            true,
            false,
            false,
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000000)
        );

        bytes32 key = gmxRouter.createOrder{value: executionFee}(params);
        emit OrderCreated(key);
    }

    function simulateOrderWithPrices(
        bytes32 key,
        address[] calldata tokens,
        uint256[] calldata minPrices,
        uint256[] calldata maxPrices
    ) external returns (bool success, bytes memory revertData) {
        require(tokens.length == minPrices.length && tokens.length == maxPrices.length, "len mismatch");

        Price.Props[] memory primaryPrices = new Price.Props[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            primaryPrices[i] = Price.Props({min: minPrices[i], max: maxPrices[i]});
        }

        OracleUtils.SimulatePricesParams memory sp = OracleUtils.SimulatePricesParams({
            primaryTokens: tokens,
            primaryPrices: primaryPrices,
            minTimestamp: block.timestamp,
            maxTimestamp: block.timestamp + 50
        });

        (bool ok, bytes memory data) = GMX_EXCHANGE_ROUTER.call(
            abi.encodeWithSelector(
                GMXInterface.simulateExecuteOrder.selector,
                key,
                sp
            )
        );

        if (ok) {
            return (true, "");
        } else {
            // real revert - decode the error
            if (data.length >= 4) {
                bytes4 selector = bytes4(data);
                if (selector == END_OF_ORACLE_SIMULATION_SELECTOR) { 
                    return (true, "");
                }
            }
            return (false, data);
        }
    }
}
