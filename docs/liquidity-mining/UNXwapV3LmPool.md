# Solidity API

## UNXwapV3LmPool

_{UNXwapV3LmPool} is the contract that actually manages reward information for each liquidity position.
It only accumulates rewards when the mining pool is active, and no rewards are accumulated if the liquidity is zero.
Rewards that are not accumulated while the pool is active will remain permanently locked in the HalvingProtocol and will not circulate in the market._

### REWARD_PRECISION

```solidity
uint256 REWARD_PRECISION
```

### Q128

```solidity
uint256 Q128
```

### v3Pool

```solidity
contract IUNXwapV3Pool v3Pool
```

Returns {IUNXwapV3Pool}.

### nonfungiblePositionManager

```solidity
contract INonfungiblePositionManager nonfungiblePositionManager
```

### halvingProtocol

```solidity
contract IHalvingProtocol halvingProtocol
```

### lmFactory

```solidity
contract IUNXwapV3LmFactory lmFactory
```

### lmLiquidity

```solidity
uint128 lmLiquidity
```

### lastUpdateBlock

```solidity
uint256 lastUpdateBlock
```

### lastActivedBlock

```solidity
uint256 lastActivedBlock
```

### rewardGrowthGlobalX128

```solidity
uint256 rewardGrowthGlobalX128
```

### allocation

```solidity
uint256 allocation
```

Returns the reward allocation.

### actived

```solidity
bool actived
```

Returns the activation status.

### lmTicks

```solidity
mapping(int24 => struct LmTick.Info) lmTicks
```

### positionRewardInfos

```solidity
mapping(uint256 => struct IUNXwapV3LmPool.PositionRewardInfo) positionRewardInfos
```

### onlyPool

```solidity
modifier onlyPool()
```

### onlyNFPManager

```solidity
modifier onlyNFPManager()
```

### onlyLmFactory

```solidity
modifier onlyLmFactory()
```

### onlyNFPManagerOrLmFactoryOrV3Pool

```solidity
modifier onlyNFPManagerOrLmFactoryOrV3Pool()
```

### whenActived

```solidity
modifier whenActived()
```

### constructor

```solidity
constructor(address v3Pool_, address nfpManager, address halving) public
```

### accumulateReward

```solidity
function accumulateReward() public
```

Accumulate reward.

_Should only executed by {NonfungiblePositionManager} or {UNXwapV3LmFactory} or {UNXwapV3Pool}._

### crossLmTick

```solidity
function crossLmTick(int24 tick, bool zeroForOne) external
```

Syncs with LmTick

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tick | int24 | The destination tick of the transition. |
| zeroForOne | bool | The direction of the swap, true for token0 to token1, false for token1 to token0. |

### harvest

```solidity
function harvest(uint256 tokenId) external returns (uint256 reward)
```

Collect the reward.

_Should only executed by {NonfungiblePositionManager}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token ID of the position. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| reward | uint256 | The amount to harvested. |

### updateLiquidity

```solidity
function updateLiquidity(address user, uint256 tokenId) external
```

Updates liquidity of the position.

_Should only executed by {NonfungiblePositionManager}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of user. |
| tokenId | uint256 | The token ID of the position. |

### activate

```solidity
function activate() external
```

Activate liquidity mining.

_Should only executed by {UNXwapV3LmFactory}._

### deactivate

```solidity
function deactivate() external
```

Deactivate liquidity mining.

_Should only executed by {UNXwapV3LmFactory}._

### setAllocation

```solidity
function setAllocation(uint256 alloc) external
```

Sets the liquidity mining reward allocation.

_Should only executed by {UNXwapV3LmFactory}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| alloc | uint256 | The reward allocation. |

### getRewardGrowthInside

```solidity
function getRewardGrowthInside(int24 tickLower, int24 tickUpper) public view returns (uint256 rewardGrowthInsideX128)
```

Returns reward growth data.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick boundary of the position. |
| tickUpper | int24 | The upper tick boundary of the position. |

### currentRewardPerBlock

```solidity
function currentRewardPerBlock() public view returns (uint256 reward)
```

Returns the reward per block of {UNXwapV3LmPool} for the current halving cycle.

### rewardPerBlockOf

```solidity
function rewardPerBlockOf(uint256 halvingNum) public view returns (uint256 reward)
```

Returns the reward per block of {UNXwapV3LmPool} for a specific halving cycle.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| halvingNum | uint256 | The halving number |

### _calculateReward

```solidity
function _calculateReward(uint256 rewardGrowthInside, uint128 liquidity, uint256 tokenId) internal view returns (uint256 reward)
```

Calculates the reward of the position.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| rewardGrowthInside | uint256 | The reward growth data. |
| liquidity | uint128 | The liquidity of the positoin. |
| tokenId | uint256 | The token ID of the position. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| reward | uint256 | The reward of the position. |

### _harvestOperation

```solidity
function _harvestOperation(int24 tickLower, int24 tickUpper, uint256 tokenId, address to) internal returns (uint256 reward)
```

Transfers or updates reward of the position.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick boundary of the position. |
| tickUpper | int24 | The upper tick boundary of the position. |
| tokenId | uint256 | The token ID of the position. |
| to | address | The address of receiver. |

### _updatePosition

```solidity
function _updatePosition(int24 tickLower, int24 tickUpper, int128 liquidityDelta) internal
```

Updates the position.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick boundary of the position. |
| tickUpper | int24 | The upper tick boundary of the position. |
| liquidityDelta | int128 | The change in pool liquidity as a result of the position update. |

