// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './interfaces/IUNXwapV3Manager.sol';
import '../common/CommonAuth.sol';
import './UNXwapV3Factory.sol';
import  '../liquidity-mining/UNXwapV3LmFactory.sol';

contract UNXwapV3Manager is IUNXwapV3Manager, CommonAuth {
    IUniswapV3Factory public immutable override factory;
    IUNXwapV3LmFactory public override lmFactory;

    address public override deployFeeToken;
    address public override deployFeeCollector;
    bool public override deployable;
    uint256 public override deployFee;

    constructor() {
        factory = IUniswapV3Factory(address(new UNXwapV3Factory{salt: keccak256(abi.encode(msg.sender, address(this)))}()));
        owner = msg.sender;
    }

    function createPool(address tokenA, address tokenB, address payer, uint24 fee) external override returns (address v3Pool, address lmPool) {
        if(deployable) {
            if(deployFee > 0) {
                _operateDeployFeeProtocol(payer);
            }
        } else {
            _checkOwnerOrExecutor();
        }

        v3Pool = factory.createPool(tokenA, tokenB, fee);
        lmPool = lmFactory.createLmPool(v3Pool);
        IUNXwapV3Pool(v3Pool).setLmPool(lmPool);
    }
    
    function list(address v3Pool) external override onlyOwnerOrExecutor returns (address lmPool) {
        lmPool = lmFactory.list(v3Pool);
    }

    function delist(address v3Pool) external override onlyOwnerOrExecutor {
        lmFactory.delist(v3Pool);
    }

    function allocate(PoolAllocationParams[] calldata params) external override onlyOwnerOrExecutor {
        lmFactory.allocate(params);
    }
    
    function setFactoryOwner(address owner_) external override onlyOwner {
        factory.setOwner(owner_);
    }  

    function setLmFactory(address lmFactory_) external override onlyOwner {
        lmFactory = IUNXwapV3LmFactory(lmFactory_);
    }

    function setLmPool(address v3Pool, address lmPool) external override onlyOwnerOrExecutor {
        UNXwapV3Pool(v3Pool).setLmPool(lmPool);
    }  

    function setDeployFeeToken(address token) external override onlyOwnerOrExecutor {
        deployFeeToken = token;
    }

    function setDeployFeeCollector(address collector) external override onlyOwnerOrExecutor {
        deployFeeCollector = collector;
    }

    function setDeployable(bool deployable_) external override onlyOwnerOrExecutor {
        deployable = deployable_;
    }

    function setDeployFee(uint256 fee) external override onlyOwnerOrExecutor {
        deployFee = fee;
    }

    function setFeeProtocol(address v3Pool, uint8 feeProtocol0, uint8 feeProtocol1) external override onlyOwnerOrExecutor {
        UNXwapV3Pool(v3Pool).setFeeProtocol(feeProtocol0, feeProtocol1);
    }

    function collectProtocol(
        address v3Pool,
        address collector,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override onlyOwnerOrExecutor returns (uint128 amount0, uint128 amount1) {
        (amount0, amount1) = UNXwapV3Pool(v3Pool).collectProtocol(collector, amount0Requested, amount1Requested);
    }

    function _operateDeployFeeProtocol(address payer) internal {
        (bool success, bytes memory data) = deployFeeToken.call(abi.encodeWithSelector(IERC20.transferFrom.selector, payer, deployFeeCollector, deployFee));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'pay for deployement fee failed');

        emit CollectDeployFee(payer, deployFeeCollector, deployFeeToken, deployFee);
    }
}