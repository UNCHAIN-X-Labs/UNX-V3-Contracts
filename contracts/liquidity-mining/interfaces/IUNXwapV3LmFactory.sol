// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './IHalvingProtocol.sol';
import '../../core/interfaces/IUNXwapV3Manager.sol';

interface IUNXwapV3LmFactory {
    struct ListingInfo {
        address v3Pool;
        uint256 allocation;
    }

    event CreateLmPool(address indexed v3Pool, address indexed lmPool);
    event Listing(address indexed v3Pool, address indexed lmPool);
    event Delisting(address indexed v3Pool, address indexed lmPool);
    event Allocate(address indexed lmPool, uint256 allocation);
    event SetMaxAllocation(uint256 oldValue, uint256 newValue);

    /**
     * @notice Transfer reward to receiver.
     * @dev Should only executed by {UNXwapV3LmPool}.
     * @param to The address of receiver.
     * @param amount The amount of reward.
     */
    function transferReward(address to, uint256 amount) external;

    /**
     * @notice Create a {UNXwapV3LmPool}.
     * @dev Should only executed by {UNXwapV3Manager}.
     * @param v3Pool The address of {UNXwapV3Pool}.
     * @return lmPool The address of {UNXwapV3LmPool}.
     */
    function createLmPool(address v3Pool) external returns (address lmPool);

    /**
     * @notice Lists for liquidity mining.
     * @dev Should only executed by {UNXwapV3Manager}.
     * @param v3Pool The address of {UNXwapV3Pool}.
     * @return lmPool The address of {UNXwapV3LmPool}.
     */
    function list(address v3Pool) external returns (address lmPool);

    /**
     * @notice Delists from liquidity mining.
     * @dev Should only executed by {UNXwapV3Manager}.
     * @param v3Pool The address of {UNXwapV3Pool}.
     */
    function delist(address v3Pool) external;

    /**
     * @notice Sets the liquidity mining reward allocation for {UNXwapV3LmPool}.
     * @dev Should only executed by {UNXwapV3Manager}.
     * @param params The array of {PoolAllocationParams}
     */
    function allocate(IUNXwapV3Manager.PoolAllocationParams[] calldata params) external;

    /**
     * @notice Sets the maximum allocation of all {UNXwapV3LmPool}.
     * @dev Should only executed by {UNXwapV3Manager}.
     * @param maxValue the maximum allocation (apply 2 decimals, 100.00 % => 10000).
     */
    function setMaxAllocation(uint256 maxValue) external;

    /**
     * @notice Returns the allocation of a specific {UNXwapV3Pool}.
     * @param v3Pool The address of {UNXwapV3Pool}.
     * @return allocation The allocation of {UNXwapV3Pool}.
     */
    function allocationOf(address v3Pool) external view returns (uint256 allocation);

    /**
     * @notice Return {IHalvingProtocol}.
     */
    function halvingProtocol() external view returns (IHalvingProtocol);
    
    /**
     * @notice Returns listed pools information.
     */
    function listedPools() external view returns (ListingInfo[] memory result);
}