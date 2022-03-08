// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Rewards.sol";

import "hardhat/console.sol";

contract DEX {
    mapping(address => uint256) public balanceOfLongs;
    mapping(address => uint256) public balanceOfShorts;
    Rewards public rewardsContract;

    uint256 public constant PERIOD_DURATION = 30 days;
    uint256 curPeriodEndDate;

    enum Position {
        Long,
        Short
    }

    enum TradeType {
        Open,
        Close
    }

    event ExecutePosition(address indexed, Position indexed, uint256);

    constructor(string memory rewardsName, string memory rewardsSymbol) {
        /*
            deploy Rewards contract
                Ideally, a single rewards contract can serve multiple DEX contracts,
                each created at different times.
        */
        rewardsContract = new Rewards(rewardsName, rewardsSymbol);
        curPeriodEndDate = block.timestamp + PERIOD_DURATION;
    }

    function openPosition(Position position) external payable {
        if (position == Position.Long) {
            balanceOfLongs[msg.sender] += msg.value;
        } else if (position == Position.Short) {
            balanceOfShorts[msg.sender] += msg.value;
        } else {
            revert("DEX::openPosition: INVALID_POSITION");
        }

        // emit event
        // emit ExecutePosition(msg.sender, TradeType.Open, msg.value);
        // update rewards
        Rewards(rewardsContract).logOperation(msg.sender, msg.value);
    }

    function closePosition(Position position, uint256 amount) external {
        if (position == Position.Long) {
            require(balanceOfLongs[msg.sender] >= amount, "DEX::closePosition: INSUFFICIENT_LONG_BALANCE");
            balanceOfLongs[msg.sender] -= amount;
        } else if (position == Position.Short) {
            require(balanceOfShorts[msg.sender] >= amount, "DEX::closePosition: INSUFFICIENT_SHORT_BALANCE");
            balanceOfShorts[msg.sender] -= amount;
        } else {
            revert("DEX::closePosition: INVALID_POSITION");
        }

        // emit event
        // emit ExecutePosition(msg.sender, TradeType.close, msg.value);
        // update rewards
        Rewards(rewardsContract).logOperation(msg.sender, amount);
    }

    /*
        NOTE:
            This fxn is effectively duplicated in the Rewards contract
            which is most likely unecessary.
    */
    function endPeriod() external {
        require(block.timestamp >= curPeriodEndDate, "DEX::endPeriod: PERIOD_IN_PROGRESS");
        curPeriodEndDate += PERIOD_DURATION;
        Rewards(rewardsContract).endPeriod();
    }

    function redeemRewards(uint256[] calldata periods) external {
        Rewards(rewardsContract).redeemRewards(msg.sender, periods);
    }
}
