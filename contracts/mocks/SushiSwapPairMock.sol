// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../uniswapv2/UniswapV2Pair.sol";

contract SushiSwapPairMock is UniswapV2Pair {
    // Initialize pair of token 
    constructor() public UniswapV2Pair() {}
}