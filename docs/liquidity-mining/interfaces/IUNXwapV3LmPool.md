# Solidity API

## IUNXwapV3LmPool

### PositionRewardInfo

```solidity
struct PositionRewardInfo {
  uint256 liquidity;
  uint256 rewardGrowthInside;
  uint256 reward;
  bool flag;
}
```

### UpdateLiquidity

```solidity
event UpdateLiquidity(address user, uint256 tokenId, int128 liquidity, int24 tickLower, int24 tickUpper)
```

### Harvest

```solidity
event Harvest(address to, uint256 tokenId, uint256 reward)
```

### Activate

```solidity
event Activate()
```

### Deactivate

```solidity
event Deactivate()
```

### accumulateReward

```solidity
function accumulateReward() external
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

### getRewardGrowthInside

```solidity
function getRewardGrowthInside(int24 tickLower, int24 tickUpper) external view returns (uint256 rewardGrowthInsideX128)
```

Returns reward growth data.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick boundary of the position. |
| tickUpper | int24 | The upper tick boundary of the position. |

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

### v3Pool

```solidity
function v3Pool() external view returns (contract IUNXwapV3Pool)
```

Returns {IUNXwapV3Pool}.

### actived

```solidity
function actived() external view returns (bool)
```

Returns the activation status.

### allocation

```solidity
function allocation() external view returns (uint256)
```

Returns the reward allocation.

