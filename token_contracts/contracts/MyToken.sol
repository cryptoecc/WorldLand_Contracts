
// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WorldLandNativeToken is ERC20 {
    constructor(address foundation_wallet) 
        ERC20("WorldLand", "WL") 
    {
        _mint(foundation_wallet, 1_000_000_000 * 10 ** decimals());
    }
}
