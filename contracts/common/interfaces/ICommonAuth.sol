// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

interface ICommonAuth {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event ExecutorChanged(address indexed oldExecutor, address indexed newExecutor);

    function setExecutor(address executor_) external;
    function setOwner(address owner_) external;
    
    function owner() external view returns (address);
    function executor() external view returns (address);
}