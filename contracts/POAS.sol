// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract POAS is ERC20, AccessControl, ReentrancyGuard {
    bytes32 public constant REDEEMABLE_ROLE = keccak256("REDEEMABLE_ROLE");
    
    event Deposited(address indexed user, uint256 amount);
    event Redeemed(address indexed user, address indexed recipient, uint256 amount);
    event BatchMinted(address[] recipients, uint256[] amounts);

    constructor() ERC20("Proof of OAS", "pOAS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REDEEMABLE_ROLE, msg.sender);
    }

    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Amount must be greater than 0");
        _mint(msg.sender, msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable nonReentrant {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Amount must be greater than 0");
            totalAmount += amounts[i];
        }

        require(msg.value == totalAmount, "Invalid total amount");

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
        }

        emit BatchMinted(recipients, amounts);
    }

    function redeem(uint256 amount, address payable recipient) external nonReentrant {
        require(hasRole(REDEEMABLE_ROLE, msg.sender), "Caller is not redeemable");
        require(amount > 0, "Amount must be greater than 0");
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit Redeemed(msg.sender, recipient, amount);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0) && to != address(0)) {
            require(
                hasRole(REDEEMABLE_ROLE, from) && hasRole(REDEEMABLE_ROLE, to),
                "Transfer restricted to redeemable addresses"
            );
        }
        super._update(from, to, amount);
    }

    receive() external payable {
        deposit();
    }
} 