// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract Rewards is ERC20 {
    uint256 public constant PERIOD_DURATION = 30 days;

    address owner;

    struct OperationReceipt {
        uint256 amount;
        bool redeemed;
    }

    uint256 period;

    /* Trader Address => Period Timestamp => Trader's Cumulative Trading Volume */
    mapping(address => mapping(uint256 => uint256)) operationsReceipts;
    mapping(address => mapping(uint256 => bool)) redemptionReceipts;
    mapping(uint256 => uint256) cumulativeMarketVolume;

    constructor() {
        owner = msg.sender;
    }

    function logOperation(address account, uint256 amount) onlyOwner {
        require(msg.sender == owner, "Rewards::logOperation: ONLY_OWNER");
        operationsReceipts[account][period] += amount;
        cumulativeMarketVolume[period] += amount;

        // TODO emit event
    }

    function endPeriod() {
        require(block.timestamp >= period + PERIOD_DURATION, "Rewards::endPeriod: PERIOD_IN_PROGRESS");
        period = block.timestamp + PERIOD_DURATION;

        // TODO emit event
    }

    function getRedeemableOperationReceipts(uint256[] calldata periods) view returns (OperationReceipt[] receipts) {
        OperationReceipt[] _operationsReceipts;

        // = operationsReceipts[msg.sender];

        for (uint256 i = 0; i < periods.length; i++) {
            if (!redemptionReceipts[msg.sender][periods[i]]) {
                receipts.push(_operationsReceipts[periods[i]]);
            }
        }
    }

    function redeemRewards(uint256[] periods) {
        uint256 _operationsReceipts = operationsReceipts[msg.sender];
        uint256 rewards;

        for (uint256 i = 0; i < periods.length; i++) {
            // can't be of current period
            require(periods[i] < period, "Rewards::redeemReards: INVALID_PERIOD");
            // can't be 'redeemed == false'
            require(
                !redemptionReceipts[msg.sender][periods[i]],
                "Rewards::redeemRewards: PERIOD_REWARDS_ALREADY_REDEEMED"
            );

            rewards += operationsReceipts[msg.sender][periods[i]];
            redemptionReceipts[msg.sender][periods[i]] = true;
        }
        _mint(msg.sender, rewards);

        // TODO Emit event
    }
}
