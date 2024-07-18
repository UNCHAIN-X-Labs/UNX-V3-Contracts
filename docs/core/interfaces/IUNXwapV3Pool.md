# Solidity API

## IUNXwapV3Pool

### lmPool

```solidity
function lmPool() external view returns (contract IUNXwapV3LmPool)
```

The IUNXwapV3LmPool interface that deployed the lmPool

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract IUNXwapV3LmPool | The IUNXwapV3LmPool interface |

### setLmPool

```solidity
function setLmPool(address lmPool_) external
```

Set {lmPool}

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lmPool_ | address | The contract address of lmPool |

