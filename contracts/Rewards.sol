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
    // mapping(uint256 => uint256) cumulativeMarketVolume;

    /* Trader Address => Period Timestamp => Trader's Cumulative Trading Volume */
    mapping(address => mapping(uint256 => uint256)) cumulativeTradingVolumePerPeriod;
    uint256 cumulativeMarketVolume;
    uint256 blockTimestampLastTsx;
    uint256 blockTimestampLastBlock;
    mapping(address => uint256) rewardsBalance;

    event LogOperation(address indexed account, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
        period = block.timestamp;
    }

    /** Notes on changes made:

        1. Ending periods is handling automatically when processing transactions / awarding rewards._afterTokenTransfer

        2. Rewards are awarded on every transaction via O(1) complexity.

        Question:
        I understand how the accumulator mechanism (e.g. like that in UniswapV2) can be used to calculate
        the avg price result of a calculation (i.e. price of an asset or reward) between two points in time.

        In UniswapV2 the price of a token is calculated once per block. That wouldn't work here because
        the CMV needs to be updated and the reward calculated on every transaction, of which there can
        be multiple in a single block.

        Is there a better way than to handle the 'elapsedTime' variable than below, considering that this method
        needs to support multiple transactions per block?

     */
    function logOperation(address account, uint256 amount) external {
        require(msg.sender == owner, "Rewards::logOperation: ONLY_OWNER");

        if (block.timestamp >= period + PERIOD_DURATION) {
            // Reset period and CMV
            period = block.timestamp + PERIOD_DURATION;
            cumulativeMarketVolume = 0;
        }

        // `blockTimestampLastBlock` is used to ensure that the `timeElapsed` value
        // for the accumulator mechanism is never 0.
        uint256 timeElapsedBlock = block.timestamp - blockTimestampLastBlock;
        uint256 timeElapsedTsx = block.timestamp - blockTimestampLastTsx;

        // IF evals to 'True' then last tsx was processed on an earlier block
        if (timeElapsedTsx > 0) {
            blockTimestampLastBlock = timeElapsedBlock;
        }

        cumulativeMarketVolume += amount;
        cumulativeTradingVolumePerPeriod[account][period] += amount;

        uint256 reward = ((cumulativeTradingVolumePerPeriod[account][period] * timeElapsedBlock) /
            cumulativeMarketVolume) / 10; // reward multiplier is 0.1

        rewardsBalance[account] += reward;
        blockTimestampLastTsx = block.timestamp;

        emit LogOperation(account, amount);
    }

    function redeem(address account) external {
        uint256 rewards = rewardsBalance[account];
        rewardsBalance[account] = 0;
        _mint(account, rewards);
    }
}
