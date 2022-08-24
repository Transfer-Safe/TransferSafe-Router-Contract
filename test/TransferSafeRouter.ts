import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert, expect, util } from "chai";
import { BigNumber, constants, utils } from "ethers";
import { ethers } from 'hardhat';
import { TransferSafeRouter } from "../typechain-types";
import { InvoiceStruct } from "../typechain-types/contracts/TransferSafeRouter";

const INITIAL_BALANCE = 10000;
const CHAIN_ID = 123;
const INVOICE_ID = '123';
const INITIAL_INVOICE: InvoiceStruct = {
  amount: BigNumber.from(1000),
  availableTokenTypes: [],
  balance: BigNumber.from(1000),
  confirmDate: BigNumber.from(1000),
  createdDate: BigNumber.from(1000),
  depositDate: BigNumber.from(1000),
  deposited: true,
  exist: false,
  fee: BigNumber.from(999),
  id: INVOICE_ID,
  instant: false,
  isNativeToken: true,
  paid: true,
  paidAmount: BigNumber.from(1000),
  receipientAddress: constants.AddressZero,
  receipientEmail: 'test@gmail.com',
  receipientName: '',
  ref: 'test',
  refundDate: BigNumber.from(1000),
  refunded: true,
  refundedAmount: BigNumber.from(1000),
  releaseLockDate: BigNumber.from(1000),
  releaseLockTimeout: BigNumber.from(1000),
  senderAddress: constants.AddressZero,
  tokenType: constants.AddressZero
}

describe("Token contract", function () {
  let router: TransferSafeRouter;
  let owner: SignerWithAddress;
  let invoiceCreator: SignerWithAddress;
  let invoiceSender: SignerWithAddress;

  beforeEach(async () => {
    const [user0, user1, user2] = await ethers.getSigners();
    owner = user0;
    invoiceCreator = user1;
    invoiceSender = user2;
    const TransferSafeRouter = await ethers.getContractFactory("TransferSafeRouter");
    router = await TransferSafeRouter.deploy(CHAIN_ID);
    await router.deployed();
  });

  it("Should have proper initial values", async function () {
    expect(await router.getFee()).to.equal(BigNumber.from(10));
    expect(await router.hasRole(await router.DEFAULT_ADMIN_ROLE(), owner.address));
    expect(await router.hasRole(await router.ADMIN(), owner.address));
  });

  it("Should allow to change fee for admins", async function () {
    await router.setFee(BigNumber.from(30));
    expect(await router.getFee()).to.be.equal(BigNumber.from(30));
  });

  it("Should not allow to change fee for non admins", async function () {
    await assert.isRejected(router.connect(invoiceCreator).setFee(BigNumber.from(10)), /.*Access denied.*/);
  });

  it('should create invoice with proper init values', async () => {
    await router.connect(invoiceCreator).createInvoice(INITIAL_INVOICE);
    const createdInvoice = await router.getInvoice(INVOICE_ID);

    expect(createdInvoice.id).to.equal(INVOICE_ID);
    expect(createdInvoice.amount).to.equal(INITIAL_INVOICE.amount);
    expect(createdInvoice.availableTokenTypes).to.deep.equal([]);
    expect(createdInvoice.confirmDate).to.equal(BigNumber.from(0));
    expect(createdInvoice.balance).to.equal(BigNumber.from(0));
    expect(createdInvoice.depositDate).to.equal(BigNumber.from(0));
    expect(createdInvoice.deposited).to.equal(false);
    expect(createdInvoice.exist).to.equal(true);
    expect(createdInvoice.fee).to.equal(await router.getFee());
    expect(createdInvoice.instant).to.equal(INITIAL_INVOICE.instant);
    expect(createdInvoice.isNativeToken).to.equal(INITIAL_INVOICE.isNativeToken);
    expect(createdInvoice.paid).to.equal(false);
    expect(createdInvoice.paidAmount).to.equal(constants.Zero);
    expect(createdInvoice.receipientAddress).to.equal(invoiceCreator.address);
    expect(createdInvoice.receipientEmail).to.equal(INITIAL_INVOICE.receipientEmail);
    expect(createdInvoice.ref).to.equal(INITIAL_INVOICE.ref);
    expect(createdInvoice.refundDate).to.equal(constants.Zero);
    expect(createdInvoice.refunded).to.equal(false);
    expect(createdInvoice.refundedAmount).to.equal(constants.Zero);
    expect(createdInvoice.releaseLockTimeout).to.equal(INITIAL_INVOICE.releaseLockTimeout);
    expect(createdInvoice.senderAddress).to.equal(constants.AddressZero);
    expect(createdInvoice.tokenType).to.equal(constants.AddressZero);
  });

  it('should now allow to create invoices with dublicated ids', async () => {
    await router.createInvoice(INITIAL_INVOICE);
    await assert.isRejected(router.createInvoice(INITIAL_INVOICE));
  })

  it('should deposit and confirm invoice with proper values', async () => {
    const transferAmount = 3000;
    const serviceFee = transferAmount * (await router.getFee()).toNumber() / 1000;

    const value = utils.parseEther(transferAmount.toString());
    await router.connect(invoiceCreator).createInvoice(INITIAL_INVOICE);
    await router.connect(invoiceSender).deposit(INITIAL_INVOICE.id, false, {
      value,
    });
    await router.connect(invoiceSender).confirmInvoice(INITIAL_INVOICE.id);
    const invoice = await router.getInvoice(INITIAL_INVOICE.id);
    expect(await router.getNativeFeeBalance()).to.equal(value.div(invoice.fee.mul(10)));
    const creatorBalance = (await invoiceCreator.getBalance()).mul(10).div(constants.WeiPerEther).toNumber() / 10;
    const senderBalance = (await invoiceSender.getBalance()).mul(10).div(constants.WeiPerEther).toNumber() / 10;
    expect(creatorBalance).to.closeTo(INITIAL_BALANCE + transferAmount - serviceFee, 1);
    expect(senderBalance).to.closeTo(INITIAL_BALANCE - transferAmount, 1);
  });
});