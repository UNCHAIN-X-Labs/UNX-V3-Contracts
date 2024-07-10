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
    event Activate();
    event Deactivate();

    /**
     * @notice Accumulate reward.
     * @dev Should only executed by {NonfungiblePositionManager} or {UNXwapV3LmFactory} or {UNXwapV3Pool}.
     */
    function accumulateReward() external;

    /**
     * @notice Syncs with LmTick
     * @param tick The destination tick of the transition.
     * @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0.
     */
    function crossLmTick(int24 tick, bool zeroForOne) external;

    /**
     * @notice Updates liquidity of the position.
     * @dev Should only executed by {NonfungiblePositionManager}.
     * @param user The address of user.
     * @param tokenId The token ID of the position.
     */
    function updateLiquidity(address user, uint256 tokenId) external;

    /**
     * @notice Returns reward growth data.
     * @param tickLower The lower tick boundary of the position.
     * @param tickUpper The upper tick boundary of the position.
     */
    function getRewardGrowthInside(int24 tickLower, int24 tickUpper) external view returns (uint256 rewardGrowthInsideX128);

    /**
     * @notice Activate liquidity mining.
     * @dev Should only executed by {UNXwapV3LmFactory}.
     */
    function activate() external;

    /**
     * @notice Deactivate liquidity mining.
     * @dev Should only executed by {UNXwapV3LmFactory}.
     */
    function deactivate() external;

    /**
     * @notice Sets the liquidity mining reward allocation.
     * @dev Should only executed by {UNXwapV3LmFactory}.
     * @param alloc The reward allocation.
     */
    function setAllocation(uint256 alloc) external;

    /**
     * @notice Collect the reward.
     * @dev Should only executed by {NonfungiblePositionManager}.
     * @param tokenId The token ID of the position.
     * @return reward The amount to harvested.
     */
    function harvest(uint256 tokenId) external returns (uint256 reward);

    /**
     * @notice Returns {IUNXwapV3Pool}.
     */
    function v3Pool() external view returns (IUNXwapV3Pool);

    /**
     * @notice Returns the activation status.
     */
    function actived() external view returns (bool);

    /**
     * @notice Returns the reward allocation.
     */
    function allocation() external view returns (uint256);
}
