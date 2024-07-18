# Solidity API

## ICommonAuth

### OwnerChanged

```solidity
event OwnerChanged(address oldOwner, address newOwner)
```

### ExecutorChanged

```solidity
event ExecutorChanged(address oldExecutor, address newExecutor)
```

### setExecutor

```solidity
function setExecutor(address executor_) external
```

### setOwner

```solidity
function setOwner(address owner_) external
```

### owner

```solidity
function owner() external view returns (address)
```

### executor

```solidity
function executor() external view returns (address)
```

