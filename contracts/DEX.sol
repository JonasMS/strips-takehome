// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import RewardsContract from "./Rewards.sol";
import IRewardsContract from "./IRewards.sol";

import "hardhat/console.sol";

contract DEX {
    mapping(address => uint256) public balanceOfLongs;
    mapping(address => uint256) public balanceOfShorts;
    address rewardsContract public;

    enum Position {
        Long,
        Short
    }

    enum TradeType {
        Open,
        Close
    }
    
    event ExecutePosition(address indexed, Position indexed, uint);

    constructor() {
        /*
            deploy Rewards contract
                Ideally, a single rewards contract can serve multiple DEX contracts,
                each created at different times.
        */
        rewardsContract = new RewardsContract("DexRewards", "DRD");
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
        IRewardsContract(rewardsContract).logOperation(msg.sender, msg.value);
    }

    function closePosition(Position position, uint256 amount) external {
        if (position == Position.Long) {
            require(balanceOfLongs[msg.sender] >= amount, "DEX::closePosition: INSUFFICIENT_LONG_BALANCE");
            balanceOfLongs[msg.sender] -= msg.value;
        } else if (position == Position.Short) {
            require(balanceOfShorts[msg.sender] >= amount, "DEX::closePosition: INSUFFICIENT_SHORT_BALANCE");
            balanceOfShorts[msg.sender] -= msg.value;
        } else {
            revert("DEX::closePosition: INVALID_POSITION");
        }

        // emit event
        // emit ExecutePosition(msg.sender, TradeType.close, msg.value);
        // update rewards
        IRewardsContract(rewardsContract).logOperation(msg.sender, msg.value);

    }
}
