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

    event LogOperation(address indexed account, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }

    function logOperation(address account, uint256 amount) external {
        require(msg.sender == owner, "Rewards::logOperation: ONLY_OWNER");
        operationsReceipts[account][period] += amount;
        cumulativeMarketVolume[period] += amount;

        emit LogOperation(account, amount);
    }

    function endPeriod() external {
        require(block.timestamp >= period + PERIOD_DURATION, "Rewards::endPeriod: PERIOD_IN_PROGRESS");
        period = block.timestamp + PERIOD_DURATION;

        // TODO emit event
    }

    // TODO uneccessary?
    // function getRedeemableOperationReceipts(uint256[] calldata periods)
    //     external
    //     view
    //     returns (OperationReceipt[] memory receipts)
    // {
    //     for (uint256 i = 0; i < periods.length; i++) {
    //         if (!redemptionReceipts[msg.sender][periods[i]]) {
    //             receipts[i] = operationsReceipts[periods[i]];
    //         }
    //     }
    // }

    function redeemRewards(uint256[] calldata periods) external {
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
