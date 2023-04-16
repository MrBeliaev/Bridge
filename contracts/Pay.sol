// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pay is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), 100000000 * 10 ** decimals());
    }

    function multiTransfer(
        address[] calldata _toAddresses,
        uint256[] calldata _amounts
    ) external {
        require(
            _toAddresses.length == _amounts.length,
            "Need arrays same length"
        );
        for (uint i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }
}
