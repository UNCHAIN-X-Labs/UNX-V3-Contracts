# Solidity API

## IHalvingProtocol

### HalvingOptions

```solidity
struct HalvingOptions {
  address token;
  uint256 genesisBlock;
  uint256 totalNum;
  uint256 halvingInterval;
  uint256 initRewardPerDay;
  uint256 totalSupply;
}
```

### SetOperator

```solidity
event SetOperator(address operator, bool trueOrFalse)
```

### initialize

```solidity
function initialize(struct IHalvingProtocol.HalvingOptions options) external
```

Initialize halving protocol options.

_It should only be called once by the owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| options | struct IHalvingProtocol.HalvingOptions | {HalvingOptions} |

### setOperator

```solidity
function setOperator(address account, bool trueOrFalse) external
```

Grant operator permissions.

_Should only executed by owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of operator. |
| trueOrFalse | bool | Permission granting. |

### transferReward

```solidity
function transferReward(address to, uint256 amount) external
```

Transfer reward to receiver.

_Should only executed by contracts managing LmFactory or UNX rewards._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of receiver. |
| amount | uint256 | The amount of reward. |

### genesisBlock

```solidity
function genesisBlock() external view returns (uint256)
```

Returns genesis block number for mining.

### endBlock

```solidity
function endBlock() external view returns (uint256)
```

Returns end block number for mining.

### currentRewardPerBlock

```solidity
function currentRewardPerBlock() external view returns (uint256 reward)
```

Returns the reward per block for the current halving cycle.

### halvingBlocks

```solidity
function halvingBlocks() external view returns (uint256[] blocks)
```

Returns all halving blocks.

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

Returns total supply for mining.

### calculateTotalMiningBeforeLastHalving

```solidity
function calculateTotalMiningBeforeLastHalving() external view returns (uint256 totalMining)
```

Returns the total mining amount before LastHalving.

### rewardPerBlockOf

```solidity
function rewardPerBlockOf(uint256 halvingNum) external view returns (uint256 reward)
```

Returns the reward per block for a specific halving cycle.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| halvingNum | uint256 | The halving number |

