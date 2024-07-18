# Solidity API

## IUNXwapV3LmFactory

### ListingInfo

```solidity
struct ListingInfo {
  address v3Pool;
  uint256 allocation;
}
```

### CreateLmPool

```solidity
event CreateLmPool(address v3Pool, address lmPool)
```

### Listing

```solidity
event Listing(address v3Pool, address lmPool)
```

### Delisting

```solidity
event Delisting(address v3Pool, address lmPool)
```

### Allocate

```solidity
event Allocate(address lmPool, uint256 allocation)
```

### SetMaxAllocation

```solidity
event SetMaxAllocation(uint256 oldValue, uint256 newValue)
```

### transferReward

```solidity
function transferReward(address to, uint256 amount) external
```

Transfer reward to receiver.

_Should only executed by {UNXwapV3LmPool}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of receiver. |
| amount | uint256 | The amount of reward. |

### createLmPool

```solidity
function createLmPool(address v3Pool) external returns (address lmPool)
```

Create a {UNXwapV3LmPool}.

_Should only executed by {UNXwapV3Manager}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of {UNXwapV3Pool}. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| lmPool | address | The address of {UNXwapV3LmPool}. |

### list

```solidity
function list(address v3Pool) external returns (address lmPool)
```

Lists for liquidity mining.

_Should only executed by {UNXwapV3Manager}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of {UNXwapV3Pool}. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| lmPool | address | The address of {UNXwapV3LmPool}. |

### delist

```solidity
function delist(address v3Pool) external
```

Delists from liquidity mining.

_Should only executed by {UNXwapV3Manager}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of {UNXwapV3Pool}. |

### allocate

```solidity
function allocate(struct IUNXwapV3Manager.PoolAllocationParams[] params) external
```

Sets the liquidity mining reward allocation for {UNXwapV3LmPool}.

_Should only executed by {UNXwapV3Manager}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IUNXwapV3Manager.PoolAllocationParams[] | The array of {PoolAllocationParams} |

### setMaxAllocation

```solidity
function setMaxAllocation(uint256 maxValue) external
```

Sets the maximum allocation of all {UNXwapV3LmPool}.

_Should only executed by {UNXwapV3Manager}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| maxValue | uint256 | the maximum allocation (apply 2 decimals, 100.00 % => 10000). |

### allocationOf

```solidity
function allocationOf(address v3Pool) external view returns (uint256 allocation)
```

Returns the allocation of a specific {UNXwapV3Pool}.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of {UNXwapV3Pool}. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allocation | uint256 | The allocation of {UNXwapV3Pool}. |

### halvingProtocol

```solidity
function halvingProtocol() external view returns (contract IHalvingProtocol)
```

Return {IHalvingProtocol}.

### listedPools

```solidity
function listedPools() external view returns (struct IUNXwapV3LmFactory.ListingInfo[] result)
```

Returns listed pools information.

