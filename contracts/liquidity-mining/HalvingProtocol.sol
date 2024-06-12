// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/IHalvingProtocol.sol';

contract HalvingProtocol is IHalvingProtocol, Ownable {
    uint256 public immutable override genesisBlock;
    uint256 public immutable halvingInterval;
    uint256 public immutable totalNum;
    uint256 public immutable initReward;
    uint256 public immutable lastHalvingBlock;
    uint256 public immutable override endBlock;
    uint256 public immutable override totalSupply;
    address public immutable token;
    address public operator;

    constructor(HalvingOptions memory options) Ownable() {
        // Set halving options.
        token = options.token;
        genesisBlock = options.genesisBlock;
        halvingInterval = options.halvingInterval;
        totalNum = options.totalNum;
        initReward = options.initReward;
        lastHalvingBlock = options.genesisBlock + (options.halvingInterval * options.totalNum);
        totalSupply = options.totalSupply;

        uint256 totalMiningBeforeLastHalving = 0;
        for(uint256 i = 0; i < options.totalNum; i++) {
            totalMiningBeforeLastHalving += (options.halvingInterval * (options.initReward / (2 ** i)));
        }

        endBlock = options.genesisBlock + (options.halvingInterval * options.totalNum) + ((options.totalSupply - totalMiningBeforeLastHalving) / (options.initReward / (2 ** options.totalNum))) - 1;
    }

    function setOperator(address account) external onlyOwner {
        // Operator should be LmFactory.
        operator = account;
    }

    function transferReward(address to, uint256 amount) external override {
        require(msg.sender == operator, "Halving: caller is unauthorized");
        IERC20(token).transfer(to, amount);
    }

    function rewardPerBlockOf(uint256 halvingCount) external view override returns (uint256 reward) {
        reward = initReward / (2 ** halvingCount) / 28800;
    }    

    function currentRewardPerBlock() external view override returns (uint256 reward) {
        uint256 currentBlock = block.number;
        if(currentBlock < genesisBlock || currentBlock > endBlock) {
            return 0;
        }

        uint256 elapsedBlocks = currentBlock - genesisBlock;
        uint256 halvingNum = elapsedBlocks / halvingInterval;
        reward = halvingNum > totalNum ? initReward / (2 ** totalNum) / 28800 : initReward / (2 ** halvingNum) / 28800;
    }

    function halvingBlocks() external view override returns (uint256[] memory blocks) {
        blocks = new uint256[](totalNum);
        uint256 genesisBlock_ = genesisBlock;

        for(uint256 i = 0; i < totalNum; i++) {
            blocks[i] = genesisBlock_ + (halvingInterval * (i + 1));
        }

        return blocks;
    }

    function calculateTotalMiningBeforeLastHalving() public view override returns (uint256 totalMining) {
        for(uint256 i = 0; i < totalNum; i++) {
            totalMining += (halvingInterval * (initReward / (2 ** i)));
        }
    }
}