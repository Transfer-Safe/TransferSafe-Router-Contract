// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./TransferSafeAccessControl.sol";
import "./RouterConfig.sol";
import "./Invoice.sol";

contract TransferSafeRouter is TransferSafeAccessControl, RouterConfigContract {
    uint256 nativeFeeBalance = 0;
    uint256 fee = 10;
    uint256 slippageLimit = 5;

    mapping(address => uint256) tokensFeeBalances;
    mapping(string => Invoice) private invoices;
    mapping(address => string[]) private userInvoices;

    event InvoiceDeposited(string invoiceId);
    event InvoiceConfirmed(Invoice invoice, uint256 amount, address recepient);
    event InvoiceRefunded(Invoice invoice, uint256 amount);
    event InvoiceCreated(string invoiceId);
    event SlippageCalculated(uint256 slippage);

    constructor(uint256 _chainId) TransferSafeAccessControl() RouterConfigContract(_chainId) {
        chainId = _chainId;
    }

    function createInvoice(Invoice memory invoice) public {
        require(invoices[invoice.id].exist != true, "DUPLICATE_INVOICE");
        invoice.exist = true;
        invoice.receipientAddress = msg.sender;
        invoice.releaseLockDate = uint32(block.timestamp) + invoice.releaseLockTimeout;
        invoice.fee = fee;
        invoice.paidAmount = 0;
        invoice.refundedAmount = 0;
        invoice.depositDate = 0;
        invoice.confirmDate = 0;
        invoice.refundDate = 0;
        invoice.refunded = false;
        invoice.balance = 0;
        invoice.deposited = false;
        invoice.paid = false;
        invoice.createdDate = uint32(block.timestamp);
        invoices[invoice.id] = invoice;
        userInvoices[invoice.receipientAddress].push(invoice.id);
        emit InvoiceCreated(invoice.id);
    }

    function listInvoices(address userAddress, uint256 take, uint256 skip) public view returns (Invoice[] memory) {
        string[] memory userInvoiceIds = userInvoices[userAddress];
        Invoice[] memory userInvoicesArray = new Invoice[](userInvoiceIds.length);
        if (userInvoiceIds.length == 0) {
            return userInvoicesArray;
        }

        for (uint256 i = 0; i < userInvoiceIds.length; i++) {
            // TODO: respect take and skip pagination
            userInvoicesArray[i] = invoices[userInvoiceIds[i]];
        }
        return userInvoicesArray;
    }

    function confirmInvoice(string memory invoiceId) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance > 0, "INVOICE_NOT_BALANCED");
        require(invoice.senderAddress == msg.sender, "FORBIDDEN");
        require(invoice.paid == false, "INVOICE_HAS_BEEN_PAID");

        uint256 payoutAmount = 0;
        if (invoice.balance > 0) {
             uint256 invoiceFee = SafeMath.mul(
                SafeMath.div(invoices[invoiceId].balance, 1000),
                invoice.fee
            );
            payoutAmount = SafeMath.sub(invoices[invoiceId].balance, invoiceFee);
            invoices[invoiceId].balance = 0;
            nativeFeeBalance += invoiceFee;
            invoices[invoiceId].paidAmount = payoutAmount;
            bool isSent = payable(invoice.receipientAddress).send(payoutAmount);
            require(isSent, "FAILED_TO_SEND");
        } else {
            revert("NOT_IMPLEMENTED");
        }

        invoices[invoiceId].confirmDate = uint32(block.timestamp);
        invoices[invoiceId].paid = true;

        emit InvoiceConfirmed(invoices[invoiceId], payoutAmount, msg.sender);
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
            // TODO: check for releaseLockDate
            bool sent = payable(invoice.receipientAddress).send(refundAmount);
            require(sent, "Failed to send funds");
        } else {
            revert("Not implemented");
            IERC20 token = IERC20(invoice.tokenType);
            token.transfer(invoice.receipientAddress, refundAmount);
        }

        invoices[invoiceId].refundDate = uint32(block.timestamp);

        emit InvoiceRefunded(invoices[invoiceId], refundAmount);
    }

    function deposit(string memory invoiceId, bool instant) payable public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance == 0, "INVOICE_NOT_BALANCED");

        if (config.chainlinkNativeTokenAddress != address(0)) {
            uint256 amountToBePaid = amountInNativeCurrency(invoiceId);
            uint256 transactionAmount = msg.value;
            assertSlippage(transactionAmount, amountToBePaid);
        }

        invoices[invoiceId].balance = msg.value;
        invoices[invoiceId].senderAddress = msg.sender;

        invoices[invoiceId].depositDate = uint32(block.timestamp);
        invoices[invoiceId].deposited = true;
        invoices[invoiceId].isNativeToken = true;

        emit InvoiceDeposited(invoiceId);

        if (instant == true || invoice.instant == true) {
            confirmInvoice(invoiceId);
        }
    }

    function assertSlippage(uint256 originalValue, uint256 value) private {
        uint256 diff;
        if (originalValue > value) {
            diff = SafeMath.sub(originalValue, value);
        } else {
            diff = SafeMath.sub(value, originalValue);
        }
        uint256 slippage = SafeMath.div(SafeMath.mul(diff, 1000), originalValue);
        emit SlippageCalculated(slippage);

        if (slippage > slippageLimit) {
            revert("SLIPPAGE_LIMIT_EXCEEDED");
        }
    }

    function depositErc20(string memory invoiceId, address tokenType, bool instant) public {
        revert("Not implemented");
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

    function widthdrawFee(address destination, uint256 amount) public onlyAdmin {
        nativeFeeBalance = SafeMath.sub(nativeFeeBalance, amount);
        payable(destination).transfer(amount);
    }

    function widthdrawErc20Fee(address destination, address tokenType, uint256 amount) public onlyAdmin {
        tokensFeeBalances[tokenType] = SafeMath.sub(tokensFeeBalances[tokenType], amount);
        IERC20 token = IERC20(tokenType);
        token.transfer(destination, amount);
    }

    function setFee(uint256 newFee) public onlyAdmin {
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
        if (chainlinkAddress == address(0)) {
            return 0;
        }
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
