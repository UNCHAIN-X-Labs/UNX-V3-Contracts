# Solidity API

## UNXwapV3Factory

Deploys Uniswap V3 pools and manages ownership and control over pool protocol fees

### owner

```solidity
address owner
```

Returns the current owner of the factory

_Can be changed by the current owner via setOwner_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### feeAmountTickSpacing

```solidity
mapping(uint24 => int24) feeAmountTickSpacing
```

Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled

_A fee amount can never be removed, so this value should be hard coded or cached in the calling context_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### getPool

```solidity
mapping(address => mapping(address => mapping(uint24 => address))) getPool
```

Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist

_tokenA and tokenB may be passed in either token0/token1 or token1/token0 order_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### onlyOwner

```solidity
modifier onlyOwner()
```

### constructor

```solidity
constructor() public
```

UNX-Custom: UNXwapV3Factory should be deploy from UNXwapV3FactoryManager.

### createPool

```solidity
function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool)
```

Creates a pool for the given two tokens and fee

_tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
are invalid._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenA | address | One of the two tokens in the desired pool |
| tokenB | address | The other of the two tokens in the desired pool |
| fee | uint24 | The desired fee for the pool |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the newly created pool |

### setOwner

```solidity
function setOwner(address _owner) external
```

Updates the owner of the factory

_Must be called by the current owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _owner | address | The new owner of the factory |

### enableFeeAmount

```solidity
function enableFeeAmount(uint24 fee, int24 tickSpacing) public
```

Enables a fee amount with the given tickSpacing

_Fee amounts may never be removed once enabled_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee | uint24 | The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6) |
| tickSpacing | int24 | The spacing between ticks to be enforced for all pools created with the given fee amount |

