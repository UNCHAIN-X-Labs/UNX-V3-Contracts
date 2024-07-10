// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

interface IHalvingProtocol {
    struct HalvingOptions {
        address token;
        uint256 genesisBlock;
        uint256 totalNum;
        uint256 halvingInterval;
        uint256 initRewardPerDay;
        uint256 totalSupply;
    }

    event SetOperator(address indexed operator, bool trueOrFalse);

    /**
     * @notice Grant operator permissions.
     * @dev Should only executed by owner. 
     * @param account The address of operator.
     * @param trueOrFalse Permission granting.
     */
    function setOperator(address account, bool trueOrFalse) external;

    /**
     * @notice Transfer reward to receiver.
     * @dev Should only executed by contracts managing LmFactory or UNX rewards.
     * @param to The address of receiver.
     * @param amount The amount of reward.
     */
    function transferReward(address to, uint256 amount) external;

    /**
     * @notice Returns genesis block number for mining.
     */
    function genesisBlock() external view returns (uint256);

    /**
     * @notice Returns end block number for mining.
     */
    function endBlock() external view returns (uint256);

    /**
     * @notice Returns the reward per block for the current halving cycle.
     */
    function currentRewardPerBlock() external view returns (uint256 reward);

    /**
     * @notice Returns all halving blocks.
     */
    function halvingBlocks() external view returns (uint256[] memory blocks);

    /**
     * @notice Returns total supply for mining.
     */    
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the total mining amount before LastHalving.
     */
    function calculateTotalMiningBeforeLastHalving() external view returns (uint256 totalMining);

    /**
     * @notice Returns the reward per block for a specific halving cycle.
     * @param halvingNum The halving number
     */
    function rewardPerBlockOf(uint256 halvingNum) external view returns (uint256 reward);

}