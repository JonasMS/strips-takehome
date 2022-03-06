// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";

contract DEX {
    mapping(address => uint256) public balanceOfLongs;
    mapping(address => uint256) public balanceOfShorts;

    enum Position {
        Long,
        Short
    }

    constructor() {
        /*
            deploy Rewards contract
                Ideally, a single rewards contract can serve multiple DEX contracts,
                each created at different times.
        */
    }

    function openPosition(Position position) payable {
        if (position == Position.long) {
            balanceOfLongs[msg.sender] += msg.value;
        } else if (position == Position.short) {
            balanceOfShorts[msg.sender] += msg.value;
        } else {
            revert("DEX::openPosition: INVALID_POSITION");
        }

        // emit event
        // update rewards
    }

    function closePosition(Position position, uint256 amount) {
        if (position == Position.long) {
            require(balanceOfLongs[msg.sender] >= amount, "DEX::closePosition: INSUFFICIENT_LONG_BALANCE");
            balanceOfLongs[msg.sender] -= msg.value;
        } else if (position == Position.short) {
            require(balanceOfShorts[msg.sender] >= amount, "DEX::closePosition: INSUFFICIENT_SHORT_BALANCE");
            balanceOfShorts[msg.sender] -= msg.value;
        } else {
            revert("DEX::closePosition: INVALID_POSITION");
        }

        // emit event
        // update rewards
    }
}
