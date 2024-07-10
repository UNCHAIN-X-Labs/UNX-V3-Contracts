// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './interfaces/IUNXwapV3Manager.sol';
import '../common/CommonAuth.sol';
import './UNXwapV3Factory.sol';
import  '../liquidity-mining/UNXwapV3LmFactory.sol';

/**
 * @title UNXwapV3Manager
 * @dev {UNXwapV3Manager} serves as the top-level manager of the UNXwap Protocol, overseeing other contracts within the protocol.
 * It has the authority to set important configuration values for the protocol.
 * But once the DAO is established, these authorities will be transferred to the DAO, and the executor will be the contract address that executes the DAO’s decisions.
 * Ultimately, when the DAO reaches a stable phase, the team will relinquish ownership by changing the owner to the zero address.
 */
contract UNXwapV3Manager is IUNXwapV3Manager, CommonAuth {
    /// @inheritdoc IUNXwapV3Manager
    IUniswapV3Factory public immutable override factory;
    /// @inheritdoc IUNXwapV3Manager
    IUNXwapV3LmFactory public override lmFactory;

    /// @inheritdoc IUNXwapV3Manager
    address public override deployFeeToken;
    /// @inheritdoc IUNXwapV3Manager
    address public override deployFeeCollector;
    /// @inheritdoc IUNXwapV3Manager
    bool public override deployable;
    /// @inheritdoc IUNXwapV3Manager
    uint256 public override deployFee;
    /// @inheritdoc IUNXwapV3Manager
    address public override nfpManager;
    /// @inheritdoc IUNXwapV3Manager
    address public override protocolFeeCollector;

    constructor() {
        factory = IUniswapV3Factory(address(new UNXwapV3Factory{salt: keccak256(abi.encode(msg.sender, address(this)))}()));
        owner = msg.sender;
        protocolFeeCollector = msg.sender;
    }

    /// @inheritdoc IUNXwapV3Manager
    function createPool(
        address tokenA,
        address tokenB,
        address payer,
        uint24 fee,
        uint256 requiredDeployFee
    ) external override returns (address v3Pool, address lmPool) {
        if(deployable) {
            require(msg.sender == nfpManager, "caller is unauthorized");
            if(deployFee > 0) {
                _operateDeployFeeProtocol(payer, requiredDeployFee);
            }
        } else {
            _checkOwnerOrExecutor();
        }

        v3Pool = factory.createPool(tokenA, tokenB, fee);
        lmPool = lmFactory.createLmPool(v3Pool);
        _setLmPool(v3Pool, lmPool);
    }
    
    /// @inheritdoc IUNXwapV3Manager
    function list(address v3Pool) external override onlyOwnerOrExecutor returns (address lmPool) {
        lmPool = lmFactory.list(v3Pool);
    }

    /// @inheritdoc IUNXwapV3Manager
    function delist(address v3Pool) external override onlyOwnerOrExecutor {
        lmFactory.delist(v3Pool);
    }

    /// @inheritdoc IUNXwapV3Manager
    function allocate(PoolAllocationParams[] calldata params) external override onlyOwnerOrExecutor {
        lmFactory.allocate(params);
    }
    
    /// @inheritdoc IUNXwapV3Manager
    function setFactoryOwner(address owner_) external override onlyOwner {
        factory.setOwner(owner_);
    }  

    /// @inheritdoc IUNXwapV3Manager
    function setLmFactory(address lmFactory_) external override onlyOwner {
        lmFactory = IUNXwapV3LmFactory(lmFactory_);
        emit SetLmPactory(lmFactory_);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setDeployFeeToken(address token) external override onlyOwnerOrExecutor {
        uint32 size;
        assembly {
            size := extcodesize(token)
        }
        require(size > 0);

        deployFeeToken = token;
        emit SetDeployFeeToken(token);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setDeployFeeCollector(address collector) external override onlyOwnerOrExecutor {
        deployFeeCollector = collector;
        emit SetDeployFeeCollector(collector);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setDeployable(bool deployable_) external override onlyOwnerOrExecutor {
        deployable = deployable_;
        emit SetDeployable(deployable_);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setDeployFee(uint256 fee) external override onlyOwnerOrExecutor {
        deployFee = fee;
        emit SetDeployFee(deployFeeToken, fee);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setFeeProtocol(ProtocolFeeParams[] calldata params) external override onlyOwnerOrExecutor {
        for(uint256 i = 0; i < params.length; ++i) {
            UNXwapV3Pool(params[i].v3Pool).setFeeProtocol(params[i].feeProtocol0, params[i].feeProtocol1);
        }
    }

    /// @inheritdoc IUNXwapV3Manager
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external override onlyOwnerOrExecutor {
        factory.enableFeeAmount(fee, tickSpacing);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setMaxAllocation(uint256 maxValue) external override onlyOwnerOrExecutor {
        lmFactory.setMaxAllocation(maxValue);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setNfpManager(address nfpManager_) external override onlyOwner {
        nfpManager = nfpManager_;
        emit SetNfpManager(nfpManager_);
    }

    /// @inheritdoc IUNXwapV3Manager
    function setProtocolFeeCollector(address collector) external override onlyOwner {
        protocolFeeCollector = collector;
        emit SetProtocolFeeCollector(collector);
    }

    /// @inheritdoc IUNXwapV3Manager
    function collectProtocol(CollectProtocolFeeParams[] calldata params) external override returns (CollectProtocolFeeParams[] memory result) {
        require(msg.sender == protocolFeeCollector);
        result = new CollectProtocolFeeParams[](params.length);
        for(uint256 i = 0; i < params.length; ++i) {
            (uint128 amount0, uint128 amount1) = UNXwapV3Pool(params[i].v3Pool).collectProtocol(protocolFeeCollector, params[i].amount0, params[i].amount1);
            result[i].v3Pool = params[i].v3Pool;
            result[i].amount0 = amount0;
            result[i].amount1 = amount1;
        }
    }

    /**
     * @notice Collects the deploy fee from the payer.
     * @param payer The address of payer.
     * @param requiredDeployFee The deploy fee required by payer.
     */
    function _operateDeployFeeProtocol(address payer, uint256 requiredDeployFee) internal {
        require(deployFeeCollector != address(0), 'deployFeeCollector does not exist');
        require(deployFeeToken != address(0), 'deployFeeToken does not exist');
        require(requiredDeployFee == deployFee, 'requiredDeployFee does not equal deployFee');

        (bool success, bytes memory data) = deployFeeToken.call(abi.encodeWithSelector(IERC20.transferFrom.selector, payer, deployFeeCollector, deployFee));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'pay for deployement fee failed');

        emit CollectDeployFee(payer, deployFeeCollector, deployFeeToken, deployFee);
    }

    /**
     * @notice Syncs the {UNXwapV3LmPool} with the {UNXwapV3Pool}
     * @param v3Pool The contract address of {UNXwapV3Pool}
     * @param lmPool The contract address of {UNXwapV3LmPool}
     */
    function _setLmPool(address v3Pool, address lmPool) internal {
        UNXwapV3Pool(v3Pool).setLmPool(lmPool);
        emit SetLmPool(v3Pool, lmPool); 
    }  
}