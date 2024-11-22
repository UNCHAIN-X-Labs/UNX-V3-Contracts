// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/lib/contracts/libraries/SafeERC20Namer.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IERC20Metadata.sol';
import './interfaces/INonfungiblePositionManager.sol';
import './descriptor/MetadataGenerator.sol';
import '../core/interfaces/IUniswapV3Pool.sol';

contract PositionDescriptor is MetadataGenerator {
    address private immutable WBNB;
    address private immutable UNX;

    constructor(address WBNB_, address UNX_) {
        WBNB = WBNB_;
        UNX = UNX_;
    }

    function tokenURI(INonfungiblePositionManager positionManager, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        (, , address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, , , , , ) = positionManager.positions(tokenId);
        
        IUniswapV3Pool pool = IUniswapV3Pool(
            PoolAddress.computeAddress(
                positionManager.factory(),
                PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
            )
        );

        (, int24 tick, , , , , ) = pool.slot0();

        return _generateMetadata(
            MetadataParams(
                tokenId,
                token0,
                token1,
                token0 == WBNB ? "BNB" : SafeERC20Namer.tokenSymbol(token0),
                token1 == WBNB ? "BNB" : SafeERC20Namer.tokenSymbol(token1),
                IERC20Metadata(token0).decimals(),
                IERC20Metadata(token1).decimals(),
                tickLower,
                tickUpper,
                tick,
                pool.tickSpacing(),
                fee,
                address(pool),
                token0 == UNX || token1 == UNX ? true : false
            )
        );
    }
}