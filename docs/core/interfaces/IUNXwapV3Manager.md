# Solidity API

## IUNXwapV3Manager

### PoolAllocationParams

```solidity
struct PoolAllocationParams {
  address v3Pool;
  uint256 allocation;
}
```

### ProtocolFeeParams

```solidity
struct ProtocolFeeParams {
  address v3Pool;
  uint8 feeProtocol0;
  uint8 feeProtocol1;
}
```

### CollectProtocolFeeParams

```solidity
struct CollectProtocolFeeParams {
  address v3Pool;
  uint128 amount0;
  uint128 amount1;
}
```

### CollectDeployFee

```solidity
event CollectDeployFee(address deployer, address collector, address feeToken, uint256 fee)
```

### SetLmPactory

```solidity
event SetLmPactory(address lmPactory)
```

### SetDeployFeeToken

```solidity
event SetDeployFeeToken(address token)
```

### SetDeployFeeCollector

```solidity
event SetDeployFeeCollector(address collector)
```

### SetDeployable

```solidity
event SetDeployable(bool trueOrFalse)
```

### SetDeployFee

```solidity
event SetDeployFee(address token, uint256 fee)
```

### SetLmPool

```solidity
event SetLmPool(address v3Pool, address lmPool)
```

### SetNfpManager

```solidity
event SetNfpManager(address nfpManager)
```

### SetProtocolFeeCollector

```solidity
event SetProtocolFeeCollector(address collector)
```

### createPool

```solidity
function createPool(address tokenA, address tokenB, address payer, uint24 fee, uint256 requiredDeployFee) external returns (address v3Pool, address lmPool)
```

Creates a {UNXwapV3Pool} and {UNXwapV3LmPool}.

_If {deployable} is false, should only executed by owner, else anyone should executed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenA | address | One of the two tokens in the desired pool. |
| tokenB | address | The other of the two tokens in the desired pool. |
| payer | address | The address of payer. |
| fee | uint24 | The desired fee for the pool. |
| requiredDeployFee | uint256 | The deploy fee required by payer. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of the newly created {UNXwapV3Pool}. |
| lmPool | address | The address of the newly created {UNXwapV3LmPool}. |

### list

```solidity
function list(address v3Pool) external returns (address lmPool)
```

Lists for liquidity mining.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of {UNXwapV3Pool}. |

### delist

```solidity
function delist(address v3Pool) external
```

Delists from liquidity mining.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| v3Pool | address | The address of {UNXwapV3Pool}. |

### allocate

```solidity
function allocate(struct IUNXwapV3Manager.PoolAllocationParams[] params) external
```

Sets the liquidity mining reward allocation for {UNXwapV3LmPool}.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IUNXwapV3Manager.PoolAllocationParams[] | The array of {PoolAllocationParams} |

### setFactoryOwner

```solidity
function setFactoryOwner(address owner_) external
```

Sets {UNXwapV3Factory}'s owner.

_Should only executed by owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | The address of owner. |

### setLmFactory

```solidity
function setLmFactory(address lmFactory_) external
```

Sets {UNXwapV3LmFactory}

_Should only executed by owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lmFactory_ | address | The address of {UNXwapV3LmFactory}. |

### setDeployFeeToken

```solidity
function setDeployFeeToken(address token) external
```

Sets the address of token required for create pool fees.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The address of token. |

### setDeployFeeCollector

```solidity
function setDeployFeeCollector(address collector) external
```

Sets the address of deploy fee collector.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collector | address | The address of collector. |

### setDeployable

```solidity
function setDeployable(bool deployable_) external
```

Sets whether pool creation is open to the public.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployable_ | bool | whether pool creation is open to the public. |

### setDeployFee

```solidity
function setDeployFee(uint256 fee) external
```

Sets the fee amount for create pool.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee | uint256 | The fee amount. |

### setFeeProtocol

```solidity
function setFeeProtocol(struct IUNXwapV3Manager.ProtocolFeeParams[] params) external
```

Sets protocol fee amount of {UNXwapV3Pool}

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IUNXwapV3Manager.ProtocolFeeParams[] | The array of {ProtocolFeeParams} |

### setMaxAllocation

```solidity
function setMaxAllocation(uint256 maxValue) external
```

Sets the maximum allocation of all {UNXwapV3LmPool}.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| maxValue | uint256 | the maximum allocation (apply 2 decimals, 100.00 % => 10000). |

### setNfpManager

```solidity
function setNfpManager(address nfpManager_) external
```

Sets {NonfungiblePositionManager}.

_Should only executed by owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nfpManager_ | address | The address of {NonfungiblePositionManager}. |

### setProtocolFeeCollector

```solidity
function setProtocolFeeCollector(address collector) external
```

Sets the address of protocol fee collector.

_Should only executed by owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collector | address | The address of collector. |

### collectProtocol

```solidity
function collectProtocol(struct IUNXwapV3Manager.CollectProtocolFeeParams[] params) external returns (struct IUNXwapV3Manager.CollectProtocolFeeParams[] result)
```

Collect the protocol fee accrued to the pool.

_Should only executed by {protocolFeeCollector}._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IUNXwapV3Manager.CollectProtocolFeeParams[] | The array of {CollectProtocolFeeParams}. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| result | struct IUNXwapV3Manager.CollectProtocolFeeParams[] | The array of {CollectProtocolFeeParams}. |

### enableFeeAmount

```solidity
function enableFeeAmount(uint24 fee, int24 tickSpacing) external
```

Enables a fee amount with the given tickSpacing.

_Should only executed by owner or executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee | uint24 | The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6). |
| tickSpacing | int24 | The spacing between ticks to be enforced for all pools created with the given fee amount. |

### factory

```solidity
function factory() external view returns (contract IUniswapV3Factory)
```

Returns {IUniswapV3Factory}.

### lmFactory

```solidity
function lmFactory() external view returns (contract IUNXwapV3LmFactory)
```

Returns {IUNXwapV3LmFactory}.

### deployFeeToken

```solidity
function deployFeeToken() external view returns (address)
```

Returns the token address required for create pool fees.

### deployFeeCollector

```solidity
function deployFeeCollector() external view returns (address)
```

Returns the address of {deployFee} collector.

### deployable

```solidity
function deployable() external view returns (bool)
```

Returns whether pool creation is open to the public.

### deployFee

```solidity
function deployFee() external view returns (uint256)
```

Returns the pool creation fee amount.

### nfpManager

```solidity
function nfpManager() external view returns (address)
```

Returns the address of {NonFungiblePositionManager}.

### protocolFeeCollector

```solidity
function protocolFeeCollector() external view returns (address)
```

Returns the address of protocol fee collector.

