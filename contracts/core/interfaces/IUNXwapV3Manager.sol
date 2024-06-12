// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './IUniswapV3Factory.sol';
import '../../periphery/interfaces/INonfungiblePositionManager.sol';
import '../../liquidity-mining/interfaces/IUNXwapV3LmFactory.sol';

interface IUNXwapV3Manager {
    struct PoolAllocationParams {
        address v3Pool;
        uint256 allocation;
    }

    event CollectDeployFee(address indexed deployer, address indexed collector, address indexed feeToken, uint256 fee);

    function createPool(address tokenA, address tokenB, address payer, uint24 fee) external returns (address v3Pool, address lmPool);
    function list(address v3Pool) external returns (address lmPool);
    function delist(address v3Pool) external;
    function allocate(PoolAllocationParams[] calldata params) external;

    function setFactoryOwner(address owner_) external;

    function setLmFactory(address lmFactory_) external;
    function setLmPool(address v3Pool, address lmPool) external;

    function setDeployFeeToken(address token) external;
    function setDeployFeeCollector(address collector) external;
    function setDeployable(bool deployable_) external;
    function setDeployFee(uint256 fee) external;
    function setFeeProtocol(address v3Pool, uint8 feeProtocol0, uint8 feeProtocol1) external;
    function collectProtocol(address v3Pool, address collector, uint128 amount0Requested, uint128 amount1Requested) external returns (uint128 amount0, uint128 amount1);

    function factory() external view returns (IUniswapV3Factory);
    function lmFactory() external view returns (IUNXwapV3LmFactory);
    function deployFeeToken() external view returns (address);
    function deployFeeCollector() external view returns (address);
    function deployable() external view returns (bool);
    function deployFee() external view returns (uint256);
}