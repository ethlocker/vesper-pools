// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./VCurveBase.sol";
import "../../Pausable.sol";
import "../../interfaces/vesper/IController.sol";
import "../../interfaces/chainlink/AggregatorV3Interface.sol";

abstract contract VFixedPoolBase is VCurveBase, Context, Pausable, ReentrancyGuard, ERC20 {
    mapping(address => AggregatorV3Interface) internal priceFeed;

    uint16 public immutable APY; // 10000 = 100%

    uint256 public insuranceBalance;

    IController public immutable controller;

    constructor(
        address _controller,
        uint16 _apy,
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
        require(_controller != address(0), "Controller address is zero");
        require(_apy > 0 && _apy < 1000, "APY is invalid");

        controller = IController(_controller);
        APY = _apy;

        priceFeed[DAI] = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9); // dai/usd price oracle
        priceFeed[USDC] = AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); // usdc/usd price oracle
        priceFeed[USDT] = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D); // usdt/usd price oracle
    }

    function getLatestPrice(address token) public view returns (int256) {
        (, int256 price, , , ) = priceFeed[token].latestRoundData();
        return price;
    }

    /**
     * @notice Deposit DAI/USDC/USDT tokens
     * @param token Deposit token.
     * @param amount ERC20 token amount.
     */
    function deposit(address token, uint256 amount) public whenNotPaused nonReentrant {
        require(token == DAI || token == USDC || token == USDT, "Deposit token is not allowed");
        require(!address(_msgSender()).isContract(), "Contract is not allowed");

        uint256[3] memory liquidity;
        if (token == DAI) {
            liquidity[0] = amount;
        } else if (token == USDC) {
            liquidity[1] = amount;
        } else if (token == USDT) {
            liquidity[2] = amount;
        }
        three_pool.add_liquidity(liquidity, 0);
        uint256 _usdAmount = amount.mul(uint256(getLatestPrice(token)));
        _mint(_msgSender(), _usdAmount);
    }

    function withdraw(uint256 amount) public whenNotPaused nonReentrant {
        require(!address(_msgSender()).isContract(), "Contract is not allowed");
    }

    function rebalance() external {}

    function tokenLocked() public view returns (uint256) {}

    function totalValue() public view returns (uint256) {}

    modifier onlyController() {
        require(address(controller) == _msgSender(), "Caller is not the controller");
        _;
    }

    function pause() external onlyController {
        _pause();
    }

    function unpause() external onlyController {
        _unpause();
    }

    function shutdown() external onlyController {
        _shutdown();
    }

    function open() external onlyController {
        _open();
    }
}
