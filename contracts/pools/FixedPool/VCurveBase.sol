// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../interfaces/curve/ICurve.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract VCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490; //deposit token to the gauge pool
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52; //reward token

    ICurve3Pool public three_pool = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7); //3 assets deposit pool
    ICurveGauge public gauge = ICurveGauge(0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A); //3crv farming contract
    ICurveMintr public mintr = ICurveMintr(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0); //reward mint contract

    uint256 private constant MAX_UINT_VALUE = uint256(-1);

    constructor() public {
        IERC20(DAI).safeApprove(address(three_pool), MAX_UINT_VALUE);
        IERC20(USDC).safeApprove(address(three_pool), MAX_UINT_VALUE);
        IERC20(USDT).safeApprove(address(three_pool), MAX_UINT_VALUE);
        IERC20(THREE_CRV).safeApprove(address(gauge), MAX_UINT_VALUE);
    }

    function balanceOfPool() public view returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    function getClaimable() external returns (uint256) {
        return gauge.claimable_tokens(address(this));
    }

    function getMostPremium() public view returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = three_pool.balances(0); // DAI
        balances[1] = three_pool.balances(1).mul(10**12); // USDC, decimal is 6
        balances[2] = three_pool.balances(2).mul(10**12); // USDT, decimal is 6

        // DAI
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (DAI, 0);
        }

        // USDC
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (USDC, 1);
        }

        // USDT
        if (balances[2] < balances[0] && balances[2] < balances[1]) {
            return (USDT, 2);
        }
        // If they're somehow equal, we just want DAI
        return (DAI, 0);
    }
}
