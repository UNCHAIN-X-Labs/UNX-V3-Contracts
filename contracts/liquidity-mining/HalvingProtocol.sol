// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/IHalvingProtocol.sol';

/**
 * @title HalvingProtocol
 * @dev {HalvingProtocol} is responsible for calculating the block reward amount according to the UNX halving schedule.
 * The UNX halving occurs every {halvingInterval} blocks  from the {genesisBlock}.
 * After the final halving, mining will continue with a fixed reward(last reward amount halved) amount until the remaining supply is exhausted.
 */
contract HalvingProtocol is IHalvingProtocol, Ownable {
    /// @inheritdoc IHalvingProtocol
    uint256 public override genesisBlock;
    /// @inheritdoc IHalvingProtocol
    uint256 public override endBlock;
    /// @inheritdoc IHalvingProtocol
    uint256 public override totalSupply;

    uint256 public halvingInterval;
    uint256 public totalNum;
    uint256 public initRewardPerBlcok;
    uint256 public lastHalvingBlock;
    address public token;

    mapping(address => bool) public operators;

    constructor() Ownable() {}

    function initialize(HalvingOptions calldata options) external override onlyOwner {
        require(genesisBlock == 0, 'Only execute once.');
        require(options.genesisBlock != 0, 'The genesis block cannot be set to 0.');

        // Set halving options.
        token = options.token;
        genesisBlock = options.genesisBlock;
        halvingInterval = options.halvingInterval;
        totalNum = options.totalNum;
        initRewardPerBlcok = options.initRewardPerDay / 28800;
        lastHalvingBlock = options.genesisBlock + (options.halvingInterval * options.totalNum);
        totalSupply = options.totalSupply;

        uint256 totalMiningBeforeLastHalving;
        for(uint256 i = 0; i < options.totalNum; ++i) {
            totalMiningBeforeLastHalving += (options.halvingInterval * (options.initRewardPerDay / 28800 / (2 ** i)));
        }

        endBlock = options.genesisBlock + (options.halvingInterval * options.totalNum) + ((options.totalSupply - totalMiningBeforeLastHalving) / (options.initRewardPerDay / 28800 / (2 ** options.totalNum))) - 1;
    }

    /// @inheritdoc IHalvingProtocol
    function setOperator(address account, bool trueOrFalse) external override onlyOwner {
        // Operator should be LmFactory or Something rewarded with UNX.
        operators[account] = trueOrFalse;
        emit SetOperator(account, trueOrFalse);
    }

    /// @inheritdoc IHalvingProtocol
    function transferReward(address to, uint256 amount) external override {
        require(operators[msg.sender], "Halving: caller is unauthorized");
        IERC20(token).transfer(to, amount);
    }

    /// @inheritdoc IHalvingProtocol
    function rewardPerBlockOf(uint256 halvingNum) external view override returns (uint256 reward) {
        reward = initRewardPerBlcok / (2 ** halvingNum);
    }

    /// @inheritdoc IHalvingProtocol
    function currentRewardPerBlock() external view override returns (uint256 reward) {
        uint256 currentBlock = block.number;
        if(currentBlock < genesisBlock || currentBlock > endBlock) {
            return 0;
        }

        uint256 elapsedBlocks = currentBlock - genesisBlock;
        uint256 halvingNum = elapsedBlocks / halvingInterval;
        reward = halvingNum > totalNum ? initRewardPerBlcok / (2 ** totalNum) : initRewardPerBlcok / (2 ** halvingNum);
    }

    /// @inheritdoc IHalvingProtocol
    function halvingBlocks() external view override returns (uint256[] memory blocks) {
        blocks = new uint256[](totalNum);
        uint256 genesisBlock_ = genesisBlock;

        for(uint256 i = 0; i < totalNum; ++i) {
            blocks[i] = genesisBlock_ + (halvingInterval * (i + 1));
        }
    }

    /// @inheritdoc IHalvingProtocol
    function calculateTotalMiningBeforeLastHalving() public view override returns (uint256 totalMining) {
        for(uint256 i = 0; i < totalNum; ++i) {
            totalMining += (halvingInterval * (initRewardPerBlcok / (2 ** i)));
        }
    }
}