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
    
    struct ProtocolFeeParams {
        address v3Pool;
        uint8 feeProtocol0;
        uint8 feeProtocol1;
    }

    struct CollectProtocolFeeParams {
        address v3Pool;
        uint128 amount0;
        uint128 amount1;
    }

    event CollectDeployFee(address indexed deployer, address indexed collector, address indexed feeToken, uint256 fee);
    event SetLmPactory(address lmPactory);
    event SetDeployFeeToken(address token);
    event SetDeployFeeCollector(address collector);
    event SetDeployable(bool trueOrFalse);
    event SetDeployFee(address indexed token, uint256 fee);
    event SetLmPool(address indexed v3Pool, address indexed lmPool);
    event SetNfpManager(address nfpManager);
    event SetProtocolFeeCollector(address collector);

    /**
     * @notice Creates a {UNXwapV3Pool} and {UNXwapV3LmPool}.
     * @dev If {deployable} is false, should only executed by owner, else anyone should executed.
     * @param tokenA One of the two tokens in the desired pool.
     * @param tokenB The other of the two tokens in the desired pool.
     * @param payer The address of payer.
     * @param fee The desired fee for the pool.
     * @param requiredDeployFee The deploy fee required by payer.
     * @return v3Pool The address of the newly created {UNXwapV3Pool}.
     * @return lmPool The address of the newly created {UNXwapV3LmPool}.
     */
    function createPool(address tokenA, address tokenB, address payer, uint24 fee, uint256 requiredDeployFee) external returns (address v3Pool, address lmPool);

    /**
     * @notice Lists for liquidity mining.
     * @dev Should only executed by owner or executor.
     * @param v3Pool The address of {UNXwapV3Pool}.
     */
    function list(address v3Pool) external returns (address lmPool);

    /**
     * @notice Delists from liquidity mining.
     * @dev Should only executed by owner or executor.
     * @param v3Pool The address of {UNXwapV3Pool}.
     */
    function delist(address v3Pool) external;

    /**
     * @notice Sets the liquidity mining reward allocation for {UNXwapV3LmPool}.
     * @dev Should only executed by owner or executor.
     * @param params The array of {PoolAllocationParams}
     */
    function allocate(PoolAllocationParams[] calldata params) external;

    /**
     * @notice Sets {UNXwapV3Factory}'s owner.
     * @dev Should only executed by owner.
     * @param owner_ The address of owner.
     */
    function setFactoryOwner(address owner_) external;

    /**
     * @notice Sets {UNXwapV3LmFactory}
     * @dev Should only executed by owner.
     * @param lmFactory_ The address of {UNXwapV3LmFactory}.
     */
    function setLmFactory(address lmFactory_) external;

    /**
     * @notice Sets the address of token required for create pool fees.
     * @dev Should only executed by owner or executor.
     * @param token The address of token.
     */
    function setDeployFeeToken(address token) external;

    /**
     * @notice Sets the address of deploy fee collector.
     * @dev Should only executed by owner or executor.
     * @param collector The address of collector.
     */
    function setDeployFeeCollector(address collector) external;

    /**
     * @notice Sets whether pool creation is open to the public.
     * @dev Should only executed by owner or executor.
     * @param deployable_ whether pool creation is open to the public.
     */
    function setDeployable(bool deployable_) external;

    /**
     * @notice Sets the fee amount for create pool.
     * @dev Should only executed by owner or executor.
     * @param fee The fee amount.
     */
    function setDeployFee(uint256 fee) external;

    /**
     * @notice Sets protocol fee amount of {UNXwapV3Pool}
     * @dev Should only executed by owner or executor.
     * @param params The array of {ProtocolFeeParams}
     */
    function setFeeProtocol(ProtocolFeeParams[] calldata params) external;

    /**
     * @notice Sets the maximum allocation of all {UNXwapV3LmPool}.
     * @dev Should only executed by owner or executor.
     * @param maxValue the maximum allocation (apply 2 decimals, 100.00 % => 10000).
     */
    function setMaxAllocation(uint256 maxValue) external;

    /**
     * @notice Sets {NonfungiblePositionManager}.
     * @dev Should only executed by owner.
     * @param nfpManager_ The address of {NonfungiblePositionManager}.
     */
    function setNfpManager(address nfpManager_) external;
    
    /**
     * @notice Sets the address of protocol fee collector.
     * @dev Should only executed by owner.
     * @param collector The address of collector.
     */
    function setProtocolFeeCollector(address collector) external;

    /**
     * @notice Collect the protocol fee accrued to the pool.
     * @dev Should only executed by {protocolFeeCollector}.
     * @param params The array of {CollectProtocolFeeParams}.
     * @return result The array of {CollectProtocolFeeParams}.
     */
    function collectProtocol(CollectProtocolFeeParams[] calldata params) external returns (CollectProtocolFeeParams[] memory result);

    /**
     * @notice Enables a fee amount with the given tickSpacing.
     * @dev Should only executed by owner or executor.
     * @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6).
     * @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount.
     */
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

    /**
     * @notice Returns {IUniswapV3Factory}.
     */
    function factory() external view returns (IUniswapV3Factory);

    /**
     * @notice Returns {IUNXwapV3LmFactory}.
     */
    function lmFactory() external view returns (IUNXwapV3LmFactory);

    /**
     * @notice Returns the token address required for create pool fees.
     */
    function deployFeeToken() external view returns (address);

    /**
     * @notice Returns the address of {deployFee} collector.
     */
    function deployFeeCollector() external view returns (address);

    /**
     * @notice Returns whether pool creation is open to the public.
     */
    function deployable() external view returns (bool);

    /**
     * @notice Returns the pool creation fee amount.
     */
    function deployFee() external view returns (uint256);

    /**
     * @notice Returns the address of {NonFungiblePositionManager}.
     */
    function nfpManager() external view returns (address);

    /**
     * @notice Returns the address of protocol fee collector.
     */
    function protocolFeeCollector() external view returns (address);
}