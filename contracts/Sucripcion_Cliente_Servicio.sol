// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
contract MonthlySubscription {
    address public service;
    address public owner;
    uint256 public monthlyPrice;

    struct Subscription {
        uint256 nextPaymentTime; // timestamp
        bool active;
    }

    mapping(address => Subscription) public subscribers;

    // User pays monthly fee (in ETH)
    function subscribe() public payable {
        require(msg.value == monthlyPrice, "Incorrect payment amount");
        require(!isActive(msg.sender), "User already subscribed");

        (bool success, ) = payable(owner).call{ value: msg.value }("");
        require(success, "Payment transfer failed");

        subscribers[msg.sender].nextPaymentTime = block.timestamp + 30 days;
        subscribers[msg.sender].active = true;
    }


    // Check if subscription is still valid
    function isActive(address subscriber) public returns (bool) {
        Subscription storage s = subscribers[subscriber];
        if (!s.active) {
        return false;
        }
        if (block.timestamp > s.nextPaymentTime) {
            s.active = false;
            return false;
        }
        return true;
    }

    event ServiceAccess(address indexed user, string url);

    function accessService() external {
        require(isActive(msg.sender), "You must be subscribed this month");

        string memory url = string.concat(
            "https://mock-app.example.com/access?token="
        );

        emit ServiceAccess(msg.sender, url);
    }
}