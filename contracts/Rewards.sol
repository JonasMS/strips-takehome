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
    /* NOTE:
        More gas efficient to just store the most recently redeemed period.
        This would open up the possibility of users missing out on reward periods
        but that risk can be mitigated.
    */
    mapping(address => mapping(uint256 => bool)) redemptionReceipts;
    mapping(uint256 => uint256) cumulativeMarketVolume;

    event LogOperation(address indexed account, uint256 amount);
    event EndPeriod(uint256 indexed period);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
        period = block.timestamp;
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

        emit EndPeriod(period);
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

    function redeemRewards(address account, uint256[] calldata periods) external {
        uint256 rewards;

        for (uint256 i = 0; i < periods.length; i++) {
            // can't be of current period or later
            require(periods[i] < period && periods[i] > 0, "Rewards::redeemReards: INVALID_PERIOD");
            // can't be 'redeemed == true'
            require(
                !redemptionReceipts[account][periods[i]],
                "Rewards::redeemRewards: PERIOD_REWARDS_ALREADY_REDEEMED"
            );

            // calculate rewards
            uint256 ctv = operationsReceipts[account][periods[i]];
            uint256 cmv = cumulativeMarketVolume[periods[i]];
            rewards += ((ctv * 387) / 1000) / cmv;
            redemptionReceipts[account][periods[i]] = true;
        }

        _mint(account, rewards);
    }
}
