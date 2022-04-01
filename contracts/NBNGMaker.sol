// SPDX-License-Identifier: MIT

// P1 - P3: OK
pragma solidity 0.6.12;
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./uniswapv2/interfaces/IUniswapV2ERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";

import "./Ownable.sol";

// NBNGMaker is MasterChef's left hand and kinda a wizard. He can cook up NBNG from pretty much anything!
// This contract handles "serving up" rewards for xNBNG holders by trading tokens collected from fees for NBNG.

// T1 - T4: OK
contract NBNGMaker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // V1 - V5: OK
    IUniswapV2Factory public immutable factory; // Set contract for factory address
    // V1 - V5: OK
    address public immutable bar; // Safe all value of user staking
    // V1 - V5: OK
    address private immutable nbng; // Address of  token NBNG
    // V1 - V5: OK
    address private immutable weth; //Address of token WETH

    // V1 - V5: OK
    mapping(address => address) internal _bridges; // Mapping user address get address of bridge address

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountNBNG
    );
    // Setup for address fot factory, bar, nbng, weth  
    constructor(
        address _factory,
        address _bar,
        address _nbng,
        address _weth
    ) public {
        factory = IUniswapV2Factory(_factory);
        bar = _bar;
        nbng = _nbng;
        weth = _weth;
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        // Check Bridge == Address(0) => set brigder address is weth
        if (bridge == address(0)) {
            bridge = weth;
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != nbng && token != weth && token != bridge,
            "NBNGMaker: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    // M1 - M5: OK
    // C1 - C24: OK
    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "NBNGMaker: must use EOA");
        _;
    }

    // F1 - F10: OK
    // F3: _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of NBNG to the bar, run convert, then remove the NBNG again.
    //     As the size of the NBNGBar has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token0, address token1) external onlyEOA() {
        _convert(token0, token1);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(
        address[] calldata token0,
        address[] calldata token1
    ) external onlyEOA() {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(token0[i], token1[i]);
        }
    }

    // F1 - F10: OK
    // C1- C24: OK
    function _convert(address token0, address token1) internal {
        // Interactions
        // S1 - S4: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "NBNGMaker: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }
        emit LogConvert(
            msg.sender,
            token0,
            token1,
            amount0,
            amount1,
            _convertStep(token0, token1, amount0, amount1)
        );
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, _swap, _toNBNG, _convertStep: X1 - X5: OK
    function _convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 NBNGOut) {
        // Interactions
        // If address of token1 equal token2
        // Same token =
        if (token0 == token1) {   
        // Address of token1 equal address of token2
            uint256 amount = amount0.add(amount1);
        // Address of token 1 and address of token 2 equal nbng(Token SPC)   
            if (token0 == nbng) {
        // Send token SPC for address bar        
                IERC20(nbng).safeTransfer(bar, amount);
                NBNGOut = amount;
            } else if (token0 == weth) {
                NBNGOut = _toNBNG(weth, amount);
            } else {
        // Convert token difference token nbng and WETH     
        // Get address for briger token  
                address bridge = bridgeFor(token0);
        // Get amount out when swap token token0 to bridge         
                amount = _swap(token0, bridge, amount, address(this));
        // Covert amount: _convertStep() -> Check type of token to convert     
        // Continue check type contoken    
                NBNGOut = _convertStep(bridge, bridge, amount, 0);
            }
        // difference token token0 # token1   
        // Token0 equal nbng 
        } else if (token0 == nbng) {
            // eg. NBNG - ETH
        // Transfer amount0 of token0 to address bar token ERC20
            IERC20(nbng).safeTransfer(bar, amount0); 
        // Get token out     
            NBNGOut = _toNBNG(token1, amount1).add(amount0);
        } else if (token1 == nbng) {
            // eg. USDT - NBNG
            IERC20(nbng).safeTransfer(bar, amount1);
            NBNGOut = _toNBNG(token0, amount0).add(amount1);
        } else if (token0 == weth) {
            // eg. ETH - USDC
            // WETH to token USDC
            // Token token1 to token weth
            NBNGOut = _toNBNG(
                weth,
                _swap(token1, weth, amount1, address(this)).add(amount0)
            );
        } else if (token1 == weth) {
            // eg. USDT - ETH
            // Token WETH to WETH to token USDC
            NBNGOut = _toNBNG(
                weth,
                _swap(token0, weth, amount0, address(this)).add(amount1)
            );
        } else {
            // eg. MIC - USDT
            // Bridge => swap token 
            address bridge0 = bridgeFor(token0);
            // 
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                NBNGOut = _convertStep(
                    bridge0,
                    token1,
                    _swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                NBNGOut = _convertStep(
                    token0,
                    bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this))
                );
            } else {
                NBNGOut = _convertStep(
                    bridge0,
                    bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    _swap(token0, bridge0, amount0, address(this)),
                    _swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(
        address fromToken, //from
        address toToken,  //to
        uint256 amountIn,  //TokenIn
        address to // Address transfer token
    ) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        //Get pair address
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(fromToken, toToken));
        // address of pair different 0    
        require(address(pair) != address(0), "NBNGMaker: Cannot convert");

        // Interactions
        // X1 - X5: OK
        // get data value of token in liquidity pool
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        // set ammount in
        uint256 amountInWithFee = amountIn.mul(997);
        //Check from token equal pair token
        if (fromToken == pair.token0()) {
         // Calculate token with amountOut
            amountOut =
                amountInWithFee.mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut =
                amountInWithFee.mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _toNBNG(address token, uint256 amountIn)
        internal
        returns (uint256 amountOut)
    {
        // X1 - X5: OK
        amountOut = _swap(token, nbng, amountIn, bar);
    }
}
