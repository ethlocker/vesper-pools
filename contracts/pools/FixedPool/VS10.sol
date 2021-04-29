// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./VFixedPoolBase.sol";

//solhint-disable no-empty-blocks
contract VS10Pool is VFixedPoolBase {
    constructor(address _controller) public VFixedPoolBase(_controller, 1000, "VS10 PoolShare Token", "VS10") {}
}
