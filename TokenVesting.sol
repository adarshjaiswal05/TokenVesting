// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./TokenA.sol";

contract TokenVesting {
    uint256 vestingTime = 5 minutes;

    address private _admin;

    TokenA public token;

    struct UserDetails {
        uint256 startTime;
        uint256 endTime;
        uint256 amountPerMinute;
        uint256 payouts;
        uint256 remainingVestedAmount;
    }

    mapping(address => UserDetails) public User;
    mapping(address => uint256) public UserAccumlatedAmount;

    constructor(address _token) {
        require(_token != address(0x0), "invalid-token");
        _admin = msg.sender;
        token = TokenA(_token);
    }

    function vest(uint256 amount) external {
        require(amount > 0, "invalid amount");

        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "insufficient allowance"
        );

        token.transferFrom(msg.sender, address(this), amount);

        UserDetails memory newUser;

        newUser.startTime = block.timestamp;
        newUser.endTime = block.timestamp + vestingTime;
        newUser.amountPerMinute = (amount * 60) / vestingTime;
        newUser.payouts = 0;
        newUser.remainingVestedAmount = amount;

        User[msg.sender] = newUser;
    }

    function updateUserDetails(address add) external {
        UserDetails memory user = User[add];
        require(user.startTime != 0, "no user found");
        require(user.remainingVestedAmount != 0, "no amount left to claim");
        uint256 payoutLeft = (block.timestamp - user.startTime) / 60;
        uint256 claimableAmount;
        if (payoutLeft < 0) {
            claimableAmount =
                ((vestingTime) / 60 - user.payouts) *
                (user.amountPerMinute);
            user.payouts += (((vestingTime) / 60 - user.payouts));
        } else {
            claimableAmount =
                (payoutLeft - user.payouts) *
                (user.amountPerMinute);
            user.payouts += (payoutLeft - user.payouts);
        }

        user.remainingVestedAmount -= claimableAmount;
        UserAccumlatedAmount[add] += claimableAmount;
        User[add] = user;
    }

    function redeemableAmountDetails() external view returns (uint256) {
        return UserAccumlatedAmount[msg.sender];
    }

    function redeemAmount(uint256 amount) external {
        require(amount > 0, "invalid amount");
        require(
            amount <= UserAccumlatedAmount[msg.sender],
            "insufficient amount "
        );
        // UserAccumlatedAmount[msg.sender]-=amount;
        payable(msg.sender).transfer(amount);
    }

    function changeVestingTime(uint256 timeInMinutes) external {
        require(
            msg.sender == _admin,
            "only admin is allowed to perfoam this task"
        );
        vestingTime = timeInMinutes * 60;
    }
}
