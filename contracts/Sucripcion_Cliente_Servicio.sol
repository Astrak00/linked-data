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
    function subscribe(address subscriber) public payable {
        require(msg.value == monthlyPrice, "Incorrect payment amount");

        (bool success, ) = payable(owner).call{ value: msg.value }("");

        subscribers[subscriber].nextPaymentTime = block.timestamp + 30 days;
        subscribers[subscriber].active = true;
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

    // Example of a protected service function
    function accessService() external returns (string memory) {
        require(isActive(msg.sender), "You must be subscribed this month");
        return "Service granted!";
    }


}

