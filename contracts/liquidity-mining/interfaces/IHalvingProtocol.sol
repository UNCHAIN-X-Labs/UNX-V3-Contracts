// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

interface IHalvingProtocol {
    struct HalvingOptions {
        address token;
        uint256 genesisBlock;
        uint256 totalNum;
        uint256 halvingInterval;
        uint256 initReward;
        uint256 totalSupply;
    }

    function transferReward(address to, uint256 amount) external;
    function genesisBlock() external view returns (uint256);
    function endBlock() external view returns (uint256);
    function currentRewardPerBlock() external view returns (uint256 reward);
    function halvingBlocks() external view returns (uint256[] memory blocks);
    function totalSupply() external view returns (uint256);
    function calculateTotalMiningBeforeLastHalving() external view returns (uint256 totalMining);
    function rewardPerBlockOf(uint256 halvingNum) external view returns (uint256 reward);

}