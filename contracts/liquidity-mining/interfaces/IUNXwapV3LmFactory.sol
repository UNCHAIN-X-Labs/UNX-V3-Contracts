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

    function transferReward(address to, uint256 amount) external;
    function createLmPool(address v3Pool) external returns (address lmPool);
    function list(address v3Pool) external returns (address lmPool);
    function delist(address v3Pool) external;
    function allocate(IUNXwapV3Manager.PoolAllocationParams[] calldata params) external;
    function setMaxAllocation(uint256 maxValue) external;
    function allocationOf(address v3Pool) external view returns (uint256 allocation);
    function halvingProtocol() external view returns (IHalvingProtocol);
}