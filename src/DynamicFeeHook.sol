// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";

interface IVolatilityOracle {
    function realizedVolatility() external view returns (uint256);
    function latestTimestamp() external view returns (uint256);
}

contract DynamicFeeHook is BaseHook {
    uint256 public constant VOLATILITY_MULTIPLIER = 100; // 0.01% fee per 1% volatility

    IVolatilityOracle public immutable volatilityOracle;
    uint256 public lastFeeUpdate;
    uint256 public constant FEE_UPDATE_INTERVAL = 1 hours;

    constructor(
        IPoolManager _poolManager,
        IVolatilityOracle _volatilityOracle
    ) BaseHook(_poolManager) {
        volatilityOracle = _volatilityOracle;
    }
    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: true,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function getFee() public view returns (uint24) {
        uint256 realizedVolatility = volatilityOracle.realizedVolatility();
        uint24 fee = uint24(
            (realizedVolatility * type(uint24).max) / type(uint256).max
        );
        return fee;
    }

    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24,
        bytes calldata
    ) external override returns (bytes4) {
        uint24 initialFee = getFee();
        poolManager.updateDynamicLPFee(key, initialFee);
        return DynamicFeeHook.afterInitialize.selector;
    }

    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        if (block.timestamp >= lastFeeUpdate + FEE_UPDATE_INTERVAL) {
            uint24 newFee = getFee();
            lastFeeUpdate = block.timestamp;
            return (
                IHooks.beforeSwap.selector,
                BeforeSwapDeltaLibrary.ZERO_DELTA,
                newFee | LPFeeLibrary.OVERRIDE_FEE_FLAG
            );
        }
        return (
            IHooks.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }
}
