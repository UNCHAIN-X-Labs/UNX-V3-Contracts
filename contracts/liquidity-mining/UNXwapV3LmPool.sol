// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../core/libraries/LowGasSafeMath.sol';
import '../core/libraries/SafeCast.sol';
import '../core/libraries/FullMath.sol';
import '../core/libraries/FixedPoint128.sol';
import '../core/interfaces/IUNXwapV3Pool.sol';
import '../periphery/interfaces/INonfungiblePositionManager.sol';

import './libraries/LmTick.sol';
import './interfaces/IUNXwapV3LmFactory.sol';
import './interfaces/IUNXwapV3LmPool.sol';
import './interfaces/IHalvingProtocol.sol';

/**
 * @title UNXwapV3LmPool
 * @dev {UNXwapV3LmPool} is the contract that actually manages reward information for each liquidity position.
 * It only accumulates rewards when the mining pool is active, and no rewards are accumulated if the liquidity is zero.
 * Rewards that are not accumulated while the pool is active will remain permanently locked in the HalvingProtocol and will not circulate in the market.
 */
contract UNXwapV3LmPool is IUNXwapV3LmPool {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using LmTick for mapping(int24 => LmTick.Info);

    uint256 public constant REWARD_PRECISION = 1e12;
    uint256 constant Q128 = 0x100000000000000000000000000000000;

    /// @inheritdoc IUNXwapV3LmPool
    IUNXwapV3Pool public immutable override v3Pool;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IHalvingProtocol public immutable halvingProtocol;
    IUNXwapV3LmFactory public immutable lmFactory;

    uint128 public lmLiquidity;
    uint256 public lastUpdateBlock;
    uint256 public lastActivedBlock;
    uint256 public rewardGrowthGlobalX128;

    // apply 2 decimals. 100.00 % => 10000
    /// @inheritdoc IUNXwapV3LmPool
    uint256 public override allocation;
    /// @inheritdoc IUNXwapV3LmPool
    bool public override actived;

    mapping(int24 => LmTick.Info) public lmTicks;
    mapping(uint256 => PositionRewardInfo) public positionRewardInfos;

    modifier onlyPool() {
        require(msg.sender == address(v3Pool), "Only call by UNXwapV3Pool");
        _;
    }

    modifier onlyNFPManager() {
        require(msg.sender == address(nonfungiblePositionManager), "Only call by NonfungiblePositionManager");
        _;
    }

    modifier onlyLmFactory() {
        require(msg.sender == address(lmFactory), "Only call by UNXwapLmFactory");
        _;
    }

    modifier onlyNFPManagerOrLmFactoryOrV3Pool() {
        require(msg.sender == address(nonfungiblePositionManager)
            || msg.sender == address(lmFactory)
            || msg.sender == address(v3Pool),
            "Only call by UNXwapV3Pool or NonfungiblePositionManager or UNXwapLmFactory");
        _;
    }

    modifier whenActived() {
        require(actived, "lmPoo is not actived");
        _;
    }

    constructor(address v3Pool_, address nfpManager, address halving) {
        v3Pool = IUNXwapV3Pool(v3Pool_);
        nonfungiblePositionManager = INonfungiblePositionManager(nfpManager);
        halvingProtocol = IHalvingProtocol(halving);
        lmFactory = IUNXwapV3LmFactory(msg.sender);
    }

    /// @inheritdoc IUNXwapV3LmPool
    function accumulateReward() public override onlyNFPManagerOrLmFactoryOrV3Pool {
        uint256 genesisBlock = halvingProtocol.genesisBlock();
        uint256 currentBlock = block.number;

        if(currentBlock <= lastUpdateBlock || currentBlock <= genesisBlock) {
            return;
        }
        
        uint256 endBlock = actived ? halvingProtocol.endBlock()
            : lastActivedBlock > halvingProtocol.endBlock() ? halvingProtocol.endBlock() : lastActivedBlock;

        if(lmLiquidity != 0) {
            uint256 targetBlock = currentBlock > endBlock ? endBlock : currentBlock;
            uint256 lastestBlock = lastUpdateBlock < genesisBlock - 1 ? genesisBlock : lastUpdateBlock;

            if(lastestBlock >= targetBlock) {
                return;
            }

            uint256[] memory halvingBlocks = halvingProtocol.halvingBlocks();
            uint256 tmpUpdatedBlock = lastestBlock;

            for(uint256 i = 0; i < halvingBlocks.length; ++i) {
                if(halvingBlocks[i] > tmpUpdatedBlock && halvingBlocks[i] <= targetBlock) {
                    // Accumlate reward before halving
                    // before-halving duration (halvingBlocks[i] - tmpUpdatedBlock - 1)
                    rewardGrowthGlobalX128 += FullMath.mulDiv((halvingBlocks[i] - tmpUpdatedBlock - 1), FullMath.mulDiv(rewardPerBlockOf(i), FixedPoint128.Q128, REWARD_PRECISION), lmLiquidity);
                    tmpUpdatedBlock = halvingBlocks[i] - 1;
                }
            }

            // Accumlate reward after halving
            // after-halving duration (targetBlock - tmpUpdatedBlock)
            if(tmpUpdatedBlock < targetBlock) {
                rewardGrowthGlobalX128 += FullMath.mulDiv((targetBlock - tmpUpdatedBlock), FullMath.mulDiv(currentRewardPerBlock(), FixedPoint128.Q128, REWARD_PRECISION), lmLiquidity);
            }
        }
        
        lastUpdateBlock = currentBlock;
    }

    /// @inheritdoc IUNXwapV3LmPool
    function crossLmTick(int24 tick, bool zeroForOne) external override onlyPool {
        if(lmTicks[tick].liquidityGross == 0) {
            return;
        }

        int128 lmLiquidityNet = lmTicks.cross(tick, rewardGrowthGlobalX128);

        if (zeroForOne) {
            lmLiquidityNet = -lmLiquidityNet;
        }

        lmLiquidity = LiquidityMath.addDelta(lmLiquidity, lmLiquidityNet);
    }

    /// @inheritdoc IUNXwapV3LmPool
    function harvest(uint256 tokenId) external override onlyNFPManager returns (uint256 reward) {
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = nonfungiblePositionManager.positions(
            tokenId
        );
        // Update rewardGrowthInside
        accumulateReward();
        reward = _harvestOperation(tickLower, tickUpper, tokenId, nonfungiblePositionManager.ownerOf(tokenId));
    }

    /// @inheritdoc IUNXwapV3LmPool
    function updateLiquidity(address user, uint256 tokenId) external override onlyNFPManager {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(
            tokenId
        );

        // Update rewardGrowthInside
        accumulateReward();
        if(positionRewardInfos[tokenId].flag) {
             _harvestOperation(tickLower, tickUpper, tokenId, address(0));
        } else {
            positionRewardInfos[tokenId].flag = true;
        }

        int128 liquidityDelta = int128(liquidity) - int128(positionRewardInfos[tokenId].liquidity);
        positionRewardInfos[tokenId].liquidity = liquidity;

        if(liquidityDelta != 0) {
            _updatePosition(tickLower, tickUpper, liquidityDelta);
            // Update latest rewardGrowthInside
            positionRewardInfos[tokenId].rewardGrowthInside = getRewardGrowthInside(tickLower, tickUpper);
            emit UpdateLiquidity(user, tokenId, liquidityDelta, tickLower, tickUpper);
        }
    }

    /// @inheritdoc IUNXwapV3LmPool
    function activate() external override onlyLmFactory {
        require(!actived, "lmPool is already actived");
        actived = true;
        lastUpdateBlock = block.number;
        emit Activate();
    }

    /// @inheritdoc IUNXwapV3LmPool
    function deactivate() external override onlyLmFactory whenActived {
        delete actived;
        lastActivedBlock = block.number;
        emit Deactivate();
    }

    /// @inheritdoc IUNXwapV3LmPool
    function setAllocation(uint256 alloc) external override onlyLmFactory {
        require(actived);
        accumulateReward();
        allocation = alloc;
    }

    /// @inheritdoc IUNXwapV3LmPool
    function getRewardGrowthInside(int24 tickLower, int24 tickUpper) public view override returns (uint256 rewardGrowthInsideX128) {
        (, int24 tick, , , , ,) = v3Pool.slot0();
        return lmTicks.getRewardGrowthInside(tickLower, tickUpper, tick, rewardGrowthGlobalX128);
    }

    /**
     * @notice Returns the reward per block of {UNXwapV3LmPool} for the current halving cycle.
     */
    function currentRewardPerBlock() public view returns (uint256 reward) {
        reward = halvingProtocol.currentRewardPerBlock() * allocation / 10000;
    }

    /**
     * @notice Returns the reward per block of {UNXwapV3LmPool} for a specific halving cycle.
     * @param halvingNum The halving number
     */
    function rewardPerBlockOf(uint256 halvingNum) public view returns (uint256 reward) {
        reward = halvingProtocol.rewardPerBlockOf(halvingNum) * allocation / 10000;
    }

    /**
     * @notice Calculates the reward of the position.
     * @param rewardGrowthInside The reward growth data.
     * @param liquidity The liquidity of the positoin.
     * @param tokenId The token ID of the position.
     * @return reward The reward of the position.
     */
    function _calculateReward(uint256 rewardGrowthInside, uint128 liquidity, uint256 tokenId) internal view returns (uint256 reward) {
        uint256 rewardGrowthInsideDelta;
        rewardGrowthInsideDelta = rewardGrowthInside - positionRewardInfos[tokenId].rewardGrowthInside;
        reward = FullMath.mulDiv(rewardGrowthInsideDelta, liquidity, FixedPoint128.Q128) * REWARD_PRECISION;
        reward += positionRewardInfos[tokenId].reward;
    }

    /**
     * @notice Transfers or updates reward of the position.
     * @param tickLower The lower tick boundary of the position.
     * @param tickUpper The upper tick boundary of the position.
     * @param tokenId The token ID of the position.
     * @param to The address of receiver.
     */
    function _harvestOperation(int24 tickLower, int24 tickUpper, uint256 tokenId, address to) internal returns (uint256 reward) {
        uint256 rewardGrowthInside = getRewardGrowthInside(tickLower, tickUpper);
        reward = _calculateReward(rewardGrowthInside, uint128(positionRewardInfos[tokenId].liquidity), tokenId);
        positionRewardInfos[tokenId].rewardGrowthInside = rewardGrowthInside;

        if (reward > 0) {
            if (to != address(0)) {
                delete positionRewardInfos[tokenId].reward;
                lmFactory.transferReward(to, reward);
                emit Harvest(to, tokenId, reward);
            } else {
                positionRewardInfos[tokenId].reward = reward;
            }
        }
    }

    /**
     * @notice Updates the position.
     * @param tickLower The lower tick boundary of the position.
     * @param tickUpper The upper tick boundary of the position.
     * @param liquidityDelta The change in pool liquidity as a result of the position update.
     */
    function _updatePosition(int24 tickLower, int24 tickUpper, int128 liquidityDelta) internal {
        (, int24 tick, , , , ,) = v3Pool.slot0();
        uint128 maxLiquidityPerTick = v3Pool.maxLiquidityPerTick();
        uint256 _rewardGrowthGlobalX128 = rewardGrowthGlobalX128;

        bool flippedLower;
        bool flippedUpper;

        if(liquidityDelta != 0) {
            flippedLower = lmTicks.update(
                tickLower,
                tick,
                liquidityDelta,
                _rewardGrowthGlobalX128,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = lmTicks.update(
                tickUpper,
                tick,
                liquidityDelta,
                _rewardGrowthGlobalX128,
                true,
                maxLiquidityPerTick
            );
        }

        if(tick >= tickLower && tick < tickUpper) {
            lmLiquidity = LiquidityMath.addDelta(lmLiquidity, liquidityDelta);
        }

        if(liquidityDelta < 0) {
            if(flippedLower) {
                lmTicks.clear(tickLower);
            }
            if(flippedUpper) {
                lmTicks.clear(tickUpper);
            }
        }
    }
}