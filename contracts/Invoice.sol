// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

struct Invoice {
    string id;
    uint256 amount;
    uint256 fee;

    uint256 balance;
    uint256 paidAmount;
    uint256 refundedAmount;

    bool isNativeToken;
    address tokenType;
    address[] availableTokenTypes;
    string ref;
    address receipientAddress;
    address senderAddress;
    string receipientName;
    string receipientEmail;

    bool paid;
    bool deposited;
    bool exist;
    bool instant;
    bool refunded;

    uint32 releaseLockTimeout;

    uint32 releaseLockDate;
    uint32 depositDate;
    uint32 confirmDate;
    uint32 refundDate;
    uint32 createdDate;
}