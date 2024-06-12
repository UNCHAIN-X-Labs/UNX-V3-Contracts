// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../../core/interfaces/IUNXwapV3Pool.sol';

interface IUNXwapV3LmPool {
    struct PositionRewardInfo {
        uint256 liquidity;
        uint256 rewardGrowthInside;
        uint256 reward;
        bool flag;
    }

    event UpdateLiquidity(
        address indexed user,
        uint256 indexed tokenId,
        int128 liquidity,
        int24 tickLower,
        int24 tickUpper
    );

    event Harvest(address indexed to, uint256 indexed tokenId, uint256 reward);

    function accumulateReward() external;
    function crossLmTick(int24 tick, bool zeroForOne) external;
    function updateLiquidity(address user, uint256 tokenId) external;
    function getRewardGrowthInside(int24 tickLower, int24 tickUpper) external view returns (uint256 rewardGrowthInsideX128);

    function activate() external;
    function deactivate() external;
    function setAllocation(uint256 alloc) external;
    function harvest(uint256 tokenId) external returns (uint256 reward);

    function v3Pool() external view returns (IUNXwapV3Pool);
    function actived() external view returns (bool);
    function allocation() external view returns (uint256);
}
