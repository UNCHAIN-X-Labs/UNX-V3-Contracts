// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './IUniswapV3Pool.sol';
import '../../liquidity-mining/interfaces/IUNXwapV3LmPool.sol';

interface IUNXwapV3Pool is IUniswapV3Pool {
    /// @notice The IUNXwapV3LmPool interface that deployed the lmPool
    /// @return The IUNXwapV3LmPool interface
    function lmPool() external view returns (IUNXwapV3LmPool);

    /// @notice Set {lmPool}
    /// @param lmPool_ The contract address of lmPool
    function setLmPool(address lmPool_) external;
}