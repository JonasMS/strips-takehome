// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract Rewards is ERC20 {
    uint256 public constant PERIOD_DURATION = 30 days;

    address owner;

    struct OperationReceipt {
        uint256 amount;
        uint256 period;
    }

    uint256 period;

    mapping(address => OperationReceipt[]) operationsReceipts;
    mapping(uint256 => uint256) cumulativeMarketVolume;

    constructor() {
        owner = msg.sender;
    }

    function logOperation(address account, uint256 amount) onlyOwner {
        require(msg.sender == owner, "Rewards::logOperation: ONLY_OWNER");
        operationsReceipts[account].push(amount, period);
        cumulativeMarketVolume[period] += amount;

        // TODO emit event
    }

    function endPeriod() {
        require(block.timestamp >= period + PERIOD_DURATION, "Rewards::endPeriod: PERIOD_IN_PROGRESS");
        period = block.timestamp + PERIOD_DURATION;

        // TODO emit event
    }
}
