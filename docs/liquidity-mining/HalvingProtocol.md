# Solidity API

## HalvingProtocol

_{HalvingProtocol} is responsible for calculating the block reward amount according to the UNX halving schedule.
The UNX halving occurs every {halvingInterval} blocks  from the {genesisBlock}.
After the final halving, mining will continue with a fixed reward(last reward amount halved) amount until the remaining supply is exhausted._

### genesisBlock

```solidity
uint256 genesisBlock
```

Returns genesis block number for mining.

### endBlock

```solidity
uint256 endBlock
```

Returns end block number for mining.

### totalSupply

```solidity
uint256 totalSupply
```

Returns total supply for mining.

### halvingInterval

```solidity
uint256 halvingInterval
```

### totalNum

```solidity
uint256 totalNum
```

### initRewardPerBlcok

```solidity
uint256 initRewardPerBlcok
```

### lastHalvingBlock

```solidity
uint256 lastHalvingBlock
```

### token

```solidity
address token
```

### operators

```solidity
mapping(address => bool) operators
```

### constructor

```solidity
constructor() public
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

### rewardPerBlockOf

```solidity
function rewardPerBlockOf(uint256 halvingNum) external view returns (uint256 reward)
```

Returns the reward per block for a specific halving cycle.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| halvingNum | uint256 | The halving number |

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

### calculateTotalMiningBeforeLastHalving

```solidity
function calculateTotalMiningBeforeLastHalving() public view returns (uint256 totalMining)
```

Returns the total mining amount before LastHalving.

