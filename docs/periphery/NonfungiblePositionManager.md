# Solidity API

## NonfungiblePositionManager

Wraps UNXwap V3 positions in the ERC721 non-fungible token interface

### Position

```solidity
struct Position {
  uint96 nonce;
  address operator;
  uint80 poolId;
  int24 tickLower;
  int24 tickUpper;
  uint128 liquidity;
  uint256 feeGrowthInside0LastX128;
  uint256 feeGrowthInside1LastX128;
  uint128 tokensOwed0;
  uint128 tokensOwed1;
}
```

### HarvestParams

```solidity
struct HarvestParams {
  address v3Pool;
  uint256 tokenId;
}
```

### owner

```solidity
address owner
```

_The address of contract owner._

### OwnerChanged

```solidity
event OwnerChanged(address oldOwner, address newOwner)
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### nonReentrant

```solidity
modifier nonReentrant()
```

### constructor

```solidity
constructor(address _factory, address _WETH9, string uri) public
```

### positions

```solidity
function positions(uint256 tokenId) external view returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1)
```

Returns the position information associated with a given token ID.

_Throws if the token ID is not valid._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that represents the position |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| nonce | uint96 | The nonce for permits |
| operator | address | The address that is approved for spending |
| token0 | address | The address of the token0 for a specific pool |
| token1 | address | The address of the token1 for a specific pool |
| fee | uint24 | The fee associated with the pool |
| tickLower | int24 | The lower end of the tick range for the position |
| tickUpper | int24 | The higher end of the tick range for the position |
| liquidity | uint128 | The liquidity of the position |
| feeGrowthInside0LastX128 | uint256 | The fee growth of token0 as of the last action on the individual position |
| feeGrowthInside1LastX128 | uint256 | The fee growth of token1 as of the last action on the individual position |
| tokensOwed0 | uint128 | The uncollected amount of token0 owed to the position as of the last computation |
| tokensOwed1 | uint128 | The uncollected amount of token1 owed to the position as of the last computation |

### mint

```solidity
function mint(struct INonfungiblePositionManager.MintParams params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Creates a new position wrapped in a NFT

_Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
a method does not exist, i.e. the pool is assumed to be initialized._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.MintParams | The params necessary to mint a position, encoded as `MintParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that represents the minted position |
| liquidity | uint128 | The amount of liquidity for this position |
| amount0 | uint256 | The amount of token0 |
| amount1 | uint256 | The amount of token1 |

### isAuthorizedForToken

```solidity
modifier isAuthorizedForToken(uint256 tokenId)
```

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string)
```

### increaseLiquidity

```solidity
function increaseLiquidity(struct INonfungiblePositionManager.IncreaseLiquidityParams params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1)
```

Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.IncreaseLiquidityParams | tokenId The ID of the token for which liquidity is being increased, amount0Desired The desired amount of token0 to be spent, amount1Desired The desired amount of token1 to be spent, amount0Min The minimum amount of token0 to spend, which serves as a slippage check, amount1Min The minimum amount of token1 to spend, which serves as a slippage check, deadline The time by which the transaction must be included to effect the change |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The new liquidity amount as a result of the increase |
| amount0 | uint256 | The amount of token0 to acheive resulting liquidity |
| amount1 | uint256 | The amount of token1 to acheive resulting liquidity |

### decreaseLiquidity

```solidity
function decreaseLiquidity(struct INonfungiblePositionManager.DecreaseLiquidityParams params) external payable returns (uint256 amount0, uint256 amount1)
```

Decreases the amount of liquidity in a position and accounts it to the position

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.DecreaseLiquidityParams | tokenId The ID of the token for which liquidity is being decreased, amount The amount by which liquidity will be decreased, amount0Min The minimum amount of token0 that should be accounted for the burned liquidity, amount1Min The minimum amount of token1 that should be accounted for the burned liquidity, deadline The time by which the transaction must be included to effect the change |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of token0 accounted to the position's tokens owed |
| amount1 | uint256 | The amount of token1 accounted to the position's tokens owed |

### collect

```solidity
function collect(struct INonfungiblePositionManager.CollectParams params) external payable returns (uint256 amount0, uint256 amount1)
```

Collects up to a maximum amount of fees owed to a specific position to the recipient

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.CollectParams | tokenId The ID of the NFT for which tokens are being collected, recipient The account that should receive the tokens, amount0Max The maximum amount of token0 to collect, amount1Max The maximum amount of token1 to collect |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of fees collected in token0 |
| amount1 | uint256 | The amount of fees collected in token1 |

### burn

```solidity
function burn(uint256 tokenId) external payable
```

Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
must be collected first.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that is being burned |

### _getAndIncrementNonce

```solidity
function _getAndIncrementNonce(uint256 tokenId) internal returns (uint256)
```

_Gets the current nonce for a token ID and then increments it, returning the original value_

### getApproved

```solidity
function getApproved(uint256 tokenId) public view returns (address)
```

_Returns the account approved for `tokenId` token.

Requirements:

- `tokenId` must exist._

### _approve

```solidity
function _approve(address to, uint256 tokenId) internal
```

_Overrides _approve to use the operator in the position, which is packed with the position permit nonce_

### setOwner

```solidity
function setOwner(address _owner) external
```

### setTokenDescriptor

```solidity
function setTokenDescriptor(address tokenDescriptor) external
```

### harvestBatch

```solidity
function harvestBatch(struct NonfungiblePositionManager.HarvestParams[] params) external returns (uint256 reward)
```

Transfer reward to position owners in batch.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct NonfungiblePositionManager.HarvestParams[] | The array of {HarvestParams} |

### _updateLmPostion

```solidity
function _updateLmPostion(contract IUNXwapV3Pool pool, uint256 tokenId) internal
```

Synchronize the updated postion information with LmPool Position.

_This function should be called when any update liquidity._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IUNXwapV3Pool | The IUNXwapV3Pool interface |
| tokenId | uint256 | The token ID of position |

