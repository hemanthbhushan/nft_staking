// contracts/Wormhole.sol
// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NftProxy is ERC1967Proxy {
    constructor (address _implementation, bytes memory initData) ERC1967Proxy(
        _implementation,
        initData
    ) { }
}