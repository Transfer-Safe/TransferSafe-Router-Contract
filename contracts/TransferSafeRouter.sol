// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Invoice {
    bytes32 id;
    uint256 amount;
    uint256 fee;
    uint256 created;
    uint256 balance;
    bool paid;
    bool isNativeToken;
    address tokenType;
    address[] availableTokenTypes;
    string ref;
    address receipientAddress;
    address senderAddress;
    string receipientName;
    string receipientEmail;
    bool exist;
}

contract TransferSafeRouter is Ownable {
    uint256 nativeFeeBalance = 0;
    mapping(address => uint256) tokensFeeBalances;
    mapping(bytes32 => Invoice) private invoices;
    mapping(address => bytes32[]) private userInvoices;

    event PaymentReceived(bytes32 invoiceId);
    event InvoiceWithdrawn(Invoice invoice, uint256 amount);
    event InvoiceCreated(bytes32 invoiceId);

    constructor() Ownable() {}

    function createInvoice(Invoice memory invoice) public {
        require(invoices[invoice.id].exist != true, "DUPLICATE_INVOICE");
        invoice.exist = true;
        invoices[invoice.id] = invoice;
        userInvoices[invoice.receipientAddress].push(invoice.id);
        emit InvoiceCreated(invoice.id);
    }

    function confirmInvoice(bytes32 invoiceId) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance > 0, "INVOICE_NOT_BALANCED");
        require(invoice.senderAddress == msg.sender, "FORBIDDEN");
        require(invoice.paid == false, "INVOICE_HAS_BEEN_PAID");
        invoices[invoiceId].paid = true;

        uint256 payoutAmount = SafeMath.sub(invoices[invoiceId].amount, invoices[invoiceId].fee);
        invoices[invoiceId].balance = 0;
        if (invoice.isNativeToken) {
            nativeFeeBalance += invoice.fee;
            payable(msg.sender).transfer(payoutAmount);
        } else {
            tokensFeeBalances[invoice.tokenType] += invoice.fee;
            IERC20 token = IERC20(invoice.tokenType);
            token.transfer(invoice.receipientAddress, payoutAmount);
        }

        emit InvoiceWithdrawn(invoices[invoiceId], payoutAmount);
    }

    function deposit(bytes32 invoiceId) payable public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.receipientAddress == msg.sender, "FORBIDDEN");
        require(invoice.balance == 0, "INVOICE_NOT_BALANCED");
        require(invoice.amount == msg.value, "INVOICE_NOT_BALANCED");

        invoices[invoiceId].balance = msg.value;

        emit PaymentReceived(invoiceId);
    }

    function depositErc20(bytes32 invoiceId, address tokenType) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.receipientAddress == msg.sender, "FORBIDDEN");
        require(invoice.balance == 0, "INVOICE_NOT_BALANCED");

        IERC20 token = IERC20(invoice.tokenType);
        token.transferFrom(msg.sender, address(this), invoice.amount);
        invoices[invoiceId].balance = invoice.amount;
        invoices[invoiceId].tokenType = tokenType;

        emit PaymentReceived(invoiceId);
    }

    function getNativeFeeBalance() public view returns (uint256) {
        return nativeFeeBalance;
    }
    
    function getTokenFeeBalance(address tokenType) public view returns (uint256) {
        return tokensFeeBalances[tokenType];
    }

    function getInvoice(bytes32 invoiceId) public view returns (Invoice memory) {
        return invoices[invoiceId];
    }

    function getUserInvoices(address user) public view returns (Invoice[] memory) {
        bytes32[] memory userInvoiceIds = userInvoices[user];
        Invoice[] memory userInvoicesArray = new Invoice[](userInvoiceIds.length);
        for (uint256 i = 0; i < userInvoiceIds.length; i++) {
            userInvoicesArray[i] = invoices[userInvoiceIds[i]];
        }
        return userInvoicesArray;
    }
}
