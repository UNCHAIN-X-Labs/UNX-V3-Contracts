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

contract UNXwapV3LmPool is IUNXwapV3LmPool {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using LmTick for mapping(int24 => LmTick.Info);

    uint256 public constant REWARD_PRECISION = 1e12;
    uint256 constant Q128 = 0x100000000000000000000000000000000;

    IUNXwapV3Pool public immutable override v3Pool;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IHalvingProtocol public immutable halvingProtocol;
    IUNXwapV3LmFactory public immutable lmFactory;

    uint128 public lmLiquidity;
    uint256 public lastUpdateBlock;
    uint256 public lastActivedBlock;
    uint256 public rewardGrowthGlobalX128;

    // apply 2 decimals. 100.00 % => 10000
    uint256 public override allocation;
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

    modifier onlyNFPManagerOrLmFactory() {
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

    function accumulateReward() public override onlyNFPManagerOrLmFactory {
        uint256 genesisBlock = halvingProtocol.genesisBlock();
        uint256 currentBlock = block.number;

        if(currentBlock <= lastUpdateBlock || currentBlock <= genesisBlock) {
            return;
        }
        
        uint256 endBlock = actived ? halvingProtocol.endBlock() : lastActivedBlock;

        if(lmLiquidity != 0) {
            uint256 targetBlock = currentBlock > endBlock ? endBlock : currentBlock;
            uint256 lastestBlock = lastUpdateBlock < genesisBlock ? genesisBlock : lastUpdateBlock;

            if(lastestBlock >= targetBlock) {
                return;
            }

            uint256 duration = targetBlock - lastestBlock;
            if(duration > 0) {
                uint256[] memory halvingBlocks = halvingProtocol.halvingBlocks();
                uint256 tmpUpdatedBlock = lastestBlock;

                for(uint256 i = 0; i < halvingBlocks.length; i++) {
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

        }
        
        lastUpdateBlock = currentBlock;
    }

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

    function harvest(uint256 tokenId) external override onlyNFPManager returns (uint256 reward) {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(
            tokenId
        );
        // Update rewardGrowthInside
        accumulateReward();
        reward = _harvestOperation(tickLower, tickUpper, liquidity, tokenId, nonfungiblePositionManager.ownerOf(tokenId));
    }

    function updateLiquidity(address user, uint256 tokenId) external override onlyNFPManager {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(
            tokenId
        );

        // Update rewardGrowthInside
        accumulateReward();
        if(positionRewardInfos[tokenId].flag) {
             _harvestOperation(tickLower, tickUpper, liquidity, tokenId, address(0));
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

    function activate() external override onlyLmFactory {
        require(!actived, "lmPool is already actived");
        actived = true;
    }

    function deactivate() external override onlyLmFactory whenActived {
        actived = false;
        lastActivedBlock = block.number;
    }

    function setAllocation(uint256 alloc) external override onlyLmFactory {
        accumulateReward();
        allocation = alloc;
    }

    function getRewardGrowthInside(int24 tickLower, int24 tickUpper) public view override returns (uint256 rewardGrowthInsideX128) {
        (, int24 tick, , , , ,) = v3Pool.slot0();
        return lmTicks.getRewardGrowthInside(tickLower, tickUpper, tick, rewardGrowthGlobalX128);
    }

    function currentRewardPerBlock() public view returns (uint256 reward) {
        reward = halvingProtocol.currentRewardPerBlock() * allocation / 10000;
    }

    function rewardPerBlockOf(uint256 halvingNum) public view returns (uint256 reward) {
        reward = halvingProtocol.rewardPerBlockOf(halvingNum) * allocation / 10000;
    }

    function _calculateReward(uint256 rewardGrowthInside, uint128 liquidity, uint256 tokenId) internal view returns (uint256 reward) {
        uint256 rewardGrowthInsideDelta;
        rewardGrowthInsideDelta = rewardGrowthInside - positionRewardInfos[tokenId].rewardGrowthInside;
        reward = FullMath.mulDiv(rewardGrowthInsideDelta, liquidity, FixedPoint128.Q128) * REWARD_PRECISION;
        reward += positionRewardInfos[tokenId].reward;
    }

    function _harvestOperation(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 tokenId, address to) internal returns (uint256 reward) {
        uint256 rewardGrowthInside = getRewardGrowthInside(tickLower, tickUpper);
        reward = _calculateReward(rewardGrowthInside, liquidity, tokenId);
        positionRewardInfos[tokenId].rewardGrowthInside = rewardGrowthInside;

        if (reward > 0) {
            if (to != address(0)) {
                positionRewardInfos[tokenId].reward = 0;
                lmFactory.transferReward(to, reward);
                emit Harvest(to, tokenId, reward);
            } else {
                positionRewardInfos[tokenId].reward = reward;
            }
        }
    }

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