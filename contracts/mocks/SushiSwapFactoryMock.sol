// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../uniswapv2/UniswapV2Factory.sol";

contract SushiSwapFactoryMock is UniswapV2Factory {
    // Set fee to transaction, only address in MasterChefV2 list can chage
    constructor(address _feeToSetter) public UniswapV2Factory(_feeToSetter) {}
}