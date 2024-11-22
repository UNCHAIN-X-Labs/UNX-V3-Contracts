// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './INonfungibleTokenPositionDescriptor.sol';

interface IPositionDescriptor is INonfungibleTokenPositionDescriptor {
    struct NameParams {
        string quoteTokenSymbol;
        string baseTokenSymbol;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
    }

    struct DescriptionParams {
        address poolAddress;
        address quoteTokenAddress;
        address baseTokenAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        uint24 fee;
        uint256 tokenId;
    }

    struct MetadataParams {
        uint256 tokenId;
        address quoteTokenAddress;
        address baseTokenAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        uint8 quoteTokenDecimals;
        uint8 baseTokenDecimals;
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        int24 tickSpacing;
        uint24 fee;
        address poolAddress;
        bool includedUNX;
    }

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }
}