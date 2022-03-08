interface IRewards {
    function logOperation(address account, uint256 amount) external;

    function endPeriod() external;

    function redeemRewards(uint256[] calldata periods) external;
}
