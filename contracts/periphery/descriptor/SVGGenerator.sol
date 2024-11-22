// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/utils/Strings.sol';

abstract contract SVGGenerator {
    using Strings for uint256;

 	string private constant curve1 = 'M1 1C1 0 0 0 220 220';
    string private constant curve2 = 'M1 1C50 60 110 130 220 220';
    string private constant curve3 = 'M1 1C48 75 108 150 220 220';
    string private constant curve4 = 'M1 1C40 90 105 170 220 220';
    string private constant curve5 = 'M1 1C30 105 95 190 220 220';
    string private constant curve6 = 'M1 1C20 120 85 205 220 220';
    string private constant curve7 = 'M1 1C1 0 0 200 220 220';
    string private constant curve8 = 'M1 1C10 140 75 215 220 220';

    string private constant curveX1 = '191';
    string private constant curveY1 = '180';
    string private constant curveX2 = '411';
    string private constant curveY2 = '399';

    struct SVGParams {
        string quoteToken;
        string baseToken;
        address poolAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        string feeTier;
        int24 tickLower;
        int24 tickUpper;
        int24 tickSpacing;
        int8 overRange;
        uint256 tokenId;
        bool includedUNX;
    }

    struct ForeignObjectParams {
        string feeTier;
        string baseToken;
        string baseTokenSymbol;
        string quoteToken;
        string quoteTokenSymbol;
        bool includedUNX;
    }

    struct ForeignObjectDetailsParams {
        string tokenId;
        string tickLower;
        string tickUpper;
        bool includedUNX;
    }

    struct CurveParams {
        int24 tickLower;
        int24 tickUpper;
        int24 tickSpacing;
        int8 overRange;
        bool includedUNX;
    }
    
    function _generateSVGImage(SVGParams memory params) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                _generateSVGDefs(),
                _generateSVGBackground(params.includedUNX),
                _generateSVGText(params.baseTokenSymbol, params.quoteTokenSymbol),
                _generateSVGForeignObject(
                    ForeignObjectParams(
                        params.feeTier,
                        params.baseToken,
                        params.baseTokenSymbol,
                        params.quoteToken,
                        params.quoteTokenSymbol,
                        params.includedUNX
                    )
                ),
                _generateSvgCurve(
                    CurveParams(
                        params.tickLower,
                        params.tickUpper,
                        params.tickSpacing,
                        params.overRange,
                        params.includedUNX
                    )
                ),
                _generateSVGForeignObjectDetails(
                    ForeignObjectDetailsParams(
                        params.tokenId.toString(),
                        _tickToString(params.tickLower),
                        _tickToString(params.tickUpper),
                        params.includedUNX
                    )
                ),
                '</svg>'
            )
        );
    }

    function _generateSVGDefs() internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg width="592" height="782" viewBox="0 0 592 782" xmlns="http://www.w3.org/2000/svg"',
                " xmlns:xlink='http://www.w3.org/1999/xlink'>",
                '<defs>',
                '<style type="text/css">@font-face {font-family: "CustomFont"; src: url("https://statics.unchainx.io/position/font.otf") format("opentype");}</style>',
                '<mask id="fade-up" maskContentUnits="objectBoundingBox">',
                '<rect width="1" height="1" fill="url(#grad-up)" /></mask>',
                '<mask id="fade-down" maskContentUnits="objectBoundingBox">',
                '<rect width="1" height="1" fill="url(#grad-down)" /></mask>',
                '<mask id="none" maskContentUnits="objectBoundingBox">',
                '<rect width="1" height="1" fill="white" /></mask>',
                '<linearGradient id="grad-up" x1="1" x2="1" y1="1" y2="0">',
                '<stop offset="0.0" stop-color="white" stop-opacity="1" />',
                '<stop offset="0.9" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<linearGradient id="grad-down" x1="0" x2="0" y1="0" y2="1">',
                '<stop offset="0.0" stop-color="white" stop-opacity="1" />',
                '<stop offset="0.8" stop-color="black" stop-opacity="0" /></linearGradient>',
                '<radialGradient id="gradient-circle">',
                '<stop offset="0%" stop-color="#ffffff"></stop>',
                '<stop offset="10%" stop-color="#ffffff"></stop>',
                '<stop offset="40%" stop-color="#63e989da"></stop>',
                '<stop offset="80%" stop-color="#63e98933"></stop>',
                '<stop offset="100%" stop-color="#40404021"></stop></radialGradient>',
                '<radialGradient id="gradient-circle-blue">',
                '<stop offset="0%" stop-color="#ffffff"></stop>',
                '<stop offset="10%" stop-color="#ffffff"></stop>',
                '<stop offset="40%" stop-color="#98ccf2da"></stop>',
                '<stop offset="80%" stop-color="#98ccf233"></stop>',
                '<stop offset="100%" stop-color="#40404021"></stop></radialGradient>',
                '<filter id="shadow-line">',
                '<feDropShadow dx="2" dy="-2" stdDeviation="5" flood-color="#63e98a" flood-opacity="1" />',
                '<feDropShadow dx="-1" dy="1" stdDeviation="5" flood-color="#63e98a" flood-opacity="1" /></filter>',
                '<filter id="shadow-line-blue">',
                '<feDropShadow dx="2" dy="-2" stdDeviation="5" flood-color="#98cdf2" flood-opacity="1" />',
                '<feDropShadow dx="-1" dy="1" stdDeviation="5" flood-color="#98cdf2" flood-opacity="1" /></filter>',
                '<filter id="dropshadow">',
                '<feGaussianBlur in="SourceAlpha" stdDeviation="5" flood-color="#111" />',
                '<feOffset dx="2" dy="2" result="offsetblur" flood-color="#111" flood-opacity="1" />',
                '<feComponentTransfer><feFuncA type="linear" slope="1" /></feComponentTransfer>',
                '<feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge></filter>',
                '</defs>'
            )
        );
    }

    function _generateSVGBackground(bool includedUNX) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<g clip-path="url(#none)">',
                '<image href="', includedUNX ? "https://statics.unchainx.io/position/0.png" : "https://statics.unchainx.io/position/1.png", '" x="0" y="0" width="592" height="782" preserveAspectRatio="cover" />',
                '</g>'
            )
        );
    }

    function _generateSVGText(string memory baseTokenSymbol, string memory quoteTokenSymbol) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<g mask="url(#none)" style="text-transform:uppercase;">',
                '<rect fill="none" x="0" y="0" width="290" height="200" />',
                '<text y="67" x="40" fill="white" font-family="CustomFont" font-size="48px">',
                quoteTokenSymbol,
                ' / ',
                baseTokenSymbol,
                '</text>',
                '</g>'
            )
        );
    }

    function _generateSVGForeignObject(ForeignObjectParams memory params) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<foreignObject x="43" y="75" width="592" height="200">',
                '<div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;">',
                '<h1 style="font-size:20px;font-weight:600;color:', params.includedUNX ? '#3cff00' : '#98cdf2', ';border:1.5px solid ', params.includedUNX ? '#3cff00' : '#98cdf2', 
                ';border-radius:20px;margin-right:10px;padding:4px 7px;font-family:pretendard;">',
                params.feeTier, '</h1>',
                '<div>',
                '<div style="width:270px;display:flex;justify-content:space-between;margin-bottom:3px;color:#888787;font-family:pretendard;">',
                '<span style="font-size:12px;">', params.quoteToken, '</span>',
                '<span style="font-size:12px;text-transform:uppercase;">', '&#160;', params.quoteTokenSymbol, '</span>',
                '</div>',
                '<div style="width:270px;display:flex;justify-content:space-between;color:#888787;font-family:pretendard;">',
                '<span style="font-size:12px;">', params.baseToken, '</span>',
                '<span style="font-size:12px;text-transform:uppercase;">', '&#160;', params.baseTokenSymbol, '</span>',
                '</div>',
                '</div>',
                '</div>',
                '</foreignObject>'
            )
        );
    }

    function _generateSvgCurve(CurveParams memory params) private pure returns (string memory) {
        string memory curve = _getCurve(params.tickLower, params.tickUpper, params.tickSpacing);

        return string(
            abi.encodePacked(
                '<g mask="url(', params.overRange == 1 ? '#fade-up' : params.overRange == -1 ? '#fade-down' : '#none', ')" style="transform:translate(190px,179px)" filter="url(', params.includedUNX ? '#shadow-line' : '#shadow-line-blue', ')">',
                '<rect x="-16" y="-16" width="592" height="400" fill="none" />',
                '<path d="', curve, '" stroke="#ffffff" fill="none" stroke-width="4.5" stroke-linecap="round" stroke-opacity="0.8" />',
                '</g>',
                '<g mask="url(', params.overRange == 1 ? '#fade-up' : params.overRange == -1 ? '#fade-down' : '#none', ')" style="transform:translate(190px,179px)" filter="url(', params.includedUNX ? '#shadow-line' : '#shadow-line-blue', ')">',
                '<rect x="-16" y="-16" width="592" height="400" fill="none" />',
                '<path d="', curve, '" stroke="#ffffff" fill="none" stroke-linecap="round" stroke-opacity="0.8" />',
                '</g>',
                _generateSVGCurveCircle(params.overRange, params.includedUNX)
            )
        );
    }

    function _getCurve(int24 tickLower, int24 tickUpper, int24 tickSpacing) internal pure returns (string memory curve) {
        int24 tickRange = (tickUpper - tickLower) / tickSpacing;
        
        if (tickRange <= 4) {
            curve = curve1;
        } else if (tickRange <= 8) {
            curve = curve2;
        } else if (tickRange <= 16) {
            curve = curve3;
        } else if (tickRange <= 32) {
            curve = curve4;
        } else if (tickRange <= 64) {
            curve = curve5;
        } else if (tickRange <= 128) {
            curve = curve6;
        } else if (tickRange <= 256) {
            curve = curve7;
        } else {
            curve = curve8;
        }
    }

    function _generateSVGCurveCircle(int8 overRange, bool includeUnx) internal pure returns (string memory) {
        if (overRange == 1 || overRange == -1) {
            return string(
                abi.encodePacked(
                    '<circle cx="', overRange == -1 ? curveX1 : curveX2,
                    '" cy="', overRange == -1 ? curveY1 : curveY2,
                    '" r="20" fill="url(', includeUnx ? '#gradient-circle' : '#gradient-circle-blue', ')" />',
                    '<circle cx="', overRange == -1 ? curveX1 : curveX2,
                    '" cy="', overRange == -1 ? curveY1 : curveY2,
                    '" r="25" fill="none" stroke="white" />'
                )
            );
        } else {
            return string(
                abi.encodePacked(
                    '<circle cx="', curveX1, '" cy="', curveY1,
                    '" r="20" fill="url(', includeUnx ? '#gradient-circle' : '#gradient-circle-blue', ')" />',
                    '<circle cx="', curveX2, '" cy="', curveY2,
                    '" r="20" fill="url(', includeUnx ? '#gradient-circle' : '#gradient-circle-blue', ')" />'
                )
            );
        }
    }

    function _generateSVGForeignObjectDetails(ForeignObjectDetailsParams memory params) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<foreignObject x="1" y="471" width="592" height="200">',
                '<div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;flex-direction:column;justify-content:center;align-items:center;font-family:pretendard;">',
                '<div style="width:390px;display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">',
                '<span style="font-size:15px;color:', params.includedUNX ? '#37c645' : '#68a0f5', ';font-weight:700;">ID</span>',
                '<span style="font-size:18px;color:', params.includedUNX ? '#80ff8c' : '#98cdf2', ';font-weight:700;text-shadow:3px 1px 4px #111;">',
                params.tokenId, '</span>',
                '</div>',
                '<div style="width:375px;display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">',
                '<span style="font-size:15px;color:', params.includedUNX ? '#37c645' : '#68a0f5', ';text-shadow:3px 1px 4px #111;font-weight:700;">MIN TICK</span>',
                '<span style="font-size:18px;color:', params.includedUNX ? '#80ff8c' : '#98cdf2', ';font-weight:700;text-shadow:3px 1px 4px #111;">',
                params.tickLower, '</span>',
                '</div>',
                '<div style="width:360px;display:flex;justify-content:space-between;align-items:center;">',
                '<span style="font-size:15px;color:', params.includedUNX ? '#37c645' : '#68a0f5', ';text-shadow:3px 1px 4px #111;font-weight:700;">MAX TICK</span>',
                '<span style="font-size:18px;color:', params.includedUNX ? '#80ff8c' : '#98cdf2', ';font-weight:700;text-shadow:3px 1px 4px #111;">',
                params.tickUpper, '</span>',
                '</div>',
                '</div>',
                '</foreignObject>'
            )
        );
    }

    function _tickToString(int24 tick) private pure returns (string memory) {
        string memory sign = '';
        if (tick < 0) {
            tick = tick * -1;
            sign = '-';
        }
        return string(abi.encodePacked(sign, uint256(tick).toString()));
    }
}