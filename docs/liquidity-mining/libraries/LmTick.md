# Solidity API

## LmTick

Contains functions for managing tick processes and relevant calculations

### Info

```solidity
struct Info {
  uint128 liquidityGross;
  int128 liquidityNet;
  uint256 rewardGrowthOutsideX128;
}
```

### getRewardGrowthInside

```solidity
function getRewardGrowthInside(mapping(int24 => struct LmTick.Info) self, int24 tickLower, int24 tickUpper, int24 tickCurrent, uint256 rewardGrowthGlobalX128) internal view returns (uint256 rewardGrowthInsideX128)
```

Retrieves reward growth data

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| self | mapping(int24 &#x3D;&gt; struct LmTick.Info) | The mapping containing all tick information for initialized ticks |
| tickLower | int24 | The lower tick boundary of the position |
| tickUpper | int24 | The upper tick boundary of the position |
| tickCurrent | int24 | The current tick |
| rewardGrowthGlobalX128 | uint256 | The all-time global reward growth, per unit of liquidity |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| rewardGrowthInsideX128 | uint256 | The all-time reward growth, per unit of liquidity, inside the position's tick boundaries |

### update

```solidity
function update(mapping(int24 => struct LmTick.Info) self, int24 tick, int24 tickCurrent, int128 liquidityDelta, uint256 rewardGrowthGlobalX128, bool upper, uint128 maxLiquidity) internal returns (bool flipped)
```

Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| self | mapping(int24 &#x3D;&gt; struct LmTick.Info) | The mapping containing all tick information for initialized ticks |
| tick | int24 | The tick that will be updated |
| tickCurrent | int24 | The current tick |
| liquidityDelta | int128 | A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left) |
| rewardGrowthGlobalX128 | uint256 | The all-time global reward growth, per unit of liquidity |
| upper | bool | true for updating a position's upper tick, or false for updating a position's lower tick |
| maxLiquidity | uint128 | The maximum liquidity allocation for a single tick |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flipped | bool | Whether the tick was flipped from initialized to uninitialized, or vice versa |

### clear

```solidity
function clear(mapping(int24 => struct LmTick.Info) self, int24 tick) internal
```

Clears tick data

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| self | mapping(int24 &#x3D;&gt; struct LmTick.Info) | The mapping containing all initialized tick information for initialized ticks |
| tick | int24 | The tick that will be cleared |

### cross

```solidity
function cross(mapping(int24 => struct LmTick.Info) self, int24 tick, uint256 rewardGrowthGlobalX128) internal returns (int128 liquidityNet)
```

Transitions to next tick as needed by price movement

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| self | mapping(int24 &#x3D;&gt; struct LmTick.Info) | The mapping containing all tick information for initialized ticks |
| tick | int24 | The destination tick of the transition |
| rewardGrowthGlobalX128 | uint256 | The all-time global reward growth, per unit of liquidity, in token0 |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidityNet | int128 | The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left) |

