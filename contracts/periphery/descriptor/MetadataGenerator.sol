// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import 'base64-sol/base64.sol';
import '../interfaces/IPositionDescriptor.sol';
import '../libraries/HexStrings.sol';
import './SVGGenerator.sol';

abstract contract MetadataGenerator is IPositionDescriptor, SVGGenerator {
    using SafeMath for uint8;
    using SafeMath for uint256;
    using HexStrings for uint256;

    function _generateMetadata(MetadataParams memory params) internal pure returns (string memory) {
        string memory name = _generateName(
            NameParams(
                params.quoteTokenSymbol,
                params.baseTokenSymbol,
                params.tickLower,
                params.tickUpper,
                params.fee
            )            
        );

        string memory description = _generateDescription(
            DescriptionParams(
                params.poolAddress,
                params.quoteTokenAddress,
                params.baseTokenAddress,
                params.quoteTokenSymbol,
                params.baseTokenSymbol,
                params.fee,
                params.tokenId
            )
        );

        string memory image = Base64.encode(bytes(_generateSVGImage(
            SVGGenerator.SVGParams({
                quoteToken: _addressToString(params.quoteTokenAddress),
                baseToken: _addressToString(params.baseTokenAddress),
                poolAddress: params.poolAddress,
                quoteTokenSymbol: params.quoteTokenSymbol,
                baseTokenSymbol: params.baseTokenSymbol,
                feeTier: _feeToPercentString(params.fee),
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                tickSpacing: params.tickSpacing,
                overRange: _overRange(params.tickLower, params.tickUpper, params.tickCurrent),
                tokenId: params.tokenId,
                includedUNX: params.includedUNX
            })
        )));
        
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _generateName(NameParams memory params) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                'Unchain X Position NFT - ',
                params.quoteTokenSymbol,
                '/',
                params.baseTokenSymbol,
                '(',
                _feeToPercentString(params.fee),
                ')'
            )
        );
    }

    function _generateDescription(DescriptionParams memory params) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'This NFT represents a liquidity position in a Unchain X ',
                    params.quoteTokenSymbol,
                    '/',
                    params.baseTokenSymbol,
                    ' pool. ',
                    'The owner of this NFT can modify or redeem the position.\\n',
                    'Pool Address: ',
                    _addressToString(params.poolAddress),
                    '\\n\\n',
                    unicode'⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated.'
                )
            );
    }

    function _feeToPercentString(uint24 fee) internal pure returns (string memory) {
        if (fee == 0) {
            return '0%';
        }
        uint24 temp = fee;
        uint256 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        uint256 nZeros;
        if (digits >= 5) {
            // if decimal > 1 (5th digit is the ones place)
            uint256 decimalPlace = digits.sub(numSigfigs) >= 4 ? 0 : 1;
            nZeros = digits.sub(5) < (numSigfigs.sub(1)) ? 0 : digits.sub(5).sub(numSigfigs.sub(1));
            params.zerosStartIndex = numSigfigs;
            params.zerosEndIndex = uint8(params.zerosStartIndex.add(nZeros).sub(1));
            params.sigfigIndex = uint8(params.zerosStartIndex.sub(1).add(decimalPlace));
            params.bufferLength = uint8(nZeros.add(numSigfigs.add(1)).add(decimalPlace));
        } else {
            // else if decimal < 1
            nZeros = uint256(5).sub(digits);
            params.zerosStartIndex = 2;
            params.zerosEndIndex = uint8(nZeros.add(params.zerosStartIndex).sub(1));
            params.bufferLength = uint8(nZeros.add(numSigfigs.add(2)));
            params.sigfigIndex = uint8((params.bufferLength).sub(2));
            params.isLessThanOne = true;
        }
        params.sigfigs = uint256(fee).div(10**(digits.sub(numSigfigs)));
        params.isPercent = true;
        params.decimalIndex = digits > 4 ? uint8(digits.sub(4)) : 0;

        return _generateDecimalString(params);
    }

    function _generateDecimalString(DecimalStringParams memory params) internal pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex.add(1); zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[params.sigfigIndex--] = '.';
            }
            buffer[params.sigfigIndex--] = bytes1(uint8(uint256(48).add(params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function _addressToString(address addr) internal pure returns (string memory) {
        return (uint256(addr)).toHexString(20);
    }

    function _overRange(int24 tickLower, int24 tickUpper, int24 tickCurrent) internal pure returns (int8) {
        if (tickCurrent < tickLower) {
            return -1;
        } else if (tickCurrent > tickUpper) {
            return 1;
        } else {
            return 0;
        }
    }
}