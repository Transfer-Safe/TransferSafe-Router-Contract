// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./RouterConfig.sol";

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

contract TransferSafeRouter is Ownable, RouterConfigContract {
    uint256 nativeFeeBalance = 0;
    uint256 fee = 10;

    mapping(address => uint256) tokensFeeBalances;
    mapping(string => Invoice) private invoices;
    mapping(address => string[]) private userInvoices;

    event PaymentReceived(string invoiceId);
    event InvoiceWithdrawn(Invoice invoice, uint256 amount);
    event InvoiceRefunded(Invoice invoice, uint256 amount);
    event InvoiceCreated(string invoiceId);

    constructor(uint256 _chainId) Ownable() RouterConfigContract(_chainId) {
        chainId = _chainId;
    }

    function createInvoice(Invoice memory invoice) public {
        require(invoices[invoice.id].exist != true, "DUPLICATE_INVOICE");
        invoice.exist = true;
        invoice.receipientAddress = msg.sender;
        invoice.releaseLockDate = uint32(block.timestamp) + invoice.releaseLockTimeout;
        invoice.fee = SafeMath.div(SafeMath.mul(invoice.amount, fee), 1000);
        invoice.paidAmount = 0;
        invoice.refundedAmount = 0;
        invoice.depositDate = 0;
        invoice.confirmDate = 0;
        invoice.refundDate = 0;
        invoice.refunded = false;
        invoice.deposited = false;
        invoice.paid = false;
        invoice.createdDate = uint32(block.timestamp);
        invoices[invoice.id] = invoice;
        userInvoices[invoice.receipientAddress].push(invoice.id);
        emit InvoiceCreated(invoice.id);
    }

    function confirmInvoice(string memory invoiceId) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance > 0, "INVOICE_NOT_BALANCED");
        require(invoice.senderAddress == msg.sender, "FORBIDDEN");
        require(invoice.paid == false, "INVOICE_HAS_BEEN_PAID");

        uint256 payoutAmount = SafeMath.sub(invoices[invoiceId].balance, invoices[invoiceId].fee);
        invoices[invoiceId].balance = 0;
        if (invoice.isNativeToken) {
            nativeFeeBalance += invoice.fee;
            invoices[invoiceId].paidAmount = payoutAmount;
            payable(msg.sender).transfer(payoutAmount);
        } else {
            tokensFeeBalances[invoice.tokenType] += invoice.fee;
            IERC20 token = IERC20(invoice.tokenType);
            token.transfer(invoice.receipientAddress, payoutAmount);
        }

        invoices[invoiceId].confirmDate = uint32(block.timestamp);
        invoices[invoiceId].paid = true;

        emit InvoiceWithdrawn(invoices[invoiceId], payoutAmount);
    }

    function refundInvoice(string memory invoiceId) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance > 0, "INVOICE_NOT_BALANCED");
        require(invoice.receipientAddress == msg.sender, "FORBIDDEN");
        require(invoice.paid == false, "INVOICE_HAS_BEEN_PAID");

        uint256 refundAmount = invoice.balance;
        invoices[invoiceId].balance = 0;
        invoices[invoiceId].refunded = true;

        if (invoice.isNativeToken) {
            payable(msg.sender).transfer(refundAmount);
        } else {
            IERC20 token = IERC20(invoice.tokenType);
            token.transfer(invoice.receipientAddress, refundAmount);
        }

        invoices[invoiceId].refundDate = uint32(block.timestamp);

        emit InvoiceRefunded(invoices[invoiceId], refundAmount);
    }

    function deposit(string memory invoiceId, bool instant) payable public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance == 0, "INVOICE_NOT_BALANCED");

        invoices[invoiceId].balance = msg.value;
        invoices[invoiceId].senderAddress = msg.sender;

        invoices[invoiceId].depositDate = uint32(block.timestamp);
        invoices[invoiceId].deposited = true;

        emit PaymentReceived(invoiceId);

        if (instant == true) {
            confirmInvoice(invoiceId);
        }
    }

    function depositErc20(string memory invoiceId, address tokenType, bool instant) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance == 0, "INVOICE_NOT_BALANCED");

        IERC20 token = IERC20(invoice.tokenType);
        token.transferFrom(msg.sender, address(this), invoice.amount);
        invoices[invoiceId].balance = invoice.amount;
        invoices[invoiceId].tokenType = tokenType;

        invoices[invoiceId].depositDate = uint32(block.timestamp);
        invoices[invoiceId].deposited = true;

        emit PaymentReceived(invoiceId);
    }

    function getNativeFeeBalance() public view returns (uint256) {
        return nativeFeeBalance;
    }
    
    function getTokenFeeBalance(address tokenType) public view returns (uint256) {
        return tokensFeeBalances[tokenType];
    }

    function getInvoice(string memory invoiceId) public view returns (Invoice memory) {
        Invoice memory invoice = invoices[invoiceId];
        return invoice;
    }

    function getUserInvoices(address user) public view returns (Invoice[] memory) {
        string[] memory userInvoiceIds = userInvoices[user];
        Invoice[] memory userInvoicesArray = new Invoice[](userInvoiceIds.length);
        for (uint256 i = 0; i < userInvoiceIds.length; i++) {
            userInvoicesArray[i] = invoices[userInvoiceIds[i]];
        }
        return userInvoicesArray;
    }

    function widthdrawFee(address destination, uint256 amount) public onlyOwner {
        nativeFeeBalance = SafeMath.sub(nativeFeeBalance, amount);
        payable(destination).transfer(amount);
    }

    function widthdrawErc20Fee(address destination, address tokenType, uint256 amount) public onlyOwner {
        tokensFeeBalances[tokenType] = SafeMath.sub(tokensFeeBalances[tokenType], amount);
        IERC20 token = IERC20(tokenType);
        token.transfer(destination, amount);
    }

    function setFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    function getFee() view public returns (uint256) {
        return fee;
    }

    function amountInCurrency(string memory invoiceId, address token) view public returns (uint256) {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.exist, "INVOICE_NOT_EXIST!");
        address chainlinkAddress = config.chainlinkTokensAddresses[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(chainlinkAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return convertAmount(invoice.amount, price, decimals);
    }
    
    function amountInNativeCurrency(string memory invoiceId) view public returns (uint256) {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.exist, "INVOICE_NOT_EXIST!");
        address chainlinkAddress = config.chainlinkNativeTokenAddress;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(chainlinkAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return convertAmount(invoice.amount, price, decimals);
    }

    function convertAmount(uint256 amount, int256 price, uint8 decimals) pure private returns (uint256) {
        return SafeMath.div(
            SafeMath.mul(
                amount,
                uint256(price)
            ),
            10 ** decimals
        );
    }
}
