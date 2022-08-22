// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract TransferSafeAccessControl is AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MANAGER = keccak256("MANAGER");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Access denied");
        _;
    }

    modifier onlyManager() {
        require(
            isAdmin(msg.sender) || isManager(msg.sender), "Access denied");
        _;
    }

    function isAdmin(address account) private view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account) || hasRole(ADMIN, account);
    }

    function isManager(address account) private view returns (bool) {
        return hasRole(MANAGER, account);
    }
}