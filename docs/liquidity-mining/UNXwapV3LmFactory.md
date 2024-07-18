# Solidity API

## UNXwapV3LmFactory

_{UNXwapV3LmFactory} includes comprehensive management logic for liquidity mining pools,such as creating, activating/deactivating LmPools, and allocating rewards.
Its execution functions cannot be called independently and can only be executed by the UNXwapV3Manager._

### halvingProtocol

```solidity
contract IHalvingProtocol halvingProtocol
```

Return {IHalvingProtocol}.

### nonfungiblePositionManager

```solidity
contract INonfungiblePositionManager nonfungiblePositionManager
```

### v3Manager

```solidity
address v3Manager
```

### maxListing

```solidity
uint256 maxListing
```

### lmPools

```solidity
mapping(address => address) lmPools
```

### totalAllocation

```solidity
uint256 totalAllocation
```

### maxAllocation

```solidity
uint256 maxAllocation
```

### onlyManager

```solidity
modifier onlyManager()
```

### allocationLimiter

```solidity
modifier allocationLimiter()
```

### constructor

```solidity
constructor(address halving, address nfpManager, address v3Manager_, uint256 maxAllocation_, uint256 maxListing_) public
```

### transferReward

```solidity
function transferReward(address to, uint256 reward) external
```

Transfer reward to receiver.

_Should only executed by {UNXwapV3LmPool}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of receiver. |
| reward | uint256 |  |

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
function allocationOf(address lmPool) public view returns (uint256 allocation)
```

Returns the allocation of a specific {UNXwapV3Pool}.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lmPool | address |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allocation | uint256 | The allocation of {UNXwapV3Pool}. |

### listedPools

```solidity
function listedPools() public view returns (struct IUNXwapV3LmFactory.ListingInfo[] result)
```

Returns listed pools information.

### _setAllocation

```solidity
function _setAllocation(address lmPool, uint256 allocation) internal
```

Sets allocation of {UNXwapV3LmPool}.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lmPool | address | The address of {UNXwapV3LmPool}. |
| allocation | uint256 | The reward allocation (apply 2 decimals, 100.00 % => 10000). |

### _isListed

```solidity
function _isListed(address v3Pool) internal view returns (bool)
```

Validation of listing for liquidity mining.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of {UNXwapV3Pool}. |

