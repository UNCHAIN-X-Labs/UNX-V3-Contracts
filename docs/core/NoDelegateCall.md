# Solidity API

## NoDelegateCall

Base contract that provides a modifier for preventing delegatecall to methods in a child contract

### constructor

```solidity
constructor() internal
```

### noDelegateCall

```solidity
modifier noDelegateCall()
```

Prevents delegatecall into the modified method

