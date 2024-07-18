# Solidity API

## CommonAuth

### owner

```solidity
address owner
```

### executor

```solidity
address executor
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### onlyOwnerOrExecutor

```solidity
modifier onlyOwnerOrExecutor()
```

### setOwner

```solidity
function setOwner(address owner_) public
```

### setExecutor

```solidity
function setExecutor(address executor_) external
```

### _checkOwner

```solidity
function _checkOwner() internal view
```

### _checkOwnerOrExecutor

```solidity
function _checkOwnerOrExecutor() internal view
```

