// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './interfaces/ICommonAuth.sol';

contract CommonAuth is ICommonAuth {
    address public override owner;
    address public override executor;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyOwnerOrExecutor {
        _checkOwnerOrExecutor();
        _;
    }

    function setOwner(address owner_) public override onlyOwner {
        require(owner != owner_);
        emit OwnerChanged(owner, owner_);
        owner = owner_;
    }

    function setExecutor(address executor_) external override onlyOwnerOrExecutor {
        require(executor != executor_);
        emit ExecutorChanged(executor, executor_);
        executor = executor_;
    }
    
    function _checkOwner() internal view {
        require(msg.sender == owner, "Only call by owner");
    }

    function _checkOwnerOrExecutor() internal view {
        require(msg.sender == owner || msg.sender == executor, "Caller is unauthorized");
    }
}