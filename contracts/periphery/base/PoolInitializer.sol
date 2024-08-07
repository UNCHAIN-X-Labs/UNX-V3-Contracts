// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '../../core/interfaces/IUniswapV3Factory.sol';
import '../../core/interfaces/IUniswapV3Pool.sol';
import '../../core/interfaces/IUNXwapV3Manager.sol';

import './PeripheryImmutableState.sol';
import '../interfaces/IPoolInitializer.sol';

/// @title Creates and initializes V3 Pools
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96,
        uint256 requiredDeployFee
    ) external payable override returns (address pool) {
        require(token0 < token1);
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            (pool, ) = IUNXwapV3Manager(IUniswapV3Factory(factory).owner()).createPool(token0, token1, msg.sender, fee, requiredDeployFee);
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
}
