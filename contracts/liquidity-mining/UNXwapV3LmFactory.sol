// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import './interfaces/IUNXwapV3LmFactory.sol';
import './interfaces/IHalvingProtocol.sol';
import './interfaces/IUNXwapV3LmPool.sol';
import '../common/CommonAuth.sol';
import './UNXwapV3LmPool.sol';

/**
 * @title UNXwapV3LmFactory
 * @dev {UNXwapV3LmFactory} includes comprehensive management logic for liquidity mining pools,such as creating, activating/deactivating LmPools, and allocating rewards.
 * Its execution functions cannot be called independently and can only be executed by the UNXwapV3Manager.
 */
contract UNXwapV3LmFactory is IUNXwapV3LmFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc IUNXwapV3LmFactory
    IHalvingProtocol public immutable override halvingProtocol;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    address public immutable v3Manager;
    uint256 public immutable maxListing;

    EnumerableSet.AddressSet private listedV3Pools;

    mapping(address => address) public lmPools;

    uint256 public totalAllocation;
    uint256 public maxAllocation;

    modifier onlyManager() {
        require(msg.sender == v3Manager, "Caller is unauthorized");
        _;
    }

    modifier allocationLimiter() {
        _;
        require(totalAllocation <= maxAllocation, 'Exceed allocation');
    }

    constructor(address halving, address nfpManager, address v3Manager_, uint256 maxAllocation_, uint256 maxListing_) {
        _validateCodeSize(halving);
        _validateCodeSize(nfpManager);
        _validateCodeSize(v3Manager_);

        halvingProtocol = IHalvingProtocol(halving);
        nonfungiblePositionManager = INonfungiblePositionManager(nfpManager);
        v3Manager = v3Manager_;
        maxAllocation = maxAllocation_;
        maxListing = maxListing_;
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function transferReward(address to, uint256 reward) external override {
        require(msg.sender == lmPools[address(IUNXwapV3LmPool(msg.sender).v3Pool())], "LiquidityMiningFactory: caller is not LM Pool");
        require(to != address(0) && reward > 0);
        halvingProtocol.transferReward(to, reward);
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function createLmPool(address v3Pool) external override onlyManager returns (address lmPool) {
        require(lmPools[v3Pool] == address(0), "LiquidityMiningFactory: already created.");

        lmPool = address(new UNXwapV3LmPool{salt: keccak256(abi.encode(v3Pool, address(this)))}(v3Pool, address(nonfungiblePositionManager) , address(halvingProtocol)));
        require(lmPool != address(0));
        lmPools[v3Pool] = lmPool;

        emit CreateLmPool(v3Pool, lmPool);
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function list(address v3Pool) external override onlyManager returns (address lmPool) {
        _validateCodeSize(v3Pool);
        lmPool = lmPools[v3Pool];
        require(lmPool != address(0), "LiquidityMiningFactory: lmPool does not exist.");
        require(!_isListed(v3Pool), "LiquidityMiningFactory: already listed.");
        require(listedV3Pools.length() < maxListing, "LiquidityMiningFactory: exceed max.");

        UNXwapV3LmPool(lmPool).activate();
        listedV3Pools.add(v3Pool);

        emit Listing(v3Pool, lmPool);
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function delist(address v3Pool) external override onlyManager allocationLimiter {
        _validateCodeSize(v3Pool);
        address lmPool = lmPools[v3Pool];
        require(lmPool != address(0), "LiquidityMiningFactory: lmPool does not exist.");
        require(_isListed(v3Pool), "LiquidityMiningFactory: does not exist listed pool.");

        uint256 remains = allocationOf(lmPool);
        _setAllocation(lmPool, 0);
        UNXwapV3LmPool(lmPool).deactivate();
        listedV3Pools.remove(v3Pool);

        uint256 afLen = listedV3Pools.length();
        if(remains > 0 && afLen > 0) {
            uint256 divi = remains / afLen;
            for(uint256 i = 0; i < afLen; ++i) {
                _setAllocation(lmPools[listedV3Pools.at(i)], allocationOf(lmPools[listedV3Pools.at(i)]) + divi);
            }
        }

        emit Delisting(v3Pool, lmPool);
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function allocate(IUNXwapV3Manager.PoolAllocationParams[] calldata params) external override onlyManager allocationLimiter {
        for(uint256 i = 0; i < params.length; ++i) {
            _setAllocation(lmPools[params[i].v3Pool], params[i].allocation);
        }
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function setMaxAllocation(uint256 maxValue) external override onlyManager {
        require(maxValue >= totalAllocation, "LiquidityMiningFactory: Below limit");
        uint256 oldValue = maxAllocation;
        maxAllocation = maxValue;
        emit SetMaxAllocation(oldValue, maxValue);
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function allocationOf(address lmPool) public view override returns (uint256 allocation) {
        allocation = UNXwapV3LmPool(lmPool).allocation();
    }

    /// @inheritdoc IUNXwapV3LmFactory
    function listedPools() public override view returns (ListingInfo[] memory result) {
        uint256 len = listedV3Pools.length();
        result = new ListingInfo[](len);
        for (uint256 i = 0; i < len; ++i) {
            address v3Pool = listedV3Pools.at(i);
            result[i] = ListingInfo(v3Pool, allocationOf(lmPools[v3Pool]));
        }
    }

    /**
     * @notice Sets allocation of {UNXwapV3LmPool}.
     * @param lmPool The address of {UNXwapV3LmPool}.
     * @param allocation The reward allocation (apply 2 decimals, 100.00 % => 10000).
     */
    function _setAllocation(address lmPool, uint256 allocation) internal {
        uint256 oldAlloc = allocationOf(lmPool);
        totalAllocation -= oldAlloc;
        totalAllocation += allocation;

        UNXwapV3LmPool(lmPool).setAllocation(allocation);
        emit Allocate(lmPool, allocation);
    }

    /**
     * @notice Validation of listing for liquidity mining.
     * @param v3Pool The address of {UNXwapV3Pool}.
     */
    function _isListed(address v3Pool) internal view returns (bool) {
        return listedV3Pools.contains(v3Pool);
    }

    function _validateCodeSize(address addr) internal view {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        require(size > 0);
    }
}