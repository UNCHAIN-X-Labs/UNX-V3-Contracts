// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './IUniswapV3Pool.sol';
import '../../liquidity-mining/interfaces/IUNXwapV3LmPool.sol';

interface IUNXwapV3Pool is IUniswapV3Pool {
    function lmPool() external view returns (IUNXwapV3LmPool);
    function setLmPool(address lmPool_) external;
}