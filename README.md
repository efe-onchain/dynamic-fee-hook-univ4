# DynamicFeeHook Contract

## Overview

The `DynamicFeeHook` is a custom hook contract designed for use with Uniswap v4 or compatible decentralized exchanges (DEXs) that incorporate a pool manager with dynamic liquidity provider (LP) fees. This contract integrates with an external `IVolatilityOracle` to calculate the swap fees based on the market's realized volatility.

## Key Features

- **Volatility-Driven Fees**: The primary feature of this contract is its dynamic fee calculation system. Swap fees are adjusted based on the realized volatility reported by the external oracle, allowing liquidity providers to earn higher fees during periods of increased volatility.
- **Periodic Fee Updates**: The swap fee is recalculated at regular intervals to ensure the fee remains responsive to market conditions without being excessively volatile.
- **Compatibility with Uniswap v4 Hooks**: This contract extends the base `BaseHook` provided by Uniswap v4, making it compatible with its hook system and pool management infrastructure.

## Fee Calculation System

### Volatility-Based Fee Adjustment

The fee for each swap is calculated dynamically using the following formula:

```
Fee = (Realized Volatility * max(uint24)) / max(uint256)
```

Where:

- **Realized Volatility**: This is retrieved from an external oracle (`IVolatilityOracle`). It represents the percentage volatility in the market.
- **`VOLATILITY_MULTIPLIER`**: A constant multiplier (set to `100` in this case) defines how much the volatility impacts the final fee. This means that for every 1% volatility, the swap fee increases by 0.01%.
- **`type(uint24).max`**: The maximum possible value for a `uint24`, representing the upper bound for the swap fee.

### Example

If the realized volatility is 2%, the fee would be:

```
Fee = (2% * uint24.max) / uint256.max
```

This allows the swap fee to scale proportionally with market conditions.

### Dynamic Fee Updates

To ensure fees remain relevant to market conditions without constantly recalculating, the contract updates fees only at specified intervals:

- **Fee Update Interval**: Fees are updated every hour (`FEE_UPDATE_INTERVAL` set to `1 hour`).
- **Timestamp Tracking**: The contract stores the `lastFeeUpdate` timestamp to ensure fees are recalculated only when this interval has passed.

When a swap occurs, the contract checks if the time since the last update exceeds the `FEE_UPDATE_INTERVAL`. If it does, the new fee is recalculated using the latest volatility data from the oracle. Otherwise, the previous fee remains in effect.

## Core Methods

### `getFee()`

- **Description**: Calculates the current swap fee based on the realized volatility from the oracle.
- **Returns**: A `uint24` value representing the dynamically calculated fee.

### `beforeSwap()`

- **Description**: This hook is triggered before every swap. It checks if the fee needs to be updated based on the `FEE_UPDATE_INTERVAL` and updates the fee accordingly.
- **Returns**:
  - Selector for the hook method.
  - A `BeforeSwapDelta` struct (in this case, set to zero).
  - The updated fee, if recalculated, or zero if no update is needed.

### `afterInitialize()`

- **Description**: This hook is called after the pool is initialized. It sets the initial fee for the pool based on the current volatility.

## Contract Structure

- **BaseHook**: This contract inherits from Uniswap's `BaseHook`, enabling it to interact with Uniswap’s pool management system.
- **IPoolManager**: The contract uses the `IPoolManager` to manage the liquidity pools and update the dynamic LP fees.
- **IVolatilityOracle**: The contract relies on an external volatility oracle that provides market volatility data.

## Deployment Parameters

- **`_poolManager`**: The address of the Uniswap-compatible `IPoolManager` that manages liquidity pools.
- **`_volatilityOracle`**: The address of the `IVolatilityOracle` that provides the realized volatility data for the fee calculation.

## Summary

The `DynamicFeeHook` contract brings an innovative mechanism to dynamically adjust swap fees based on real-time market volatility. This benefits liquidity providers by allowing fees to scale with market conditions, especially during times of high volatility, ensuring that they are appropriately compensated. Meanwhile, traders experience fair fees based on current market conditions.

By leveraging periodic updates and a robust fee calculation system, this contract offers a sophisticated approach to managing LP fees in decentralized exchanges.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
