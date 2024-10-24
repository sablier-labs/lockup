// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

struct Users {
    // Default admin.
    address payable admin;
    // Impartial user.
    address payable alice;
    // Default stream broker.
    address payable broker;
    // Default campaign owner.
    address payable campaignOwner;
    // Malicious user.
    address payable eve;
    // Default NFT operator.
    address payable operator;
    // Default stream recipient.
    address payable recipient;
    // Other recipients.
    address payable recipient1;
    address payable recipient2;
    address payable recipient3;
    address payable recipient4;
    // Default stream sender.
    address payable sender;
}
